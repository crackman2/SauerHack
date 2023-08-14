unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, gl, glu,
  { my stuff}
  globalvars, CPlayer, CAimbot, cfunctioncaller, CESP, DrawText,
  CTeleportAllEnemiesToYou, CNoclip,
  CMenuMain, CFlagStealer;

var
  { ----------------------------- Player Object ---------------------------- }
  { -> read position & team                                                  }
  { -> set camera angles                                                     }
  Player: TPlayer;


  { ----------------------------- Aimbot Object ---------------------------- }
  { -> Target selection                                                      }
  { -> Aiming & auto trigger via                                             }
  {    color check                                                           }
  Aimer: TAimbot;
  CurrentBestTarget: integer;
  {EnableAimbot:PByte=nil;
  LockAim: PByte = nil;
  ReleasedRBM: PByte = nil;
  EnableLockAim:PByte=nil; }


  { -------------------------- Enemy Object Array -------------------------- }
  { -> read position & team                                                  }
  Enemy: array[1..32] of TPlayer;
  PlayerCount: integer;


  { ------------------------------ ESP Object ------------------------------ }
  { -> draw enemies on screen                                                }
  esp: TESP;
  //EnableESP:PByte=nil;


  { ------------------------------ TATY Object ----------------------------- }
  { -> teleport everyone to you                                              }
  { -> may cause death                                                       }
  taty: TTeleAETY;
  //EnableTATY:PByte=nil;


  { ----------------------------- Noclip Object ---------------------------- }
  { -> fly around                                                            }
  noclip: TNoclip;
  {EnableNoclip: PByte;
  NoclipButtonPressed: PByte;
  EnableNoclipping:PByte=nil;}


  { ------------------------------ Menu Object ----------------------------- }
  { -> draws menu for controlling                                            }
  {    settings                                                              }
  Menu: TMenu;
  {MenuPosX:Pointer=nil;
  MenuPosY:Pointer=nil;}
  EnableMenu: PByte = nil;


  { --------------------------- FlagStealer Object ------------------------- }
  { -> Save location of both flags                                           }
  { -> teleport back and forth                                               }
  FlagStealer: TFlagStealer;
//EnableFlagSteal:PByte=nil;


{ ---------------------------- Debug Screen F1 --------------------------- }
{ -> Shows information                                                     }
  {EnableDebug: PByte;
  DebugButtonPressed: PByte;}


{ ---------------------------- Counter Pointer --------------------------- }
{ -> counts up! :D located at cave + $300                                  }
{pCounter:Pointer=nil;}


procedure MainFunc();
procedure GetPlayerCount();
procedure PollDebug();
procedure ShowDebugMenu();
procedure PollNoclip();
procedure PollAimbot();
procedure glEnter2DDrawingMode; stdcall;
procedure glLeave2DDrawingMode; stdcall;
procedure DrawDebugLine();

implementation

procedure MainFunc();
var
  i: cardinal; //for loop counter
  oldGLContext: HGLRC;
