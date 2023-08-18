unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, gl, glu,
  { my stuff}
  GlobalVars, GlobalObjects, GlobalOffsets, CPlayer, CAimbot, cfunctioncaller, CESP, DrawText,
  CTeleportAllEnemiesToYou, CNoclip,
  CMenuMain, CFlagStealer;

var
  { -------------------------- Enemy Object Array -------------------------- }
  { -> read position & team                                                  }
  Enemy: array[1..32] of TPlayer;
  PlayerCount: integer;


  { ------------------------------- ViewPort ------------------------------- }
  { -> used to detect changes in resolution and move the menu accordingly    }
  newviewp: array[0..3] of GLint = (0,0,0,0);
  viewp: array[0..3] of GLint = (0,0,0,0);



procedure MainFunc();
procedure GetPlayerCount();
procedure PollDebug();
procedure ShowDebugMenu();
procedure glEnter2DDrawingMode; stdcall;
procedure glLeave2DDrawingMode; stdcall;
procedure DrawDebugLine();
procedure ShowMissingObjectError(MissingObjectName: PChar);



implementation

procedure MainFunc();
var
  i: cardinal; //for loop counter
  OldRC: HGLRC;


begin
  { ------------------------ Prepare OpenGL Drawing ------------------------ }
  { -> OldRC is the current context used by the game. Apparently it          }
  {    is impossible to use in it's current state for our purposes, so we    }
  {    just create a new one                                                 }
  { -> caveHDC is the device context, grabbed frome the wglSwapBuffers call  }
  { -> caveNewRC is a new device context that was created when the hook code }
  {    was run the first time                                                }

  { -------- Resolution Change ------- }
  { -> if resolution of the game       }
  {    changes, a new RC with the      }
  {    correct resolution is created   }
  {    and used                        }
  if Assigned(g_Menu) then begin
    if g_Menu.bInitialSetup then begin
      glGetIntegerv(GL_VIEWPORT, newviewp);
      if (viewp[2] <> newviewp[2]) or (viewp[3] <> newviewp[3]) then begin
        OldRC := wglGetCurrentContext;
        wglMakeCurrent(0,0);
        wglDeleteContext(g_NewRC);
        g_NewRC:=wglCreateContext(g_HDC);
        wglMakeCurrent(g_HDC,g_NewRC);
        glViewport(0, 0, newviewp[2], newviewp[3]);
        wglMakeCurrent(g_HDC, OldRC);
        glGetIntegerv(GL_VIEWPORT, viewp);
        g_Menu.bInitialSetup:=False;
      end;
    end;
  end;

  { --- Prepare Rendering Context ---- }
  OldRC := wglGetCurrentContext;
  wglMakeCurrent(g_HDC, g_NewRC);
  glEnter2DDrawingMode;



  { ------------------------------- pCounter ------------------------------- }
  { -> is just used to see if the hack is actually being executed (can be    }
  {    omitted                                                               }
  Inc(g_pCounter);


  //taty := TTeleAETY.Create(@Player, @Enemy, PlayerCount);   COMMENTED FOR DEBUG
  //FlagStealer:=TFlagStealer.Create(); COMMENTED FOR DEBUG


  { ---------------------------- Update Objects ---------------------------- }
  { -> create a fresh enemy array of enemies                                 }
  { -> update the data the objects have to work with                         }
  { ---- Enemy Array ---- }
  GetPlayerCount();
  i := 1;
  while (i <= PlayerCount) do
  begin
    Enemy[i] := TPlayer.Create(i);
    Enemy[i].GetPlayerData;
    Inc(i);
  end;

  { ---- Local Player --- }
  if Assigned(g_Player) then
    g_Player.GetPlayerData;

  { ------- Aimbot ------ }
  if Assigned(g_Aimer) then begin
    g_Aimer.SetEnemyArray(Enemy);
    g_Aimer.SetPlayerCount(PlayerCount);
  end;

  { -------- ESP -------- }
  if Assigned(g_ESP) then
  begin
    g_ESP.SetEnemyArray(Enemy);
    g_ESP.SetPlayerCount(PlayerCount);
  end;

  { -------- Menu ------- }
  if Assigned(g_Menu) and not g_Menu.bInitialSetup then begin
    glGetIntegerv(GL_VIEWPORT, viewp);
    g_Menu.SetPos(viewp[2] - g_Menu.menudim.x, 0); //move to top right corner
    g_Menu.bInitialSetup:=True;
  end;




  { ----------------------------- Aimbot Cylce ----------------------------- }
  { -> Checks hotkey                                                         }
  { -> selects best target and keeps aiming until the target is dead         }
  { -> stops aiming when the enemy is dead                                   }
  { -> reclick hotkey to aim at next taget                                   }
  { -> this should really be its own function...                             }
  if Assigned(g_Aimer) then g_Aimer.Poll else ShowMissingObjectError('g_FlagStealer');



  { --------------------------------- TATY --------------------------------- }
  { -> CURRENTLY BROKEN                                                      }
  if (GetAsyncKeyState(VK_X) <> 0) and (g_EnableTATY = 1) then
  begin
    //taty.TeleportAllEnemiesInfrontOfYou();  COMMENTED FOR DEBUG
  end;


  { ----------------------------- FlagStealer ------------------------------ }
  { -> CURRENTLY BROKEN                                                      }
  { -> teleport between flags                                                }
  { -> infinite points                                                       }
  if Assigned(g_FlagStealer) then begin
    if (GetAsyncKeyState(VK_P) <> 0) and (g_EnableFlagSteal = 1) then
    begin
      g_FlagStealer.SpamTeleport();
    end;
  end else ShowMissingObjectError('g_FlagStealer');


  { -------------------------------- Noclip -------------------------------- }
  { -> lets you fly around the map                                           }
  { -> toggles with 'V'                                                      }
  if Assigned(g_Noclip) then
    g_Noclip.Poll()
  else
  begin
    ShowMissingObjectError('g_Noclip');
  end;


  { ---------------------------- Debug Screen F1 --------------------------- }
  { -> Shows inforamtion                                                     }
  { -> toggles with 'F1'                                                     }
  PollDebug();



  { ----------------------------- Drawing ESP ------------------------------ }
  { -> draws red boxes around enemy player                                   }
  if g_EnableESP = 1 then
    g_ESP.DrawESP();



  { ----------------------------- Drawing Menu ----------------------------- }
  { -> draws menu                                                            }
  { -> init menu settings                                                    }
  if g_EnableMenu^ = 1 then
  begin
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_LINE_SMOOTH);
    glLineWidth(1);
    if Assigned(g_Menu) then
    begin
      g_Menu.PollControls;
      g_Menu.DrawMenu;
    end
    else
    begin
      ShowMissingObjectError('g_Menu');
    end;
  end;



  { --------------------------- Object Destroyer --------------------------- }
  { -> destory enemy array                                                   }
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
  wglMakeCurrent(g_HDC, OldRC);
end;



procedure GetPlayerCount();
var
  tmp: PInteger;
begin
  tmp := PInteger(g_offset_SauerbratenBase + g_offset_PlayerCount); //uptodate 09/08/2023
  PlayerCount := tmp^ - 1; //not counting local player
end;



{ -------------------------------- PollDebug ------------------------------- }
{ -> for ShowDebugMenu                                                       }
{ -> includes mechanism to prevent spamming (kind of the sole purpose for    }
{    most of the code in this fucntion)                                      }
procedure PollDebug();
begin
  if (GetAsyncKeyState(VK_F1) <> 0) and (g_DebugButtonPressed = 0) and
    (g_EnableDebug = 0) then
  begin
    g_EnableDebug := 1;
    g_DebugButtonPressed := 1;
  end;

  if (GetAsyncKeyState(VK_F1) <> 0) and (g_DebugButtonPressed = 0) and
    (g_EnableDebug = 1) then
  begin
    g_EnableDebug := 0;
    g_DebugButtonPressed := 1;
  end;

  if (GetAsyncKeyState(VK_F1) = 0) then
    g_DebugButtonPressed := 0;

  if g_EnableDebug = 1 then
  begin
    ShowDebugMenu();
  end;
end;



{ ------------------------------ ShowDebugMenu ----------------------------- }
{ -> displays some info and a guide on how to use things                     }
procedure ShowDebugMenu;
var
  Help: array[0..11] of ansistring;
  Globals: array[0..10] of ansistring;
  i: cardinal;
  Y: cardinal = 150;
  X: cardinal = 100;
begin
  { --------------------- Print Position --------------------- }
  glColor3f(0.8, 0.8, 0.8);
  glxDrawString(X, Y + 000, '::Debug Screen::', 2, True);
  glxDrawString(X, Y + 015, 'posx: ' + IntToStr(round(g_Player.pos.x)), 2, True);
  glxDrawString(X, Y + 030, 'posy: ' + IntToStr(round(g_Player.pos.y)), 2, True);
  glxDrawString(X, Y + 045, 'posz: ' + IntToStr(round(g_Player.pos.z)), 2, True);

  { --------------------- Print Tutorial --------------------- }
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

  { ------------- Print Globals & some Settings ------------- }
  Globals[00] := 'LockAim: ' + BoolToStr(g_Aimer.bLockAim);
  Globals[01] := 'ReleasedRBM: ' + BoolToStr(g_Aimer.bReleasedRBM);
  Globals[02] := 'MenuPosX: ' + FloatToStr(g_Menu.MenuPosX);
  Globals[03] := 'MenuPosY: ' + FloatToStr(g_Menu.MenuPosY);
  Globals[04] := 'EnableESP: ' + IntToStr(g_EnableESP);
  Globals[05] := 'EnableAimbot: ' + IntToStr(g_EnableAimbot);
  Globals[06] := 'EnableLockAim: ' + IntToStr(g_EnableLockAim);
  Globals[07] := 'EnableNoclipping: ' + IntToStr(g_EnableNoclipping);
  Globals[08] := 'EnableTATY: ' + IntToStr(g_EnableTATY);
  Globals[09] := 'EnableFlagSteal: ' + IntToStr(g_EnableFlagSteal);
  Globals[10] := 'EnableFrameShot: ' + IntToStr(g_EnableFrameShot);

  for i := 0 to Length(Globals) - 1 do
  begin
    glxDrawString(X, Y + 75 + (Length(Help) * 15) + i * 15, Globals[i], 2, True);
  end;

end;



{ -------------------------- glEnter2DDrawingMode -------------------------- }
{ -> sets out context up to draw properly                                    }
{ -> glGetIntegerv and glOrtho allow us to use usual x,y pixel coordinates   }
{    meaning that 0,0 is the top left pixel and the bottom right one is      }
{    equal to the current resolution                                         }
procedure glEnter2DDrawingMode; stdcall;
var
  viewport: array[0..3] of GLint = (0,0,0,0);
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



{ ------------------------------ DrawDebugLine ----------------------------- }
{ -> creates art in the top left corner. let's us know if hooking OpenGL     }
{    worked                                                                  }
procedure DrawDebugLine();
var
  c1: single;
  i: cardinal;
  FPS: PInteger;
begin
  FPS := Pointer(g_offset_SauerbratenBase + g_offset_FPS);

  if FPS^ > 0 then begin
    c1 := g_pCounter / (FPS^*2);
    for i := 0 to (round(c1) mod (FPS^*2)) do
    begin
      glColor3f((Round(c1+i) mod 50)/50,(Round(c1+i/2) mod 100)/100,(Round(c1+i/4) mod 25)/25);
      glLineWidth(1);
      glBegin(GL_LINES);
      glVertex2f(30.0 + cos(i+ c1 + c1) * (40*sin(c1))     , 30.0 + sin(i+c1) * (40*sin(c1)));
      glVertex2f(30.0 + cos(i + 1) * (40*sin(c1))    , 30.0 + sin(i+ 1) * (40*sin(c1)));

      glEnd();
    end;
  end;
end;



procedure ShowMissingObjectError(MissingObjectName: PChar);
begin
  MessageBox(0, PChar(MissingObjectName + ' is not assigned. Exiting.'), 'Sauerhack Reloaded', 0);
  ExitProcess(1);
end;

end.
