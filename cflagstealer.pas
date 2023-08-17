unit CFlagStealer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, windows,

  CPlayer, CustomTypes, GlobalVars, GlobalOffsets;


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
  Original:Pointer;
begin
  FlipFlop:=PByte(g_cave + $700);

  Original:=Pointer(g_offset_SauerbratenBase + $29D200);
  BlueFlagPointer:=Pointer(Original^) + $88;

  Original:=Pointer(g_offset_SauerbratenBase + $29D200);
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
  TeamValue := PBYTE(g_offset_SauerbratenBase + g_offset_TeamValue)^; //uptodate 2023/08/13
  case (TeamValue) of
    11: Result := True;
    12: Result := True;
    17: Result := True;
    else
      Result := False;
  end;

end;

end.

