unit CESP;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, gl, glu, Windows,
  CPlayer, DrawText, CustomTypes, GlobalOffsets;

type


  { TESP }
  TEnArr = array[1..32] of TPlayer;
  PTEnArr = ^TEnArr;

  TESP = class
    constructor Create(ply: TPlayer);
    procedure SetEnemyArray(en: TEnArr);
    procedure SetPlayerCount(plrcnt: cardinal);
    procedure DrawLine(StartX: single; StartY: single; EndX: single;
      EndY: single; LineTickness: single); stdcall;
    procedure DrawBox(top: single; left: single; bottom: single;
      right: single; LineThickness: single); stdcall;
    function glW2S(plypos: RVec3): boolean; stdcall;
    procedure DrawESP(); stdcall;
    function IsTeamBased(): boolean; stdcall;
    procedure Draw3DBox(Index: cardinal; lw: single); stdcall;
    procedure Draw3DCamXArrow(Index: cardinal; lw: single); stdcall;
    function GetDirectionVector(Origin:RVec3; CameraAngles:RVec2; Length:Single): RVec3;
    function MaxSingle(a:Single; b: Single): Single;



  public
    ply: TPlayer;
    en: TEnArr;
    plrcnt: cardinal;
    scrcord: RVec2;
  end;

implementation

{ TESP }


{ -------------------- TESP Constructor -------------------- }
{ -> assings pointers to the localplayer and the enemy array }
{ -> assings playercount to internal variable                }
constructor TESP.Create(ply: TPlayer);
begin
  Self.ply := ply;
end;

{ ------------------------------ SetEnemyArray ----------------------------- }
{ -> en must be set before anything can be done, really                      }
{ -> the enemy array is created in MainFunc                                  }
procedure TESP.SetEnemyArray(en: TEnArr);
begin
  Self.en := en;
end;

{ ------------------------------ SetPlayerCount ----------------------------- }
{ -> plrcnt must be set before anything can be done, really                   }
{ -> the playercount is found during the main loop                            }
procedure TESP.SetPlayerCount(plrcnt: cardinal);
begin
  Self.plrcnt := plrcnt;
end;

procedure TESP.DrawLine(StartX: single; StartY: single; EndX: single;
  EndY: single; LineTickness: single);
  stdcall;
begin
  glLineWidth(LineTickness);
  glBegin(GL_LINES);
  glVertex2f(StartX, StartY);
  glVertex2f(EndX, EndY);
  glEnd();
end;

procedure TESP.DrawBox(top: single; left: single; bottom: single;
  right: single; LineThickness: single); stdcall;
begin
  DrawLine(left, top, right, top, LineThickness); //upper border
  DrawLine(left, top, left, bottom, LineThickness); //left border
  DrawLine(left, bottom, right, bottom, LineThickness); //bottom
  DrawLine(right, top, right, bottom, LineThickness);//right
end;


{ -------------------- DrawESP -------------------- }
{ -> Uses the same target selection as the aimbot   }
{    to determine who needs a box drawn around him  }
procedure TESP.DrawESP(); stdcall;
var
  i: cardinal;
  PosToCheck: RVec3;
  pHead: RVec2;
  pFeet: RVec2;
  dHeight: single;
  //dWidth:Single; //2d box
