unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, gl, glu,
  { my stuff}
  cavepointer, CPlayer, Aimbot, FunctionCaller, CESP, DrawText, CTeleportAllEnemiesToYou, CNoclip,
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
  EnableAimbot:PByte=nil;
  LockAim: PByte = nil;
  ReleasedRBM: PByte = nil;
  CurrentBestTarget: integer;
  EnableLockAim:PByte=nil;


  { -------------------------- Enemy Object Array -------------------------- }
  { -> read position & team                                                  }
  Enemy: array[1..32] of TPlayer;
  PlayerCount: integer;


  { ------------------------------ ESP Object ------------------------------ }
  { -> draw enemies on screen                                                }
  esp: TESP;
  EnableESP:PByte=nil;


  { ------------------------------ TATY Object ----------------------------- }
  { -> teleport everyone to you                                              }
  { -> may cause death                                                       }
  taty: TTeleAETY;
  EnableTATY:PByte=nil;


  { ----------------------------- Noclip Object ---------------------------- }
  { -> fly around                                                            }
  noclip: TNoclip;
  EnableNoclip: PByte;
  NoclipButtonPressed: PByte;
  EnableNoclipping:PByte=nil;


  { ------------------------------ Menu Object ----------------------------- }
  { -> draws menu for controlling                                            }
  {    settings                                                              }
  Menu:TMenu;
  MenuPosX:Pointer=nil;
  MenuPosY:Pointer=nil;
  EnableMenu:PByte=nil;


  { --------------------------- FlagStealer Object ------------------------- }
  { -> Save location of both flags                                           }
  { -> teleport back and forth                                               }
  FlagStealer:TFlagStealer;
  EnableFlagSteal:PByte=nil;


  { ---------------------------- Debug Screen F1 --------------------------- }
  { -> Shows information                                                     }
  EnableDebug: PByte;
  DebugButtonPressed: PByte;


  { ---------------------------- Counter Pointer --------------------------- }
  { -> counts up! :D located at cave + $300                                  }
  pCounter:Pointer=nil;


procedure MainFunc();
procedure GetPlayerCount();
procedure PollDebug();
procedure ShowDebugMenu();
procedure PollNoclip();
procedure PollAimbot();
procedure glEnter2DDrawingMode; stdcall;
procedure glLeave2DDrawingMode; stdcall;

implementation

procedure MainFunc();
var
  i: cardinal; //for loop counter
  oldGLContext:HGLRC;