begin
  { ------------------------ Prepare OpenGL Drawing ------------------------ }
  { -> oldGLContext is the current context used by the game. Apparently it   }
  {    is impossible to use in it's current state for our purposes, so we    }
  {    just create a new one                                                 }
  { -> caveHDC is the device context, grabbed frome the wglSwapBuffers call  }
  { -> caveNewRC is a new device context that was created when the hook code }
  {    was run the first time                                                }
  oldGLContext := wglGetCurrentContext;
  wglMakeCurrent(caveHDC, caveNewRC);
  glEnter2DDrawingMode;

  { ------------------------------- pCounter ------------------------------- }
  { -> is just used to see if the hack is actually being executed (can be    }
  {    omitted                                                               }
  //pCounter:=Pointer(cave + $300);
  //inc(PCardinal(pCounter)^);
  Inc(global_pCounter);


  { ----------------------------- Init Pointers ---------------------------- }
  {LockAim:= PByte         (cave + $3C0);
  ReleasedRBM:=PByte      (cave + $3C8);
  MenuPosX:=Pointer       (cave + $500);
  MenuPosY:=Pointer       (cave + $504);
  EnableESP:=PByte        (cave + $600);
  EnableAimbot:=PByte     (cave + $604);
  EnableLockAim:=PByte    (cave + $608);
  EnableNoclipping:=PByte (cave + $60C);
  EnableTATY:=PByte       (cave + $610);
  EnableFlagSteal:=PByte  (cave + $614);}


  { ---------------------- Initial Values for Pointers --------------------- }
  if global_MenuInitialSetup = 0 then
  begin
    global_EnableAimbot := 1;
    global_EnableESP := 1;
    global_EnableNoclipping := 1;
    global_EnableLockAim := 1;
    EnableMenu := PByte(GetModuleHandle('sauerbraten.exe') + $30D0E8);
    //uptodate 09/08/2023
    global_MenuInitialSetup := 1;
    global_MenuPosX := 50;
    global_MenuPosY := 50;

    SetLength(global_MenuPointers, 6);

    global_MenuPointers[0] := @global_EnableESP;
    global_MenuPointers[1] := @global_EnableAimbot;
    global_MenuPointers[2] := @global_EnableLockAim;
    global_MenuPointers[3] := @global_EnableNoclipping;
    global_MenuPointers[4] := @global_EnableTATY;
    global_MenuPointers[5] := @global_EnableFlagSteal;
  end;


  { ------------------------- Object Initialization ------------------------ }
  { -> calls constructor for the localplayer object                          }
  { -> calls constructor for the enemy array                                 }
  { -> sets the index and stuff..                                            }
  { -> calls constructor for the esp object                                  }
  { -> calls constructor for the aimbot object                               }
  GetPlayerCount();
  Player := TPlayer.Create(0);


  //taty := TTeleAETY.Create(@Player, @Enemy, PlayerCount);   COMMENTED FOR DEBUG
  noclip := TNoclip.Create;
  Menu := TMenu.Create(global_MenuPosX, global_MenuPosY, 426, 185, 'SauerHack Reloaded', 3,
    global_MenuPointers);
  //FlagStealer:=TFlagStealer.Create(); COMMENTED FOR DEBUG
  i := 1;
  while (i <= PlayerCount) do
  begin
    Enemy[i] := TPlayer.Create(i);
    Inc(i);
  end;

  esp := TESP.Create(Player, Enemy, PlayerCount);
  Aimer := TAimbot.Create(Player, Enemy);



  { ----------------------------- Aimbot Cylce ----------------------------- }
  { -> Checks hotkey                                                         }
  { -> selects best target and keeps aiming until the target is dead         }
  { -> stops aiming when the enemy is dead                                   }
  { -> reclick hotkey to aim at next taget                                   }
  { -> this should really be its own function...                             }
  PollAimbot();



  { --------------------------------- TATY --------------------------------- }
  if (GetAsyncKeyState(VK_X) <> 0) and (global_EnableTATY = 1) then
  begin
    //taty.TeleportAllEnemiesInfrontOfYou();  COMMENTED FOR DEBUG
  end;


  { ----------------------------- FlagStealer ------------------------------ }
  { -> teleport between flags                                                }
  { -> infinite points                                                       }
  if (GetAsyncKeyState(VK_P) <> 0) and (global_EnableFlagSteal = 1) then
  begin
    //FlagStealer.SpamTeleport();             COMMENTED FOR DEBUG
  end;


  { -------------------------------- Noclip -------------------------------- }
  { -> lets you fly around the map                                           }
  { -> toggles with 'V'                                                      }
  if noclip <> nil then
    PollNoclip();


  { ---------------------------- Debug Screen F1 --------------------------- }
  { -> Shows inforamtion                                                     }
  { -> toggles with 'F1'                                                     }
  PollDebug();


  { ----------------------------- Drawing ESP ------------------------------ }
  { -> draws red boxes around enemy player                                   }
  if global_EnableESP = 1 then
    esp.DrawESP();



  { ----------------------------- Drawing Menu ----------------------------- }
  { -> draws menu                                                            }
  { -> init menu settings                                                    }
  if EnableMenu^ = 1 then
  begin
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_LINE_SMOOTH);
    glLineWidth(1);
    Menu.PollControls;
    Menu.DrawMenu;
  end;



  { --------------------------- Object Destroyer --------------------------- }
  { -> prevent leaks.                                                        }
  Aimer.Destroy;
  Player.Destroy;
  esp.Destroy;
  //taty.Destroy;                             COMMENTED FOR DEBUG
  noclip.Destroy;
  Menu.Destroy;
  //FlagStealer.Destroy;                      COMMENTED FOR DEBUG
  i := 1;
  while (i <= PlayerCount) do
  begin
    Enemy[i].Destroy;
    Inc(i);
  end;


  { ------------------------------ Debug Line ------------------------------ }
  { -> confirms hack is active                                               }
  DrawDebugLine;

  glLeave2DDrawingMode;
  wglMakeCurrent(caveHDC, oldGLContext);
end;



procedure GetPlayerCount();
var
  tmp: PInteger;
begin
  tmp := PInteger(GetModuleHandle('sauerbraten.exe') + $3C9AD8); //uptodate 09/08/2023
  PlayerCount := tmp^ - 1; //not counting local player
end;


procedure PollDebug();
begin

  if (GetAsyncKeyState(VK_F1) <> 0) and (global_DebugButtonPressed = 0) and
    (global_EnableDebug = 0) then
  begin
    global_EnableDebug := 1;
    global_DebugButtonPressed := 1;
  end;

  if (GetAsyncKeyState(VK_F1) <> 0) and (global_DebugButtonPressed = 0) and
    (global_EnableDebug = 1) then
  begin
    global_EnableDebug := 0;
    global_DebugButtonPressed := 1;
  end;

  if (GetAsyncKeyState(VK_F1) = 0) then
    global_DebugButtonPressed := 0;

  if global_EnableDebug = 1 then
  begin
    ShowDebugMenu();
  end;
end;


procedure ShowDebugMenu;
var
  Help: array[0..11] of ansistring;
  Globals: array[0..9] of ansistring;
  i: cardinal;
  Y: cardinal = 150;
  X: cardinal = 100;
begin
  glColor3f(0.8, 0.8, 0.8);
  glxDrawString(X, Y + 000, '::Debug Screen::', 2, True);
  glxDrawString(X, Y + 015, 'posx: ' + IntToStr(round(Player.pos.x)), 2, True);
  glxDrawString(X, Y + 030, 'posy: ' + IntToStr(round(Player.pos.y)), 2, True);
  glxDrawString(X, Y + 045, 'posz: ' + IntToStr(round(Player.pos.z)), 2, True);


  Help[00] := '- right click to aim at target';
  Help[01] := '- ''V'' to noclip. controls are WASD Space LShift LCtrl';
  Help[02] := '- ''X'' to teleport everyone to you';
  Help[03] := '- ''P'' to auto capture flags (works only if the flags are at their spawns)';
  Help[04] := '- the triggerbot checks colors. for it to work you must';
  Help[05] := '  - replace the orgo textureS in packages/models/ogro2';
  Help[06] := '  - replace green.jpg and red.jpg with a filled color of R0 G255 B0';
  Help[07] := '    so they are entirely green';
  Help[08] := '  - in game settings: enable fullbright playermodels and set to max';
  Help[09] :=
    '                      force matching playermodels and play as orgo (or any other model you picked)';
  Help[10] := '                      enable hide dead players';
  Help[11] :=
    '                      in gfx disable: shaders, shadowmaps, dynamic lights, models (lighting, reflection, glow)';


  for i := 0 to Length(Help) - 1 do
  begin
    glxDrawString(X, Y + 75 + i * 15, Help[i], 2, True);
  end;

  {
  LockAim:= PByte         (cave + $3C0);
  ReleasedRBM:=PByte      (cave + $3C8);
  MenuPosX:=Pointer       (cave + $500);
  MenuPosY:=Pointer       (cave + $504);
  EnableESP:=PByte        (cave + $600);
  EnableAimbot:=PByte     (cave + $604);
  EnableLockAim:=PByte    (cave + $608);
  EnableNoclipping:=PByte (cave + $60C);
  EnableTATY:=PByte       (cave + $610);
  EnableFlagSteal:=PByte  (cave + $614);
  }


  Globals[00] := 'LockAim: ' + IntToStr(global_LockAim);
  Globals[01] := 'ReleasedRBM: ' + IntToStr(global_ReleasedRBM);
  Globals[02] := 'MenuPosX: ' + FloatToStr(global_MenuPosX);
  Globals[03] := 'MenuPosY: ' + FloatToStr(global_MenuPosY);
  Globals[04] := 'EnableESP: ' + IntToStr(global_EnableESP);
  Globals[05] := 'EnableAimbot: ' + IntToStr(global_EnableAimbot);
  Globals[06] := 'EnableLockAim: ' + IntToStr(global_EnableLockAim);
  Globals[07] := 'EnableNoclipping: ' + IntToStr(global_EnableNoclipping);
  Globals[08] := 'EnableTATY: ' + IntToStr(global_EnableTATY);
  Globals[09] := 'EnableFlagSteal: ' + IntToStr(global_EnableFlagSteal);

  for i := 0 to Length(Globals) - 1 do
  begin
    glxDrawString(X, Y + 75 + (Length(Help) * 15) + i * 15, Globals[i], 2, True);
  end;

end;


procedure PollNoclip();
begin

  if (GetAsyncKeyState(VK_V) <> 0) and (global_NoclipButtonPressed = 0) and
    (global_EnableNoclip = 0) and (global_EnableNoclipping = 1) then
  begin
    global_EnableNoclip := 1;
    global_NoclipButtonPressed := 1;
  end;

  if (GetAsyncKeyState(VK_V) <> 0) and (global_NoclipButtonPressed = 0) and
    (global_EnableNoclip = 1) then
  begin
    global_EnableNoclip := 0;
    global_NoclipButtonPressed := 1;
  end;

  if (GetAsyncKeyState(VK_V) = 0) then
    global_NoclipButtonPressed := 0;

  if global_EnableNoclip = 1 then
  begin
    noclip.PollControls;
    noclip.NOPFalling(True);
    noclip.ZeroVelocities();
  end
  else
  begin
    noclip.NOPFalling(False);
  end;
end;

procedure PollAimbot();
begin
  if Assigned(Aimer) then
  begin
    if (global_EnableAimbot = 1) and (global_EnableLockAim = 1) then
    begin
      if not (GetAsyncKeyState($1) <> 0) then
        Aimer.ShootByte^ := $0;
      if (GetAsyncKeyState($2) <> 0) then
      begin
        if global_ReleasedRBM = 1 then
        begin
          global_LockAim := 1;
          CurrentBestTarget := Aimer.GetBestTarget(PlayerCount);
          global_ReleasedRBM := 0;
        end;
      end
      else
      begin
        global_ReleasedRBM := 1;
      end;

      if (global_LockAim = 1) and (global_ReleasedRBM = 0) then
      begin
        if Enemy[CurrentBestTarget] <> nil then
        begin
          if Enemy[CurrentBestTarget].hp <= 0 then
          begin
            global_LockAim := 0;
          end
          else
          begin
            if GetAsyncKeyState(VK_O) <> 0 then
            begin
              //Debug Output. Show current targets pointer
              // MessageBox(0, PChar('Current Target: 0x' +
              //   IntToHex(DWORD(Enemy[CurrentBestTarget].PlayerBase), 8)), 'e', 0);
            end;
            Aimer.Aim(CurrentBestTarget);
            Aimer.AutoTrigger();
          end;
        end
        else
        begin
          global_LockAim := 0;
        end;
      end
      else
      begin
        global_LockAim := 0;
      end;
    end;

    if (global_EnableAimbot = 1) and (global_EnableLockAim = 0) then
    begin
      if not (GetAsyncKeyState($1) <> 0) then
        Aimer.ShootByte^ := $0;
      if (GetAsyncKeyState($2) <> 0) then
      begin
        Aimer.Aim(Aimer.GetBestTarget(PlayerCount));
        Aimer.AutoTrigger();
      end;
    end;
  end;
end;

{ -------------------------- glEnter2DDrawingMode -------------------------- }
{ -> sets out context up to draw properly                                    }
{ -> glGetIntegerv and glOrtho allow us to use usual x,y pixel coordinates   }
{    meaning that 0,0 is the top left pixel and the bottom right one is      }
{    equal to the current resolution                                         }
procedure glEnter2DDrawingMode; stdcall;
var
  viewport: array[0..3] of GLint;
begin
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();

  glGetIntegerv(GL_VIEWPORT, viewport);
  glOrtho(0, viewport[2], viewport[3], 0, -1.0, 1.0);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
end;

{ -------------------------- glLeave2DDrawingMode -------------------------- }
{ -> can possibly be omitted, but I keep it in case some update breaks       }
{    everything                                                              }

procedure glLeave2DDrawingMode; stdcall;
begin
  glFlush();
  glEnable(GL_TEXTURE_2D);
end;

procedure DrawDebugLine();
var
  c: single;
  i: cardinal;
  FPS:PInteger;

begin

  FPS := Pointer(GetModuleHandle('sauerbraten.exe') + $39A644);

  c := global_pCounter / PInteger(FPS)^;

  for i := 0 to 30 do
  begin
    glColor3f(c / i, c * i, i / 30);
    glLineWidth(i / 10);
    glBegin(GL_LINES);
    glVertex2f(cos(c * i) * (i), i + sin(c * i) * (i));
    glVertex2f(i + cos(c * (i + 1)) * (i), sin(c * (i + 1)) * (i));
    glEnd();
  end;
end;


end.
