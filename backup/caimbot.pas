unit CAimbot;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, gl, Math,
  CPlayer, GlobalVars, CustomTypes, GlobalOffsets;

type
  TEnArr = array[1..32] of TPlayer;
  PTEnArr = ^TEnArr;

  { TAimbot }

  TAimbot = class

    constructor Create(ply: TPlayer);
    procedure Poll;
    procedure SetEnemyArray(en: TEnArr);
    procedure SetPlayerCount(plrcnt: cardinal);
    function glW2S(plypos: RVec3): boolean; stdcall;
    function IsTeamBased(): boolean; stdcall;
    function GetBestTarget(plrcnt: cardinal): integer; stdcall;
    procedure Aim(index: integer); stdcall;
    procedure AutoTrigger(); stdcall;

  public
    scrcord: RVec2;
    ShootByte: PByte;
    Fog: Pointer;
    ply: TPlayer;
    en: TEnArr;

    plrcnt:Cardinal;

    CurrentBestTarget: integer;

    bLockAim:Boolean;
    bReleasedRBM:Boolean;

    FrameShotReturner:Boolean;
    FrameShotSavedCameraAngles:RVec2;

  end;




implementation

{ TAimbot }


{ --------------------------- Aimbot Constructor --------------------------- }
{ -> Assings pointers to the localplayer and enemy array                     }
{ -> assings pointer to a value used to automatically fire (ShootByte)       }
constructor TAimbot.Create(ply: TPlayer);
var
  ShootByteBase: Pointer;
begin
  Self.ply := ply;

  ShootByteBase := Pointer(g_offset_SauerbratenBase + g_offset_ShootByte_0);    //uptodate 2023/08/13
  ShootByteBase := Pointer(cardinal(ShootByteBase^) + g_offset_ShootByte_1); //uptodate 2023/08/13
  ShootByte := PByte(ShootByteBase);
  Fog := Pointer(g_offset_SauerbratenBase + g_offset_Fog);
end;

{ ---------------------------------- Poll ---------------------------------- }
{ -> is executed every frame by MainFunc                                     }
{ -> checks menu settings g_EnableAimbot and g_EnableLockAim and             }
{    g_EnableTriggerbot                                                      }
{ -> Triggers functions to select targets, aim and triggger                  }
{ -> includes a mechanism to prevent spamming                                }
procedure TAimbot.Poll;
begin

  if FrameShotReturner then begin
     Self.ply.SetCamera(FrameShotSavedCameraAngles.x,FrameShotSavedCameraAngles.y);
     FrameShotReturner:=False;
  end;

  Self.ShootByte^ := 0;
  if (g_EnableAimbot = 1) and (g_EnableLockAim = 1) then
  begin
    if not (GetAsyncKeyState($1) <> 0) then
      Self.ShootByte^ := $0;
    if (GetAsyncKeyState($2) <> 0) then
    begin
      if Self.bReleasedRBM then
      begin
        Self.bLockAim:=True;
        Self.CurrentBestTarget := Self.GetBestTarget(Self.plrcnt);
        Self.bReleasedRBM:=False;
      end;
    end
    else
    begin
      Self.bReleasedRBM:=True;
    end;

    if (Self.bLockAim) and (not Self.bReleasedRBM) then
    begin
      if en[Self.CurrentBestTarget] <> nil then
      begin
        if en[Self.CurrentBestTarget].hp <= 0 then
        begin
          Self.bLockAim:=False;
        end
        else
        begin
          if GetAsyncKeyState(VK_O) <> 0 then
          begin
            //Debug Output. Show current targets pointer
            // MessageBox(0, PChar('Current Target: 0x' +
            //   IntToHex(DWORD(Enemy[CurrentBestTarget].PlayerBase), 8)), 'e', 0);
          end;
          if g_EnableFrameShot = 1 then begin
             Self.bLockAim:=False;
             FrameShotSavedCameraAngles:=Self.ply.cam;
             FrameShotReturner:=True;
          end;
          Self.Aim(Self.CurrentBestTarget);
          Self.AutoTrigger();

        end;
      end
      else
      begin
        Self.bLockAim:=False;
      end;
    end
    else
    begin
      Self.bLockAim:=False;
    end;
  end;

  if (g_EnableAimbot = 1) and (g_EnableLockAim = 0) then
  begin
    if not (GetAsyncKeyState($1) <> 0) then
      Self.ShootByte^ := $0;
    if (GetAsyncKeyState($2) <> 0) then
    begin
      Self.Aim(Self.GetBestTarget(Self.plrcnt));
      if (g_EnableTriggerbot = 1) then
        Self.AutoTrigger();
    end;
  end;


  if (g_EnableTriggerbot = 1) and (GetAsyncKeyState($2) <> 0) then
    Self.AutoTrigger();
end;

{ ------------------------------ SetEnemyArray ----------------------------- }
{ -> en must be set before anything can be done, really                      }
{ -> the enemy array is created in MainFunc                                  }
procedure TAimbot.SetEnemyArray(en: TEnArr);
begin
  Self.en:=en;
end;

{ ------------------------------ SetPlayerCount ----------------------------- }
{ -> plrcnt must be set before anything can be done, really                   }
{ -> the playercount is found during the main loop                            }
procedure TAimbot.SetPlayerCount(plrcnt: cardinal);
begin
  Self.plrcnt := plrcnt;
end;