begin
  { ------------------------ Prepare OpenGL Drawing ------------------------ }
  { -> oldGLContext is the current context used by the game. Apparently it   }
  {    is impossible to use in it's current state for our purposes, so we    }
  {    just create a new one                                                 }
  { -> caveHDC is the device context, grabbed frome the wglSwapBuffers call  }
  { -> caveNewRC is a new device context that was created when the hook code }
  {    was run the first time                                                }
  oldGLContext:=wglGetCurrentContext;
  wglMakeCurrent(caveHDC,caveNewRC);
  glEnter2DDrawingMode;

  { ------------------------------- pCounter ------------------------------- }
  { -> is just used to see if the hack is actually being executed (can be    }
  {    omitted                                                               }
  pCounter:=Pointer(cave + $300);
  inc(PCardinal(pCounter)^);


  { ----------------------------- Init Pointers ---------------------------- }
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


  { ---------------------- Initial Values for Pointers --------------------- }
  if PByte(EnableESP-$4)^=0 then begin
    EnableAimbot^:=1;
    EnableESP^:=1;
    EnableNoclipping^:=1;
    EnableLockAim^:=1;
    EnableMenu:=PByte(GetModuleHandle('sauerbraten.exe') + $30D0E8); //uptodate 09/08/2023
    PByte(EnableESP-$4)^:=1;
    PSingle(MenuPosX)^:=50;
    PSingle(MenuPosY)^:=50;
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
  Menu:=TMenu.Create(PSingle(MenuPosX)^,PSingle(MenuPosY)^,355,150,'SauerHack Reloaded',2.5,EnableESP);
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
  { -> selects best target and keeps aiming                                  }
  {    until the target is dead                                              }
  { -> stops aiming when the enemy is dead                                   }
  { -> reclick hotkey to aim at next taget                                   }
  { -> this should really be its own                                         }
  {    function....}
  PollAimbot();



  { --------------------------------- TATY --------------------------------- }
  if (GetAsyncKeyState(VK_X) <> 0) and (EnableTATY^=1) then
  begin
    //taty.TeleportAllEnemiesInfrontOfYou();  COMMENTED FOR DEBUG
  end;


  { ----------------------------- FlagStealer ------------------------------ }
  { -> teleport between flags                                                }
  { -> infinite points                                                       }
  if (GetAsyncKeyState(VK_P) <> 0) and (EnableFlagSteal^=1) then begin
    //FlagStealer.SpamTeleport();             COMMENTED FOR DEBUG
  end;


  { -------------------------------- Noclip -------------------------------- }
  { -> lets you fly around the map                                           }
  { -> toggles with 'V'                                                      }
  if noclip <> nil then PollNoclip();


  { ---------------------------- Debug Screen F1 --------------------------- }
  { -> Shows inforamtion                                                     }
  { -> toggles with 'F1'                                                     }
  PollDebug();


  { ----------------------------- Drawing ESP ------------------------------ }
  { -> draws red boxes around enemy player                                   }
  if EnableESP^=1 then esp.DrawESP();



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
  glColor3f(0.3, 1.0, 0.3);
  glLineWidth(2);
  glBegin(GL_LINES);
  glVertex2f(0, 0);
  glVertex2f(20.0, 20.0);
  glEnd();

  glColor3f(0.0, 1.0, 0.0);
  glBegin(GL_LINES);
      glVertex2f(20, 0);
      glVertex2f(0, 20);
  glEnd();

  glLeave2DDrawingMode;

  wglMakeCurrent(caveHDC,oldGLContext);
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
  EnableDebug := PByte(cave + $3E0);
  DebugButtonPressed := PByte(cave + $3E8);
  if (GetAsyncKeyState(VK_F1) <> 0) and (DebugButtonPressed^ = 0) and
    (EnableDebug^ = 0) then
  begin
    EnableDebug^ := 1;
    DebugButtonPressed^ := 1;
  end;

  if (GetAsyncKeyState(VK_F1) <> 0) and (DebugButtonPressed^ = 0) and
    (EnableDebug^ = 1) then
  begin
    EnableDebug^ := 0;
    DebugButtonPressed^ := 1;
  end;

  if (GetAsyncKeyState(VK_F1) = 0) then
    DebugButtonPressed^ := 0;

  if EnableDebug^ = 1 then
  begin
    ShowDebugMenu();
  end;
end;


procedure ShowDebugMenu;
var
  Help:array[0..11] of AnsiString;
  Globals:array[0..9] of AnsiString;
  i:Cardinal;
  Y:Cardinal=150;
  X:Cardinal=100;
begin
  glColor3f(0.8, 0.8, 0.8);
  glxDrawString(X, Y+ 000, '::Debug Screen::', 2, True);
  glxDrawString(X, Y+ 015, 'posx: ' + IntToStr(round(Player.pos.x)), 2, True);
  glxDrawString(X, Y+ 030, 'posy: ' + IntToStr(round(Player.pos.y)), 2, True);
  glxDrawString(X, Y+ 045, 'posz: ' + IntToStr(round(Player.pos.z)), 2, True);


  Help[00]:='- right click to aim at target';
  Help[01]:='- ''V'' to noclip. controls are WASD Space LShift LCtrl';
  Help[02]:='- ''X'' to teleport everyone to you';
  Help[03]:='- ''P'' to auto capture flags (works only if the flags are at their spawns)';
  Help[04]:='- the triggerbot checks colors. for it to work you must';
  Help[05]:='  - replace the orgo textureS in packages/models/ogro2';
  Help[06]:='  - replace green.jpg and red.jpg with a filled color of R0 G255 B0';
  Help[07]:='    so they are entirely green';
  Help[08]:='  - in game settings: enable fullbright playermodels and set to max';
  Help[09]:='                      force matching playermodels and play as orgo (or any other model you picked)';
  Help[10]:='                      enable hide dead players';
  Help[11]:='                      in gfx disable: shaders, shadowmaps, dynamic lights, models (lighting, reflection, glow)';


  for i:=0 to Length(Help)-1 do begin
      glxDrawString(X, Y+75+i*15, Help[i], 2, True);
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


  Globals[00]:= 'LockAim: ' + IntToStr(LockAim^);
  Globals[01]:= 'ReleasedRBM: ' + IntToStr(ReleasedRBM^);
  Globals[02]:= 'MenuPosX: ' + IntToStr(Cardinal(MenuPosX^));
  Globals[03]:= 'MenuPosY: ' + IntToStr(Cardinal(MenuPosY^));
  Globals[04]:= 'EnableESP: ' + IntToStr(EnableESP^);
  Globals[05]:= 'EnableAimbot: ' + IntToStr(EnableAimbot^);
  Globals[06]:= 'EnableLockAim: ' + IntToStr(EnableLockAim^);
  Globals[07]:= 'EnableNoclipping: ' + IntToStr(EnableNoclipping^);
  Globals[08]:= 'EnableTATY: ' + IntToStr(EnableTATY^);
  Globals[09]:= 'EnableFlagSteal: ' + IntToStr(EnableFlagSteal^);

  for i:=0 to Length(Globals)-1 do begin
      glxDrawString(X, Y+75+(Length(Help)*15)+i*15, Globals[i], 2, True);
  end;

end;


procedure PollNoclip();
begin
  EnableNoclip := PByte(cave + $3D0);
  NoclipButtonPressed := PByte(cave + $3D8);
  if (GetAsyncKeyState(VK_V) <> 0) and (NoclipButtonPressed^ = 0) and
    (EnableNoclip^ = 0) and (EnableNoclipping^=1) then
  begin
    EnableNoclip^ := 1;
    NoclipButtonPressed^ := 1;
  end;

  if (GetAsyncKeyState(VK_V) <> 0) and (NoclipButtonPressed^ = 0) and
    (EnableNoclip^ = 1) then
  begin
    EnableNoclip^ := 0;
    NoclipButtonPressed^ := 1;
  end;

  if (GetAsyncKeyState(VK_V) = 0) then
    NoclipButtonPressed^ := 0;

  if EnableNoclip^ = 1 then
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


  if Assigned(Aimer) then begin
    if (EnableAimbot^=1) and (EnableLockAim^=1) then begin
      if not (GetAsyncKeyState($1) <> 0) then
        Aimer.ShootByte^ := $0;
      if (GetAsyncKeyState($2) <> 0) then
      begin
        if ReleasedRBM^ = 1 then
        begin
          LockAim^ := 1;
          CurrentBestTarget := Aimer.GetBestTarget(PlayerCount);
          ReleasedRBM^ := 0;
        end;
      end
      else
      begin
        ReleasedRBM^ := 1;
      end;

      if (LockAim^ = 1) and (ReleasedRBM^ = 0) then
      begin
        if Enemy[CurrentBestTarget] <> nil then
        begin
          if Enemy[CurrentBestTarget].hp <= 0 then
          begin
            LockAim^ := 0;
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
          LockAim^ := 0;
        end;
      end
      else
      begin
        LockAim^ := 0;
      end;
    end;

    if (EnableAimbot^=1) and (EnableLockAim^=0) then begin
      if not (GetAsyncKeyState($1) <> 0) then
        Aimer.ShootByte^ := $0;
      if (GetAsyncKeyState($2) <> 0) then begin
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

  glGetIntegerv(GL_VIEWPORT,viewport);
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

end.
