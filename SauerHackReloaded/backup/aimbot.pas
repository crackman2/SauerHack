unit Aimbot;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows,gl,math,
  CPlayer;

type
   MVPmatrix = array[0..15] of single;
   RVec4 = record
    x:single;
    y:single;
    z:single;
    w:single;
  end;
  RVec3 = record
    x:single;
    y:single;
    z:single;
  end;
  RVec2 = record
    x:single;
    y:single;
  end;
  TEnArr = array[1..32] of TPlayer;
  PTEnArr = ^TEnArr;

  { TAimbot }

  TAimbot = class
    ply:PTPlayer;
    en:PTEnArr;
    Constructor Create(plr:PTPlayer; ens:PTEnArr);
    function glW2S( plypos: RVec3): Boolean; stdcall;
    function IsTeamBased():Boolean;stdcall;
    function GetBestTarget(plrcnt:Cardinal):Integer;stdcall;
    procedure Aim(index:Integer);stdcall;
    procedure AutoTrigger();stdcall;
    public
    scrcord: RVec2;
    ShootByte:PByte;
  end;




implementation

{ TAimbot }


{ ---------- Aimbot Constructor ---------- }
{ -> Assings pointers to the localplayer   }
{    and enemy array                       }
{ -> assings pointer to a value used to    }
{    automatically fire (ShootByte)        }
constructor TAimbot.Create(plr: PTPlayer; ens: PTEnArr);
var
  ShootByteBase:Pointer;
begin
  ply:=plr;
  en:=ens;
  ShootByteBase:= Pointer(GetModuleHandle('sauerbraten.exe') + $216454);
  ShootByteBase:= Pointer(Cardinal(ShootByteBase^) + $1E0);
  ShootByte:=PByte(ShootByteBase);
end;



{ ---------- World to Screen ---------- }
{ -> Projects 3D World Point onto 2D    }
{    screen                             }
{ -> Used here for target selection     }
function TAimbot.glW2S( plypos: RVec3): Boolean; stdcall;
var
  Clip: RVec4;
  NDC: RVec3;
  viewp: array[0..3] of GLint;
  depthr: array[0..1] of GLfloat;
  i:Cardinal;
  VMBase:Cardinal;
  ViewMatrx: MVPmatrix;
begin

  VMBase:=GetModuleHandle('sauerbraten.exe') + $297AF0;
  for i:=0 to 15 do
  begin
    ViewMatrx[i]:=PSingle(VMBase + i*4)^;
  end;

  Clip.x := plypos.x * ViewMatrx[0] + plypos.y * ViewMatrx[4] + plypos.z *
    ViewMatrx[8] + ViewMatrx[12];
  Clip.y := plypos.x * ViewMatrx[1] + plypos.y * ViewMatrx[5] + plypos.z *
    ViewMatrx[9] + ViewMatrx[13];
  Clip.z := plypos.x * ViewMatrx[2] + plypos.y * ViewMatrx[6] + plypos.z *
    ViewMatrx[10] + ViewMatrx[14];
  Clip.w := plypos.x * ViewMatrx[3] + plypos.y * ViewMatrx[7] + plypos.z *
    ViewMatrx[11] + ViewMatrx[15];

  if Clip.w < 0.1 then
     Result:=False
  else
  begin
  NDC.x := Clip.x / Clip.w;
  NDC.y := Clip.y / Clip.w;
  NDC.z := Clip.z / Clip.w;

  glGetIntegerv(GL_VIEWPORT, viewp);
  glGetFloatv(GL_DEPTH_RANGE, depthr);

  scrcord.x := (viewp[2] / 2 * NDC.x) + (NDC.x + viewp[2] / 2);
  scrcord.y := (viewp[3] / 2 * NDC.y) + (NDC.x + viewp[3] / 2);
  scrcord.y := viewp[3] - scrcord.y;

  Result:=True;
  end;
end;