{ ----------------------------- World to Screen ---------------------------- }
{ -> Projects 3D World Point onto 2D screen                                  }
{ -> Used here for target selection                                          }
function TAimbot.glW2S(plypos: RVec3): boolean; stdcall;
var
  Clip: RVec4;
  NDC: RVec3;
  viewp: array[0..3] of GLint = (0,0,0,0);
  depthr: array[0..1] of GLfloat = (0,0);
  i: cardinal;
  VMBase: cardinal;
  ViewMatrx: MVPmatrix;
begin

  VMBase := g_offset_SauerbratenBase + g_offset_ViewMatrix; //uptodate 2023/08/13
  for i := 0 to 15 do
  begin
    ViewMatrx[i] := PSingle(VMBase + i * 4)^;
  end;

  Clip.x := plypos.x * ViewMatrx[0] + plypos.y * ViewMatrx[4] +
    plypos.z * ViewMatrx[8] + ViewMatrx[12];
  Clip.y := plypos.x * ViewMatrx[1] + plypos.y * ViewMatrx[5] +
    plypos.z * ViewMatrx[9] + ViewMatrx[13];
  Clip.z := plypos.x * ViewMatrx[2] + plypos.y * ViewMatrx[6] +
    plypos.z * ViewMatrx[10] + ViewMatrx[14];
  Clip.w := plypos.x * ViewMatrx[3] + plypos.y * ViewMatrx[7] +
    plypos.z * ViewMatrx[11] + ViewMatrx[15];

  if Clip.w < 0.1 then
    Result := False
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

    Result := True;
  end;
end;



{ --------------------------- Check for GameMode --------------------------- }
{ -> Determines if current game mode is team based                           }
function TAimbot.IsTeamBased(): boolean; stdcall;
var
  TeamValue: byte;
begin
  TeamValue := PBYTE(g_offset_SauerbratenBase + g_offset_TeamValue)^; //uptodate 2023/08/13
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

{ ----------------------------- Get Best Target ---------------------------- }
{ -> projects each valid entities location onto the screen to determine      }
{    which one is closest to the crosshair                                   }
{ -> other criteria are:                                                     }
{          - targets team (if game mode is team based)                       }
{          - health                                                          }
{          - is target spectating                                            }
{ -> the best target is not in your team, alive, not spectating and closed   }
{    to your crosshair                                                       }
function TAimbot.GetBestTarget(plrcnt: cardinal): integer; stdcall;
var
  dist: single;
  distmin: single = 999999;
  BestTarget: integer = -1;
  i: cardinal;
  TargetPos: RVec3;
  viewp: array[0..3] of GLint = (0,0,0,0);
begin
  glGetIntegerv(GL_VIEWPORT, viewp);
  i := 1;
  while i <= plrcnt do
  begin
    if (en[i].IsSpectating = False) and (en[i].hp > 0) then
    begin
      if (en[i].TeamString[0] <> ply.TeamString[0]) or (not IsTeamBased()) then
      begin
        TargetPos.x := en[i].pos.x;
        TargetPos.y := en[i].pos.y;
        TargetPos.z := en[i].pos.z;
        if glW2S(TargetPos) then
        begin
          dist := sqrt((scrcord.x - (viewp[2] / 2)) *
                       (scrcord.x - (viewp[2] / 2)) +
                       (scrcord.y - (viewp[3] / 2)) *
                       (scrcord.y - (viewp[3] / 2)));

          if dist < distmin then
          begin
            distmin := dist;
            BestTarget := i;
          end;
        end;
      end;
    end;
    Inc(i);
  end;
  Result := BestTarget;
end;


{ ------------------------------ Aim Function ------------------------------ }
{ -> uses trigenometry to aim at target                                      }
{ -> the index determines which enemy to aim at                              }
procedure TAimbot.Aim(index: integer); stdcall;
var
  dx: single;
  dy: single;
  dz: single;
  dist: single;
begin
  if index > 0 then
  begin
    dx := en[index].pos.x - ply.pos.x;
    dy := en[index].pos.y - ply.pos.y;
    dz := (en[index].pos.z - 1.5) - ply.pos.z;

    dist := sqrt((dx * dx) + (dy * dy));

    ply.SetCamera((arctan2(dy, dx) * 57.2958) - 90.0, arctan2(dz, dist) * 57.2958);
  end;
end;

{ ------------------------ AutoTrigger / Triggerbot ------------------------ }
{ -> Checks PixelColor in the center of the screen. if it is equal           }
{    RGB($00,$FF,$00) ($0A tolerance) it triggers using the ShootByte        }
{ -> change enemy textures to be entirely green ($00FF00), ingame they       }
{    should show up as $00FF02 of some reason. make sure to disable any      }
{    shading, postprocessing or anything else that shades the models. they   }
{    have to be fullbright. also disable ragdolling and dead player  models  }
{    in general to avoid misfiring                                           }
procedure TAimbot.AutoTrigger(); stdcall;
var
  pixel: array[0..3] of byte;
  viewp: array[0..3] of GLint = (0,0,0,0);
begin
  glGetIntegerv(GL_VIEWPORT, viewp);
  glReadPixels(round(viewp[2] / 2), round(viewp[3] / 2), 1, 1, GL_RGB,
    GL_UNSIGNED_BYTE, @pixel[0]);

  PCardinal(Fog)^ := 1000024;
  if (pixel[0] = $0) and (pixel[1] = $FF) and ((pixel[2] < $0A)) then
  begin
    ShootByte^ := $1;
  end;
end;

end.
