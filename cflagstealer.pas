unit CFlagStealer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows,
  CPlayer, CustomTypes, GlobalVars, GlobalOffsets;

type

  { TFlagStealer }

  TFlagStealer = class
    constructor Create(ply: TPlayer);
    procedure SpamTeleport();

  private
    function IsCTFMode(): boolean; stdcall;
  public
    EvilFlagPointer: Pointer;
    GoodFlagPointer: Pointer;
    FlipFlop: boolean;
    PlyPos: PRVec3;
    ply: TPlayer;
  end;

implementation

{ TFlagStealer }

{ ------------------------------- FlagStealer ------------------------------ }
{ -> Reads the position of both flags in ctf modes                           }
{ -> Teleports the player back and forth to both positions                   }
{ -> easily detected by server scripts and admins                            }
constructor TFlagStealer.Create(ply: TPlayer);
begin
  Self.ply := ply;

end;

{ ------------------------------ SpamTeleport ------------------------------ }
{ -> FlipFlop decides which place to teleport to next                        }
procedure TFlagStealer.SpamTeleport();
var
  Original: Pointer;
begin
  Original := Pointer(g_offset_SauerbratenBase + g_offset_FlagStealerBase);
  GoodFlagPointer := PPointer(Original)^ + g_offset_FlagGood;
  EvilFlagPointer := PPointer(Original)^ + g_offset_FlagEvil;

  if IsCTFMode() then
  begin
    if FlipFlop then
    begin
      FlipFlop := False;
      ply.SetPosAlt(PSingle(EvilFlagPointer + $0)^,
        PSingle(EvilFlagPointer + $4)^,
        PSingle(EvilFlagPointer + $8)^ + 15);
    end
    else
    begin
      FlipFlop := True;
      ply.SetPosAlt(PSingle(GoodFlagPointer + $0)^,
        PSingle(GoodFlagPointer + $4)^,
        PSingle(GoodFlagPointer + $8)^ + 15);
    end;
  end;
end;



function TFlagStealer.IsCTFMode(): boolean; stdcall;
var
  TeamValue: byte;
begin
  TeamValue := PBYTE(g_offset_SauerbratenBase + g_offset_TeamValue)^;
  //uptodate 2023/08/13
  case (TeamValue) of
    11: Result := True;
    12: Result := True;
    17: Result := True;
    else
      Result := False;
  end;

end;

end.
