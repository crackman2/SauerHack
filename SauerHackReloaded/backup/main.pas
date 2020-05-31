unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows,gl,
  { my stuff}
  CPlayer, Aimbot, FunctionCaller, CESP, DrawText;

var
{ --------- Player Object -------- }
{ -> read position & team          }
{ -> set camera angles             }
Player:TPlayer;
Aimer:TAimbot;


{ ------ Enemy Object Array ------ }
{ -> read position & team          }
Enemy:array[1..32] of TPlayer;

PlayerCount:Integer;


{ ---------- ESP Object ---------- }
{ -> draw enemies on screen        }
esp:TESP;


{ ---------- Lock Aim ---------- }
LockAim:PByte;
ReleasedRBM:PByte;
CurrentBestTarget:Integer;


procedure MainFunc();
procedure GetPlayerCount();

implementation

procedure MainFunc();
var
   i:Cardinal; //for loop counter
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
  Player:=TPlayer.Create(0);
  Player.Index:=0;
  Player.GetPlayerData();
  esp:=TESP.Create(@Player,@Enemy,PlayerCount);
  Aimer:=TAimbot.Create(@Player,@Enemy);
  i:=1;
  while (i <= PlayerCount) do
  begin
    Enemy[i]:=TPlayer.Create(i);
    Enemy[i].Index:=i;
    Enemy[i].GetPlayerData();
    inc(i)
  end;



  { ------------ Aimbot Cylce ------------ }
  { -> Checks hotkey                       }
  { -> selects best target and keeps aiming}
  {    until the target is dead            }
  { -> stops aiming when the enemy is dead }
  { -> reclick hotkey to aim at next taget }
  LockAim:=PByte($103C0);
  ReleasedRBM:=PByte($103C8);
  Aimer.ShootByte^:=$0;
  if (GetAsyncKeyState($2) <> 0) then
  begin
    if ReleasedRBM^ = 1 then
    begin
      LockAim^:=1;
      CurrentBestTarget:=Aimer.GetBestTarget(PlayerCount);
      ReleasedRBM^:=0;
    end;
  end
  else
  begin
    ReleasedRBM^:=1;
  end;

  if (LockAim^ = 1) and (ReleasedRBM^ = 0) then
  begin
    if Enemy[CurrentBestTarget] <> nil then
    begin
       if Enemy[CurrentBestTarget].hp <= 0 then
       begin
         LockAim^:=0;
       end
       else
       begin
        Aimer.Aim(CurrentBestTarget);
        Aimer.AutoTrigger();
       end;
    end
    else
    begin
      LockAim^:=0;
      glxDrawString(1600/2,(900/2),'LockAim 0 because Target is invalid',3,false);
    end;
  end
  else
  begin
    LockAim^:= 0;
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
  i:=1;
  while (i <= PlayerCount) do
  begin
    Enemy[i].Destroy;
    inc(i)
  end;


  { ----- Debug Line ----- }
  { -> confirms hack       }
  {    is active           }
  glLineWidth(1);
  glBegin(GL_LINES);
  glVertex2f(0,0);
  glVertex2f(20,20);
  glEnd();


end;

procedure GetPlayerCount();
var
   tmp:PInteger;
begin
  tmp:=PInteger(GetModuleHandle('sauerbraten.exe') + $29CD3C);
  PlayerCount:=tmp^-1;
end;



end.

