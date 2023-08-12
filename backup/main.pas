unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, gl, glu,
  { my stuff}
  cavepointer, CPlayer, Aimbot, FunctionCaller, CESP, DrawText, CTeleportAllEnemiesToYou, CNoclip,
  CMenuMain, CFlagStealer;

var
  { ------- Variable Storage ------- }
  { -> as of 2022/03/20, locations at}
  {    10300 and beyond seem broken  }
  { -> they probably have been for a }
  {    while now and maybe only      }
  {    worked on Windows 7           }
  { -> Storage of those variables    }
  {    is now moved to a code cave   }
  {    starting at                   }
  {    libmikmod-2.dll+35090         }
  { -> the variable dwLibMikModBase  }
  {    plus an offset will replace   }
  {    any reference to 10300 and    }
  {    beyond                        }
  { -> Init in MainFunc begin!       }
  dwLibMikModBase:DWORD=0;



  { --------- Player Object -------- }
  { -> read position & team          }
  { -> set camera angles             }
  Player: TPlayer;


  { --------- Aimbot Object -------- }
  { -> Target selection              }
  { -> Aiming & auto trigger via     }
  {    color check                   }
  Aimer: TAimbot;


  { ----------- Lock Aim ----------- }
  //LockAim: PByte = PByte(cave + $3C0);
  LockAim: PByte = nil;
  //ReleasedRBM: PByte=PByte(cave + $3C8);
  ReleasedRBM: PByte = nil;
  CurrentBestTarget: integer;


  { ------ Enemy Object Array ------ }
  { -> read position & team          }
  Enemy: array[1..32] of TPlayer;

  PlayerCount: integer;


  { ---------- ESP Object ---------- }
  { -> draw enemies on screen        }
  esp: TESP;


  { ---------- TATY Object ---------- }
  { -> teleport everyone to you       }
  { -> may cause death                }
  taty: TTeleAETY;


  { --------- Noclip Object --------- }
  { -> fly around                     }
  noclip: TNoclip;
  EnableNoclip: PByte;
  NoclipButtonPressed: PByte;


  { ---------- Menu Object ---------- }
  { -> draws menu for controlling     }
  {    settings                       }
  Menu:TMenu;
  //MenuPosX:Pointer=Pointer(cave + $500);
  MenuPosX:Pointer=nil;
  //MenuPosY:Pointer=Pointer(cave + $504);
  MenuPosY:Pointer=nil;
  //EnableESP:PByte=PByte(cave + $600);
  EnableESP:PByte=nil;
  //EnableAimbot:PByte=PByte(cave + $604);
  EnableAimbot:PByte=nil;
  //EnableLockAim:PByte=PByte(cave + $608);
  EnableLockAim:PByte=nil;
  //EnableNoclipping:PByte=PByte(cave + $60C);
  EnableNoclipping:PByte=nil;
  //EnableTATY:PByte=PByte(cave + $610);
  EnableTATY:PByte=nil;
  //EnableFlagSteal:PByte=PByte(cave + $614);
  EnableFlagSteal:PByte=nil;
  EnableMenu:PByte=nil;

  { ------- FlagStealer Object ------ }
  { -> Save location of both flags    }
  { -> teleport back and forth        }
  FlagStealer:TFlagStealer;


  { --------- Debug Screen F1 --------- }
  { -> Shows information                }
  EnableDebug: PByte;
  DebugButtonPressed: PByte;


  { --------- Counter Pointer --------- }
  { -> counts up! :D located at $10300  }
  //pCounter:Pointer=Pointer(cave + $300);
  pCounter:Pointer=nil;


procedure MainFunc();
procedure GetPlayerCount();
procedure ShowDebugMenu();
procedure glEnter2DDrawingMode; stdcall;
procedure glLeave2DDrawingMode; stdcall;
procedure glShowGLError(Marker:Pchar);

implementation

procedure MainFunc();
var
  i: cardinal; //for loop counter
  ii: cardinal;

  oldGLContext:HGLRC;
