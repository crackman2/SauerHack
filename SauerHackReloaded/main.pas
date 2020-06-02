unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, gl,
  { my stuff}
  CPlayer, Aimbot, FunctionCaller, CESP, DrawText, CTeleportAllEnemiesToYou, CNoclip;

var
  { --------- Player Object -------- }
  { -> read position & team          }
  { -> set camera angles             }
  Player: TPlayer;


  { --------- Aimbot Object -------- }
  { -> Target selection              }
  { -> Aiming & auto trigger via     }
  {    color check                   }
  Aimer: TAimbot;


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

  { ---------- Lock Aim ---------- }
  LockAim: PByte;
  ReleasedRBM: PByte;
  CurrentBestTarget: integer;


  { --------- Debug Screen F1 --------- }
  { -> Shows information                }
  EnableDebug: PByte;
  DebugButtonPressed: PByte;



procedure MainFunc();
procedure GetPlayerCount();
procedure ShowDebugMenu();

implementation

procedure MainFunc();
var
  i: cardinal; //for loop counter
begin

  GetPlayerCount();
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
  Player := TPlayer.Create(0);
  Player.Index := 0;
  Player.GetPlayerData();
  esp := TESP.Create(@Player, @Enemy, PlayerCount);
  Aimer := TAimbot.Create(@Player, @Enemy);
  taty := TTeleAETY.Create(@Player, @Enemy, PlayerCount);
  noclip := TNoclip.Create;
  i := 1;
  while (i <= PlayerCount) do
  begin
    Enemy[i] := TPlayer.Create(i);
    Enemy[i].Index := i;
    Enemy[i].GetPlayerData();
    Inc(i);
  end;



  { ------------ Aimbot Cylce ------------ }
  { -> Checks hotkey                       }
  { -> selects best target and keeps aiming}
  {    until the target is dead            }
  { -> stops aiming when the enemy is dead }
  { -> reclick hotkey to aim at next taget }
  { -> this should really be its own       }
  {    function....                        }
  LockAim := PByte($103C0);
  ReleasedRBM := PByte($103C8);

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
        if GetAsyncKeyState(VK_P) <> 0 then
        begin
          MessageBox(0, PChar('Current Target: 0x' +
            IntToHex(DWORD(Enemy[CurrentBestTarget].PlayerBase), 8)), 'e', 0);
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


  { ------------ TATY ------------- }
  if GetAsyncKeyState(VK_X) <> 0 then
  begin
    taty.TeleportAllEnemiesInfrontOfYou();
  end;

  { --------------- Noclip --------------- }
  { -> lets you fly around the map         }
  { -> toggles with 'V'                    }
  EnableNoclip := PByte($103D0);
  NoclipButtonPressed := PByte($103D8);
  if (GetAsyncKeyState(VK_V) <> 0) and (NoclipButtonPressed^ = 0) and
    (EnableNoclip^ = 0) then
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
  end
  else
  begin
    noclip.NOPFalling(False);
  end;



  { --------------- Debug Screen F1 --------------- }
  { -> Shows inforamtion                            }
  { -> toggles with 'V'                             }
  EnableDebug := PByte($103E0);
  DebugButtonPressed := PByte($103E8);
  if (GetAsyncKeyState(VK_F1) <> 0) and (DebugButtonPressed^ = 0) and (EnableDebug^ = 0) then
  begin
    EnableDebug^ := 1;
    DebugButtonPressed^ := 1;
  end;

  if (GetAsyncKeyState(VK_F1) <> 0) and (DebugButtonPressed^ = 0) and (EnableDebug^ = 1) then
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
  esp.DrawESP();




  { ------ Object Destroyer ------ }
  { -> prevent leaks. doesn't work }
  { -> TO DO: FIX THIS             }
  Aimer.Destroy;
  Player.Destroy;
  esp.Destroy;
  taty.Destroy;
  noclip.Destroy;
  i := 1;
  while (i <= PlayerCount) do
  begin
    Enemy[i].Destroy;
    Inc(i);
  end;


  { ----- Debug Line ----- }
  { -> confirms hack       }
  {    is active           }
  glLineWidth(1);
  glBegin(GL_LINES);
  glVertex2f(0, 0);
  glVertex2f(20, 20);
  glEnd();

end;

procedure GetPlayerCount();
var
  tmp: PInteger;
begin
  tmp := PInteger(GetModuleHandle('sauerbraten.exe') + $29CD3C);
  PlayerCount := tmp^ - 1; //not counting local player
end;

procedure ShowDebugMenu;
begin
  glColor3f(0.8, 0.8, 0.8);
  glxDrawString(200, 200, '::Debug Screen::', 2, True);
  glxDrawString(200, 215, 'posx: ' + IntToStr(round(Player.pos.x)), 2, True);
  glxDrawString(200, 230, 'posy: ' + IntToStr(round(Player.pos.y)), 2, True);
  glxDrawString(200, 245, 'posz: ' + IntToStr(round(Player.pos.z)), 2, True);
end;




end.