{ ---------- Check for GameMode ---------- }
{ -> Determines if current game mode is    }
{    team based                            }
function TAimbot.IsTeamBased(): Boolean; stdcall;
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

{ -------------------- Get Best Target -------------------- }
{ -> projects each valid entities location onto the screen  }
{    to determine which one is closest to the crosshair     }
{ -> other criteria are:                                    }
{          - targets team (if game mode is team based)      }
{          - health                                         }
{          - is target spectating                           }
{ -> the best target is not in your team, alive, not        }
{    spectating and closed to your crosshair                }
function TAimbot.GetBestTarget(plrcnt:Cardinal): Integer; stdcall;
var
  dist:Single;
  distmin:Single=999999;
  BestTarget:Integer=-1;
  i:Cardinal;
  TargetPos:RVec3;
  viewp:array[0..3] of GLint;
begin
  glGetIntegerv(GL_VIEWPORT, viewp);
  i:=1;
  while i <= plrcnt do
  begin
    if (en^[i].IsSpectating = False) and (en^[i].hp > 0) then
    begin
      if (en^[i].TeamString[0] <> ply^.TeamString[0]) or (not IsTeamBased()) then
      begin
        TargetPos.x:=en^[i].pos.x;
        TargetPos.y:=en^[i].pos.y;
        TargetPos.z:=en^[i].pos.z;
        if glW2S(TargetPos) then
        begin
          dist:=sqrt(
                     (scrcord.x - (viewp[2]/2))*(scrcord.x - (viewp[2]/2)) +
                     (scrcord.y - (viewp[3]/2))*(scrcord.y - (viewp[3]/2))
          );

          if dist < distmin then
          begin
            distmin:=dist;
            BestTarget:=i;
          end;
        end;
      end;
    end;
    inc(i);
  end;
  if (GetAsyncKeyState(VK_Q) <> 0) and (BestTarget <> -1) then
  MessageBox(0,PChar('BestTarget final: ' + inttostr(BestTarget) + LineEnding +
                     'Position : ' + FloatToStr(en^[BestTarget].pos.x) + LineEnding + FloatToStr(en^[BestTarget].pos.y) + LineEnding + FloatToStr(en^[BestTarget].pos.z) + LineEnding +
                     'Distance : ' + FloatToStr(distmin)
  ),'e',0);
  Result:=BestTarget;
end;


{ --------------------- Aim Function ---------------------- }
{ -> uses trigenometry to aim at target                     }
{ -> the index determines which enemy to aim at             }
procedure TAimbot.Aim(index: Integer); stdcall;
var
  dx:single;
  dy:single;
  dz:single;
  dist:single;
begin
  if index > 0 then
  begin
    dx:=en^[index].pos.x - ply^.pos.x;
    dy:=en^[index].pos.y - ply^.pos.y;
    dz:=(en^[index].pos.z-3.0) - ply^.pos.z;

    dist:= sqrt(
           (dx*dx) +
           (dy*dy)
    );

    ply^.SetCamera((arctan2(dy,dx)*57.2958)-90.0, arctan2(dz,dist) * 57.2958);
  end;
end;
{ -------------------- AutoTrigger / Triggerbot -------------------- }
{ -> Checks PixelColor in the center of the screen. if it is equal   }
{    RGB($00,$FF,$02) it triggers using the ShootByte                }
procedure TAimbot.AutoTrigger(); stdcall;
var
  pixel:array[0..3] of BYTE;
  viewp:array[0..3] of GLint;
begin
  glGetIntegerv(GL_VIEWPORT, viewp);
  glReadPixels(round(viewp[2]/2),round(viewp[3]/2),1,1,GL_RGB,GL_UNSIGNED_BYTE,@pixel[0]);

  if (pixel[0] = $0) and (pixel[1] = $FF) and (pixel[2] = $02) then
  begin
    ShootByte^:=$1;
  end;
end;

end.