begin

  oldGLContext:=wglGetCurrentContext;
  wglMakeCurrent(caveHDC,caveNewRC);
  glEnter2DDrawingMode;


  //MessageBox(0,'hello world','hello world',0);

  //glEnter2DDrawingMode;


  pCounter:=Pointer       (cave + $300);
  inc(PCardinal(pCounter)^);
  //GetPlayerCount();


  { --- LibMikModBase Init and other Pointers --- }
  //dwLibMikModBase:=GetModuleHandle('libmikmod-2.dll')+$35190;   //crap, must remove

  { ------ Init Pointers ------ }
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



  { --- Initial Values for Pointers --- }
  if PByte(EnableESP-$4)^=0 then begin
    EnableAimbot^:=1;
    EnableESP^:=1;
    EnableNoclipping^:=1;
    EnableLockAim^:=1;
    EnableMenu:=PByte(GetModuleHandle('sauerbraten.exe') + $30D0E8); //uptodate 09/08/2023
    PByte(EnableESP-$4)^:=1;
    PSingle(MenuPosX)^:=100;
    PSingle(MenuPosY)^:=100;
  end;



  { ------ Object Initialization ------ }
  { -> calls constructor for the        }
  {    localplayer object               }
  { -> calls constructor for the        }
  {    enemy array                      }
  { -> sets the index and stuff..       }
  { -> calls constructor for the        }
  {    esp object                       }
  { -> calls constructor for the        }
  {    aimbot object                    }
  //Player := TPlayer.Create(0); COMMENTED FOR DEBUG
  //Player.Index := 0;           COMMENTED FOR DEBUG
  //Player.GetPlayerData();       COMMENTED FOR DEBUG
  //esp := TESP.Create(@Player, @Enemy, PlayerCount); COMMENTED FOR DEBUG
  //Aimer := TAimbot.Create(@Player, @Enemy);             COMMENTED FOR DEBUG
  //taty := TTeleAETY.Create(@Player, @Enemy, PlayerCount);   COMMENTED FOR DEBUG
  //noclip := TNoclip.Create;                                COMMENTED FOR DEBUG
  Menu:=TMenu.Create(PSingle(MenuPosX)^,PSingle(MenuPosY)^,355,150,'SauerHack Reloaded',2.5,EnableESP);
  //FlagStealer:=TFlagStealer.Create(); COMMENTED FOR DEBUG
  //i := 1;                     COMMENTED FOR DEBUG
  //while (i <= PlayerCount) do   COMMENTED FOR DEBUG
  //begin                          COMMENTED FOR DEBUG
  //  Enemy[i] := TPlayer.Create(i); COMMENTED FOR DEBUG
  //  Enemy[i].Index := i;          COMMENTED FOR DEBUG
  //  Enemy[i].GetPlayerData();      COMMENTED FOR DEBUG
  //  Inc(i);                       COMMENTED FOR DEBUG
  //end;



  { ------------ Aimbot Cylce ------------ }
  { -> Checks hotkey                       }
  { -> selects best target and keeps aiming}
  {    until the target is dead            }
  { -> stops aiming when the enemy is dead }
  { -> reclick hotkey to aim at next taget }
  { -> this should really be its own       }
  {    function....                        }
  (*
  if (EnableAimbot^=1) and (EnableLockAim^=1) then begin
    if not (GetAsyncKeyState($1) <> 0) then
      Aimer.ShootByte^ := $0;
    if (GetAsyncKeyState($2) <> 0) then
    begin
      if ReleasedRBM^ = 1 then                          COMMENTED FOR DEBUG
      begin
        LockAim^ := 1;
        CurrentBestTarget := Aimer.GetBestTarget(PlayerCount);
        ReleasedRBM^ := 0;
      end;
    end
    else
    begin                                                         COMMENTED FOR DEBUG
      ReleasedRBM^ := 1;
    end;

    if (LockAim^ = 1) and (ReleasedRBM^ = 0) then
    begin
      if Enemy[CurrentBestTarget] <> nil then
      begin
        if Enemy[CurrentBestTarget].hp <= 0 then
        begin
          LockAim^ := 0;
        end                                                COMMENTED FOR DEBUG
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

  *)



  { ------------ TATY ------------- }
  if (GetAsyncKeyState(VK_X) <> 0) and (EnableTATY^=1) then
  begin
    //taty.TeleportAllEnemiesInfrontOfYou();COMMENTED FOR DEBUG
  end;


  { ------------ FlagStealer ------------- }
  { -> teleport between flags              }
  { -> infinite points                     }
  if (GetAsyncKeyState(VK_P) <> 0) and (EnableFlagSteal^=1) then begin
    //FlagStealer.SpamTeleport();    COMMENTED FOR DEBUG
  end;


  { --------------- Noclip --------------- }
  { -> lets you fly around the map         }
  { -> toggles with 'V'                    }
  EnableNoclip := PByte(cave + $3D0);
  //EnableNoclip := PByte(dwLibMikModBase + $0D0);
  NoclipButtonPressed := PByte(cave + $3D8);
  //NoclipButtonPressed := PByte(dwLibMikModBase + $0D8);
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
    //noclip.PollControls;           COMMENTED FOR DEBUG
    //noclip.NOPFalling(True);       COMMENTED FOR DEBUG
  end
  else
  begin
    //noclip.NOPFalling(False);        COMMENTED FOR DEBUG
  end;



  { --------------- Debug Screen F1 --------------- }
  { -> Shows inforamtion                            }
  { -> toggles with 'V'                             }
  EnableDebug := PByte(cave + $3E0);
  //EnableDebug := PByte(dwLibMikModBase + $0E0);
  DebugButtonPressed := PByte(cave + $3E8);
  //DebugButtonPressed := PByte(dwLibMikModBase + $0E8);
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



  { ------------ Drawing ESP ------------- }
  { -> draws red boxes around enemy player }
  //if EnableESP^=1 then esp.DrawESP();        COMMENTED FOR DEBUG



  { ------------ Drawing Menu ------------ }
  { -> draws menu                          }
  { -> init menu settings                  }
  if EnableMenu^ = 1 then
  begin
      glEnable(GL_BLEND);
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
      glEnable(GL_LINE_SMOOTH);
      glLineWidth(1);
      Menu.PollControls;
      Menu.DrawMenu;
  end;



  { ------ Object Destroyer ------ }
  { -> prevent leaks. doesn't work }
  { -> TO DO: FIX THIS///Done..    }
  //Aimer.Destroy;                            COMMENTED FOR DEBUG
  //Player.Destroy;                       COMMENTED FOR DEBUG
  //esp.Destroy;                      COMMENTED FOR DEBUG
  //taty.Destroy;                 COMMENTED FOR DEBUG
  //noclip.Destroy;             COMMENTED FOR DEBUG
  //Menu.Destroy;
  //FlagStealer.Destroy;    COMMENTED FOR DEBUG
  //i := 1;       COMMENTED FOR DEBUG
  //while (i <= PlayerCount) do COMMENTED FOR DEBUG
  //begin          COMMENTED FOR DEBUG
    //Enemy[i].Destroy;    COMMENTED FOR DEBUG
    //Inc(i);    COMMENTED FOR DEBUG
  //end;      COMMENTED FOR DEBUG



  { ----- Debug Line ----- }
  { -> confirms hack       }
  {    is active           }

  //glClear(GL_COLOR_BUFFER_BIT);

  glColor3f(0.3, 1.0, 0.3);
  glShowGLError('glColor');
  glLineWidth(5);
  glShowGLError('glLineWidth');
  glBegin(GL_LINES);
  glShowGLError('glBegin');
  glVertex2f(-1, -1);
  glShowGLError('glVertex2f(-1,-1)');
  glVertex2f(1.0, 1.0);
  glShowGLError('glVertex2f(1,1)');
  glEnd();
  glShowGLError('glEnd(1,1)');


  glColor3f(0.0, 1.0, 0.0);
  glShowGLError('glcolor');
  glBegin(GL_LINES);
  glShowGLError('glbegin');
      glVertex2f(-0.5, -0.5);
      glShowGLError('glvertex2f');
      glVertex2f(0.5, 0.5);
      glShowGLError('glvertex2f again');
  glEnd();
  glShowGLError('glEnd');

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

procedure ShowDebugMenu;
var
  Help:array[0..11] of AnsiString;
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
end;

procedure glEnter2DDrawingMode; stdcall;
var
   viewport: array[0..3] of GLint;
begin
  //glDisable(GL_DEPTH_TEST);
  //glDisable(GL_CULL_FACE);
  //glDisable(GL_TEXTURE_2D);
  //glDisable(GL_LIGHTING);



  glShowGLError('just nothing');
  glMatrixMode(GL_PROJECTION);
  glShowGLError('glMatrixMode(GL_PROJECTION)');
  glLoadIdentity();
  glShowGLError('glLoadIdentity()');

  glGetIntegerv(GL_VIEWPORT,viewport);


  glOrtho(0, viewport[2], viewport[3], 1.0, -1.0, 1.0);
  glShowGLError('glOrtho(-1.0, 1.0, -1.0, 1.0, -1.0, 1.0)');

  glMatrixMode(GL_MODELVIEW);
  glShowGLError('glMatrixMode(GL_MODELVIEW)');
  glLoadIdentity();
  glShowGLError('glLoadIdentity()');

end;

procedure glLeave2DDrawingMode; stdcall;
begin
  glFlush();
  glEnable(GL_TEXTURE_2D);
end;

procedure glShowGLError(Marker: Pchar);
var
  error_code:GLenum;
begin
  error_code:=glGetError();
  if(error_code <> GL_NO_ERROR) then begin
                //MessageBox(0,PChar('Error in "' + Marker + '":' + IntToStr(error_code)),'gl kaputt',0);
  end;
  glGetError();
end;

end.