begin
  i := 1;
  //glxDrawString(40, 300, ansistring('Entering while loop of DrawESP'), 2, True);
  //glxDrawString(40, 312, ansistring('Playercount: ') + IntToStr(plrcnt), 2, True);

  while i <= plrcnt do
  begin
    glColor3d(1, 1, 0.0);
    //glxDrawString(10, 336 + i*12, ansistring('Index : ') + IntToStr(i), 2, True);
    if Assigned(en[i]) and Assigned(ply) then
    begin
      //glxDrawString(140, 336 + i*12, ansistring('IsSpectator'), 2, True);
      if (en[i].IsSpectating = False) and (en[i].hp > 0) then
      begin
        //glxDrawString(270, 336 + i*12, ansistring('IsTeammate'), 2, True);
        if (en[i].TeamString[0] <> ply.TeamString[0]) or (not IsTeamBased()) then
        begin
          PosToCheck.x := en[i].pos.x;
          PosToCheck.y := en[i].pos.y;
          PosToCheck.z := en[i].pos.z + 3.5;
          glColor3f(0, 1, 1);
          //glxDrawString(390,336 + i*12,AnsiString('Entity -' + IntToStr(i) + '- Pos Z: ' + IntToStr(round(PosToCheck.z))),2,True);
          if (glW2S(PosToCheck)) then
          begin
            pHead.x := scrcord.x;
            pHead.y := scrcord.y;

            PosToCheck.x := en[i].pos.x;
            PosToCheck.y := en[i].pos.y;
            PosToCheck.z := en[i].pos.z - 15;
            glW2S(PosToCheck);
            pFeet.x := scrcord.x;
            pFeet.y := scrcord.y;

            dHeight := pHead.y - pFeet.y;
            //dWidth:=dHeight/2;//2d box

            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glEnable(GL_LINE_SMOOTH);
            glColor3f(1, 0, 0);
            //DrawBox(pHead.y,pHead.x - (dWidth/2),pFeet.y, pHead.x + (dWidth/2)  ,abs(dHeight/80));//2d box
            Draw3DBox(i, abs(dHeight / 80)); //3d box
            Draw3DCamXArrow(i, abs(dHeight / 80));
            //glColor3f(0,2,0);//2d box


            //DrawLine(pHead.x - (dWidth/2) + 4,pFeet.y, pHead.x - (dWidth/2) + 4, pHead.y - (((1.0 - (en^[i].hp / 100.0))*dheight)),abs(dHeight/80));//2d box


            glColor3f(0.8, 0.8, 0.8);

            glxDrawString(pHead.x, pHead.y + (dHeight / 4), PChar(en[i].PlayerNameString), MaxSingl(abs(dHeight / 80) ,2), False);
            glDisable(GL_BLEND);
            glDisable(GL_LINE_SMOOTH);
          end;
        end;
      end
      else
      begin
        // glColor3f(1.0,0.0,0.0);
        // glxDrawString(270, 336 + i*12, ansistring('HP: ' + IntToStr(round(en[i].hp))), 2, True);
        // glxDrawString(350, 336 + i*12, ansistring('SPEC: ' + IntToStr(Cardinal(en[i].IsSpectating))), 2, True);
        // glColor3f(0.0,1.0,0.0);
      end;
    end
    else
    begin
      //glColor3f(1.0,0.0,0.0);
      //glxDrawString(400, 500 + i * 6, ansistring('Enemy is nill. Index: ' + IntToStr(i)), 1, True);
    end;
    Inc(i);
  end;
end;


procedure TESP.Draw3DBox(Index: cardinal; lw: single); stdcall;
var
  { --- 3D Vars --- }
  Head3D: RVec3;
  HNE: RVec3;
  HNW: RVec3;
  HSW: RVec3;
  HSE: RVec3;

  Feet3D: RVec3;
  FNE: RVec3;
  FNW: RVec3;
  FSW: RVec3;
  FSE: RVec3;

  { --- 3D HP Vector --- }
  HealthBar: RVec3;

  { --- 2D Vars --- }
  sHNE: RVec2;
  sHNW: RVec2;
  sHSW: RVec2;
  sHSE: RVec2;

  sFNE: RVec2;
  sFNW: RVec2;
  sFSW: RVec2;
  sFSE: RVec2;

  { --- 2D HP Vector --- }
  sHealthBar: RVec2;

  { ----- Box Width ---- }
  bw: single = 3.75;

  bFailed: boolean = False;
