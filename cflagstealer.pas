unit CFlagStealer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, windows,

  CPlayer, CustomTypes, GlobalVars;


type

  { TFlagStealer }

  TFlagStealer = class
    Constructor Create(ply:TPlayer);
    procedure SpamTeleport();

  private
    function IsCTFMode(): boolean; stdcall;
    public
    RedFlagPointer:Pointer;
    BlueFlagPointer:Pointer;
    FlipFlop:PByte;
    PlyPos:PRVec3;

    ply:TPlayer;
  end;

implementation

{ TFlagStealer }

{ ------------------------------- FlagStealer ------------------------------ }
{ -> Reads the position of both flags in ctf modes                           }
{ -> Teleports the player back and forth to both positions                   }
{ -> easily detected by server scripts and admins                            }
constructor TFlagStealer.Create(ply:TPlayer);
var
  Sauerbase:Pointer;
  Original:Pointer;
begin
  Sauerbase:=Pointer(GetModuleHandle('sauerbraten.exe'));

  FlipFlop:=PByte(g_cave + $700);

  Original:=Pointer(Sauerbase + $29D200);
  BlueFlagPointer:=Pointer(Original^) + $88;

  Original:=Pointer(Sauerbase + $29D200);
  RedFlagPointer:=Pointer(Original^) + $18;

  Self.ply:=ply;
end;

{ ------------------------------ SpamTeleport ------------------------------ }
{ -> FlipFlop decides which place to teleport to next                        }
procedure TFlagStealer.SpamTeleport();
begin
  if IsCTFMode() then begin
    if FlipFlop^=0 then begin
      FlipFlop^:=1;
      ply.SetPos(  PSingle(RedFlagPointer + $0)^,
                   PSingle(RedFlagPointer + $4)^,
                   PSingle(RedFlagPointer + $8)^ + 15);
    end
    else begin
      FlipFlop^:=0;
       ply.SetPos( PSingle(RedFlagPointer + $0)^,
                   PSingle(RedFlagPointer + $4)^,
                   PSingle(RedFlagPointer + $8)^ + 15);
    end;
  end;
end;



function TFlagStealer.IsCTFMode(): boolean; stdcall;
var
  TeamValue: byte;
begin
  TeamValue := PBYTE(cardinal(GetModuleHandle('sauerbraten.exe')) + $2A636C)^; //uptodate 2023/08/13
  case (TeamValue) of
    11: Result := True;
    12: Result := True;
    17: Result := True;
    else
      Result := False;
  end;

end;

end.

