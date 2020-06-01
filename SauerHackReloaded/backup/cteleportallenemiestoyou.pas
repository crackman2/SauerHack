unit CTeleportAllEnemiesToYou;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, windows, gl,

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
    constructor Create(plr: PTPlayer; enr: PTEnArr;PlayerCount:Cardinal);
    procedure TeleportAllEnemiesInfrontOfYou();stdcall;
    function IsTeamBased(): Boolean; stdcall;
    public
      ply:PTPlayer;
      en:PTEnArr;
      plrcnt:Cardinal;
  end;

implementation

{ TTeleAETY }

constructor TTeleAETY.Create(plr: PTPlayer; enr: PTEnArr;PlayerCount:Cardinal);
begin
  ply:=plr;
  en:=enr;
  plrcnt:=PlayerCount;
end;

procedure TTeleAETY.TeleportAllEnemiesInfrontOfYou(); stdcall;
var
  i:Cardinal;
  viewp:array[0..3] of GLint;
begin
  i:=1;
  while i <= plrcnt do
  begin
    if (en^[i].IsSpectating = False) and (en^[i].hp > 0) then
    begin
      if (en^[i].TeamString[0] <> ply^.TeamString[0]) or (not IsTeamBased()) then
      begin
           en^[i].SetPos(ply^.pos.x,ply^.pos.y,ply^.pos.z);
      end;
    end;
    inc(i);
  end;

  glColor3f(0.8,0.8,0.8);
  glGetIntegerv(GL_VIEWPORT,viewp);
  glxDrawString(20,viewp[3]- 100,'Teleporting everyone to you',2,true);
end;

function TTeleAETY.IsTeamBased(): Boolean; stdcall;
var
  TeamValue:Byte;
begin
  TeamValue:=PBYTE(Cardinal(GetModuleHandle('sauerbraten.exe')) + $1E5C28)^;
  case (TeamValue) of
  0:Result:=False;
  1:Result:=False;
  2:Result:=true;
  3:Result:=False;
  4:Result:=true;
  5:Result:=False;
  6:Result:=true;
  7:Result:=False;
  8:Result:=true;
  9:Result:=False;
  10:Result:=False;
  11:Result:=true;
  12:Result:=true;
  13:Result:=true;
  14:Result:=true;
  15:Result:=False;
  16:Result:=False;
  17:Result:=true;
  18:Result:=true;
  19:Result:=False;
  20:Result:=true;
  else
    Result:=False;
  end;

end;




end.