begin
  { ------ Zeroing ----- }
  Head3D := RVec3_Create(0, 0, 0);
  HNE := RVec3_Create(0, 0, 0);
  HNW := RVec3_Create(0, 0, 0);
  HSW := RVec3_Create(0, 0, 0);
  HSE := RVec3_Create(0, 0, 0);

  Feet3D:= RVec3_Create(0, 0, 0);
  FNE:= RVec3_Create(0, 0, 0);
  FNW:= RVec3_Create(0, 0, 0);
  FSW:= RVec3_Create(0, 0, 0);
  FSE:= RVec3_Create(0, 0, 0);

  HealthBar:= RVec3_Create(0, 0, 0);

  sHNE:=RVec2_Create(0,0);
  sHNW:=RVec2_Create(0,0);
  sHSW:=RVec2_Create(0,0);
  sHSE:=RVec2_Create(0,0);

  sFNE:=RVec2_Create(0,0);
  sFNW:=RVec2_Create(0,0);
  sFSW:=RVec2_Create(0,0);
  sFSE:=RVec2_Create(0,0);

  sHealthBar:=RVec2_Create(0,0);

  { --- Actual Beginning --- }

  Head3D := en[Index].pos;
  Feet3D := en[Index].pos;
  Feet3D.z -= 15;
  Head3D.z += 2;
  HealthBar := Head3D;
  HealthBar.z := Head3D.z - (((1.0 - (en[Index].hp / 100.0)) * (Head3D.z - Feet3D.z)));

  { --- Head Vertices --- }
  HNE := Head3D;
  HNE.x += bw;
  HNE.y += bw;

  HNW := Head3D;
  HNW.x -= bw;
  HNW.y += bw;

  HSW := Head3D;
  HSW.x -= bw;
  HSW.y -= bw;

  HSE := Head3D;
  HSE.x += bw;
  HSE.y -= bw;

  { --- Feet Vertices --- }
  FNE := Feet3D;
  FNE.x += bw;
  FNE.y += bw;

  FNW := Feet3D;
  FNW.x -= bw;
  FNW.y += bw;

  FSW := Feet3D;
  FSW.x -= bw;
  FSW.y -= bw;

  FSE := Feet3D;
  FSE.x += bw;
  FSE.y -= bw;

  { --- Health Vertex --- }
  HealthBar.x -= bw;
  HealthBar.y += bw;



  { --- Projecting --- }
  { -> Head            }
  if not glW2S(HNE) then
    bFailed := True
  else
    sHNE := scrcord;
  if not glW2S(HNW) then
    bFailed := True
  else
    sHNW := scrcord;
  if not glW2S(HSW) then
    bFailed := True
  else
    sHSW := scrcord;
  if not glW2S(HSE) then
    bFailed := True
  else
    sHSE := scrcord;

  { -> Feet }
  if not glW2S(FNE) then
    bFailed := True
  else
    sFNE := scrcord;
  if not glW2S(FNW) then
    bFailed := True
  else
    sFNW := scrcord;
  if not glW2S(FSW) then
    bFailed := True
  else
    sFSW := scrcord;
  if not glW2S(FSE) then
    bFailed := True
  else
    sFSE := scrcord;

  { -> HealthBar }
  if not glW2S(HealthBar) then
    bFailed := True
  else
    sHealthBar := scrcord;

  { --- Drawing --- }
  if not bFailed then
  begin
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_LINE_SMOOTH);
    glColor3f(1, 0, 0);
    { -> Head         }
    DrawLine(sHNE.x, sHNE.y, sHNW.x, sHNW.y, lw); //North Line
    DrawLine(sHNE.x, sHNE.y, sHSE.x, sHSE.y, lw); //East Line
    DrawLine(sHSW.x, sHSW.y, sHSE.x, sHSE.y, lw); //South Line
    DrawLine(sHSW.x, sHSW.y, sHNW.x, sHNW.y, lw); //West Line

    { -> Feet         }
    DrawLine(sFNE.x, sFNE.y, sFNW.x, sFNW.y, lw); //North Line
    DrawLine(sFNE.x, sFNE.y, sFSE.x, sFSE.y, lw); //East Line
    DrawLine(sFSW.x, sFSW.y, sFSE.x, sFSE.y, lw); //South Line
    DrawLine(sFSW.x, sFSW.y, sFNW.x, sFNW.y, lw); //West Line

    { -> Vetical      }
    DrawLine(sHNE.x, sHNE.y, sFNE.x, sFNE.y, lw); //North East Line
    DrawLine(sHSE.x, sHSE.y, sFSE.x, sFSE.y, lw); //South East Line
    DrawLine(sHSW.x, sHSW.y, sFSW.x, sFSW.y, lw); //South West Line
    DrawLine(sHNW.x, sHNW.y, sFNW.x, sFNW.y, lw); //North West Line
    glColor3f(0, 0.8, 0);
    DrawLine(sHealthBar.x, sHealthBar.y, sFNW.x, sFNW.y, lw * 2); //HealthBar
  end;
end;




function TESP.glW2S(plypos: RVec3): boolean; stdcall;
var
  Clip: RVec4;
  NDC: RVec3;
  viewp: array[0..3] of GLint = (0,0,0,0);
  depthr: array[0..1] of GLfloat = (0,0);
  i: cardinal;
  VMBase: cardinal;
  ViewMatrx: MVPmatrix;
