unit CTeleportAllEnemiesToYou;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, gl,
  CPlayer, Aimbot, DrawText;

type
  TEnArr = array[1..32] of TPlayer;
  PTEnArr = ^TEnArr;

  { TTeleAETY }
  { -> this will probably never work right the way it is right now }
  { -> BUT it used to work so there is some hope but more research }
  {    is required. the positions listed in the entitylist somehow }
  {    don't carry the hitbox or something so no damage is         }
  {    sent to the server                                          }

  TTeleAETY = class
    constructor Create(plr: PTPlayer; enr: PTEnArr; PlayerCount: cardinal);
    procedure TeleportAllEnemiesInfrontOfYou(); stdcall;
    function IsTeamBased(): boolean; stdcall;

  public
    ply: PTPlayer;
    en: PTEnArr;
    plrcnt: cardinal;
  end;

implementation

{ TTeleAETY }

constructor TTeleAETY.Create(plr: PTPlayer; enr: PTEnArr; PlayerCount: cardinal);
begin
  ply := plr;
  en := enr;
  plrcnt := PlayerCount;
end;


{ ------------ TeleportAllEnemiesInfrontOfYou ------------ }
{ -> uses the aimbot target selection to teleport all      }
{    enemies (or something.. definitly not the hitbox :(   }
procedure TTeleAETY.TeleportAllEnemiesInfrontOfYou(); stdcall;
var
  i: cardinal;
  viewp: array[0..3] of GLint;
begin
  i := 1;
  while i <= plrcnt do
  begin
    if (en^[i].IsSpectating = False) and (en^[i].hp > 0) then
    begin
      if (en^[i].TeamString[0] <> ply^.TeamString[0]) or (not IsTeamBased()) then
      begin
        en^[i].SetPos(ply^.pos.x, ply^.pos.y, ply^.pos.z);
        en^[i].SetPosAlt(ply^.pos.x, ply^.pos.y, ply^.pos.z);
      end;
    end;
    Inc(i);
  end;

  glColor3f(0.8, 0.8, 0.8);
  glGetIntegerv(GL_VIEWPORT, viewp);
  glxDrawString(20, viewp[3] - 100, 'Teleporting everyone to you', 2, True);
end;

function TTeleAETY.IsTeamBased(): boolean; stdcall;
var
  TeamValue: byte;
begin
  TeamValue := PBYTE(cardinal(GetModuleHandle('sauerbraten.exe')) + $2A636C)^; //uptodate 2023/08/13
  case (TeamValue) of
    0: Result := False;
    1: Result := False;
    2: Result := True;
    3: Result := False;
    4: Result := True;
    5: Result := False;
    6: Result := True;
    7: Result := False;
    8: Result := True;
    9: Result := False;
    10: Result := False;
    11: Result := True;
    12: Result := True;
    13: Result := True;
    14: Result := True;
    15: Result := False;
    16: Result := False;
    17: Result := True;
    18: Result := True;
    19: Result := False;
    20: Result := True;
    else
      Result := False;
  end;

end;




end.

