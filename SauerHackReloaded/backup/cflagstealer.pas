unit CFlagStealer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, windows,

  CPlayer, CustomTypes;


type

  { TFlagStealer }

  TFlagStealer = class
    Constructor Create();
    procedure SpamTeleport();

  private
    function IsCTFMode(): boolean; stdcall;
    public
    RedFlagPointer:Pointer;
    BlueFlagPointer:Pointer;

    FlipFlop:PByte;

    PlyPos:PRVec3;
  end;

implementation

{ TFlagStealer }

constructor TFlagStealer.Create();
var
  Sauerbase:Pointer;
  PlayerPosStruct:Pointer;
  Original:Pointer;
begin
  Sauerbase:=Pointer(GetModuleHandle('sauerbraten.exe'));
  FlipFlop:=PByte($10700);


  Original:=Pointer(Sauerbase + $29D200);
  BlueFlagPointer:=Pointer(Original^) + $88;

  Original:=Pointer(Sauerbase + $29D200);
  RedFlagPointer:=Pointer(Original^) + $18;



  Original := Pointer(Sauerbase + $213EA8);
  PlayerPosStruct := Pointer(Original^) + $30;
  PlyPos:=PlayerPosStruct;

end;


procedure TFlagStealer.SpamTeleport();
begin
  if FlipFlop^=0 then begin
    FlipFlop^:=1;
    PlyPos^.x:=PSingle(RedFlagPointer + $0)^;
    PlyPos^.y:=PSingle(RedFlagPointer + $4)^;
    PlyPos^.z:=PSingle(RedFlagPointer + $8)^ + 15;
  end
  else begin
    FlipFlop^:=0;
     PlyPos^.x:=PSingle(BlueFlagPointer + $0)^;
     PlyPos^.y:=PSingle(BlueFlagPointer + $4)^;
     PlyPos^.z:=PSingle(BlueFlagPointer + $8)^ + 15;
  end;
end;



function TFlagStealer.IsCTFMode(): boolean; stdcall;
var
  TeamValue: byte;
begin
  TeamValue := PBYTE(cardinal(GetModuleHandle('sauerbraten.exe')) + $1E5C28)^;
  case (TeamValue) of
    11: Result := True;
    12: Result := True;
    17: Result := True;
    else
      Result := False;
  end;

end;

end.