begin

  VMBase := g_offset_SauerbratenBase + g_offset_ViewMatrix;

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



function TESP.IsTeamBased(): boolean; stdcall;
var
  TeamValue: byte;
begin
  TeamValue := PBYTE(g_offset_SauerbratenBase + g_offset_TeamValue)^;
  //uptodate 2023/08/13
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

procedure TESP.Draw3DCamXArrow(Index: cardinal; lw: single); stdcall;
var
  { ------------------------------ 3D Elements ----------------------------- }
  ArrowBase: RVec3;
  ArrowTip: RVec3;
  ArrowBlade: array [0..1] of RVec3;


  { ---------------------------- 2D Projections ---------------------------- }
  sArrowBase: RVec2;
  sArrowTip: RVec2;
  sArrowBlade: array [0..1] of RVec2;


  { ------------------------------- Settings ------------------------------- }
  Length: single = 10;
  BladeAngle:RVec2;
  BladeDistFrombase:Single = 8;

  { ------------------------------ Error Check ----------------------------- }
  bFailed: boolean = False;

  { --------------------------------- Misc --------------------------------- }
  //i:Cardinal=0;
begin
  { -------------------------------- Zeroing ------------------------------- }
  ArrowBase:=RVec3_Create(0,0,0);
  ArrowTip:=RVec3_Create(0,0,0);
  ArrowBlade[0]:=RVec3_Create(0,0,0);
  ArrowBlade[1]:=RVec3_Create(0,0,0);

  sArrowBase:=RVec2_Create(0,0);
  sArrowTip:=RVec2_Create(0,0);
  sArrowBlade[0]:=RVec2_Create(0,0);
  sArrowBlade[1]:=RVec2_Create(0,0);



  { ----------------------------- Basic Values ----------------------------- }
  ArrowBase := en[Index].pos;
  ArrowTip := ArrowBase;


  { --------------------------- Main Arrow Vector -------------------------- }
  ArrowTip:=GetDirectionVector(ArrowBase, en[Index].cam, Length);


  { ------------------------- Arrow Blade Vectors -------------------------- }
  BladeAngle:=en[Index].cam;
  ArrowBlade[0]:=GetDirectionVector(ArrowBase,BladeAngle,BladeDistFrombase);
  ArrowBlade[1]:=GetDirectionVector(ArrowBase,BladeAngle,BladeDistFrombase);

  ArrowBlade[0].z+=3;
  ArrowBlade[1].z-=3;



  if not glW2S(ArrowBase) then
    bFailed := True
  else
    sArrowBase := scrcord;

  if not glW2S(ArrowTip) then
    bFailed := True
  else
    sArrowTip := scrcord;

  if not glW2S(ArrowBlade[0]) then
    bFailed:=True
  else
    sArrowBlade[0]:=scrcord;

  if not glW2S(ArrowBlade[1]) then
    bFailed:=True
  else
    sArrowBlade[1]:=scrcord;


  if not bFailed then
  begin
    glColor3f(0.8, 1, 1);
    DrawLine(sArrowBase.x, sArrowBase.y, sArrowTip.x, sArrowTip.y, lw);
    DrawLine(sArrowTip.x, sArrowTip.y,sArrowBlade[0].x,sArrowBlade[0].y,lw * 2);
    DrawLine(sArrowTip.x, sArrowTip.y,sArrowBlade[1].x,sArrowBlade[1].y,lw * 2);
  end;
end;


{ --------------------------- GetDirectionVector --------------------------- }
{ -> Returns a RVec3 that is "Length" units away from the Origin in the      }
{    direction the angles were pointing                                      }
{ -> functions like this should get their own unit, something like this is   }
{    also used in CNoclip                                                    }
function TESP.GetDirectionVector(Origin:RVec3; CameraAngles:RVec2; Length:Single): RVec3;
begin
  Result:=Origin;
  Result.x += cos((CameraAngles.x + 90) / 57.2958) * Length * (1.57079576 - (abs((CameraAngles.y / 57.2958))));
  Result.y += sin((CameraAngles.x + 90) / 57.2958) * Length * (1.57079576 - (abs((CameraAngles.y / 57.2958))));
  Result.z += sin((CameraAngles.y / 57.2958));
end;


function TESP.MaxSingle(a:Single; b: Single): Single;
begin
  if a > b then
    Result := a
  else
    Result := b;
end;



end.
