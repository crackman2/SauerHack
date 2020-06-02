unit CESP;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, gl, glu,windows,

  CPlayer, DrawText, CustomTypes;

type


  { TESP }
  TEnArr = array[1..32] of TPlayer;
  PTEnArr = ^TEnArr;

  TESP = class
    Constructor Create(plr:PTPlayer;enr:PTEnArr; PlrCounter:Cardinal);
    procedure DrawLine(StartX: Single; StartY: Single; EndX: Single; EndY: Single; LineTickness:Single);stdcall;
    procedure DrawBox(top:single; left:single; bottom:single; right:single; LineThickness:Single);stdcall;
    function glW2S( plypos: RVec3): Boolean; stdcall;
    procedure DrawESP();stdcall;
    function IsTeamBased(): Boolean; stdcall;
    procedure Draw3DBox(Index:Cardinal; lw:Single);stdcall;

    public
      ply:PTPlayer;
      en:PTEnArr;
      plrcnt:Cardinal;
      scrcord:RVec2;
  end;

implementation

{ TESP }


{ -------------------- TESP Constructor -------------------- }
{ -> assings pointers to the localplayer and the enemy array }
{ -> assings playercount to internal variable                }
constructor TESP.Create(plr: PTPlayer; enr: PTEnArr; PlrCounter:Cardinal);
begin
  ply:=plr;
  en:=enr;
  plrcnt:=PlrCounter;
end;


procedure TESP.DrawLine(StartX: Single; StartY: Single; EndX: Single; EndY: Single; LineTickness:Single);
  stdcall;
begin
  glLineWidth(LineTickness);
  glBegin(GL_LINES);
  glVertex2f(StartX,StartY);
  glVertex2f(EndX,EndY);
  glEnd();
end;

procedure TESP.DrawBox(top:single; left:single; bottom:single; right:single; LineThickness:Single);stdcall;
begin
  DrawLine(left,top,right,top,LineThickness); //upper border
  DrawLine(left,top,left,bottom,LineThickness); //left border
  DrawLine(left,bottom,right,bottom,LineThickness); //bottom
  DrawLine(right,top,right,bottom,LineThickness);//right
end;


{ -------------------- DrawESP -------------------- }
{ -> Uses the same target selection as the aimbot   }
{    to determine who needs a box drawn around him  }
procedure TESP.DrawESP(); stdcall;
var
  i:Cardinal;
  PosToCheck:RVec3;
  pHead:RVec2;
  pFeet:RVec2;
  dHeight:Single;
  dWidth:Single;
begin
  i:=1;
  while i <= plrcnt do
  begin
    if (en^[i].IsSpectating = False) and (en^[i].hp > 0) then
    begin
      if (en^[i].TeamString[0] <> ply^.TeamString[0]) or (not IsTeamBased()) then
      begin
           PosToCheck.x:=en^[i].pos.x;
           PosToCheck.y:=en^[i].pos.y;
           PosToCheck.z:=en^[i].pos.z+3.5;
           if(glW2S(PosToCheck)) then
           begin
             pHead.x:=scrcord.x;
             pHead.y:=scrcord.y;


             PosToCheck.x:=en^[i].pos.x;
             PosToCheck.y:=en^[i].pos.y;
             PosToCheck.z:=en^[i].pos.z-18;
             glW2S(PosToCheck);
             pFeet.x:=scrcord.x;
             pFeet.y:=scrcord.y;

             dHeight:=pHead.y-pFeet.y;
             dWidth:=dHeight/2;

             glEnable(GL_BLEND);
             glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
             glEnable(GL_LINE_SMOOTH);
             glColor3f(1,0,0);
             //DrawBox(pHead.y,pHead.x - (dWidth/2),pFeet.y, pHead.x + (dWidth/2)  ,abs(dHeight/80));
             Draw3DBox(i,abs(dHeight/80));
             glColor3f(0,2,0);


             DrawLine(pHead.x - (dWidth/2) + 4,pFeet.y, pHead.x - (dWidth/2) + 4, pHead.y - (((1.0 - (en^[i].hp / 100.0))*dheight)),abs(dHeight/80));


             glColor3f(0.8,0.8,0.8);

             glxDrawString(pHead.x,pHead.y+(dHeight/4),PChar(en^[i].PlayerNameString),abs(dHeight/80),False);
             glDisable(GL_BLEND);
             glDisable(GL_LINE_SMOOTH);
           end;
      end;
    end;

    inc(i);
  end;

end;


procedure TESP.Draw3DBox(Index: Cardinal; lw:Single); stdcall;
var
  { --- 3D Vars --- }
  Head3D:RVec3;
  HNE:RVec3;
  HNW:RVec3;
  HSW:RVec3;
  HSE:RVec3;

  Feet3D:RVec3;
  FNE:RVec3;
  FNW:RVec3;
  FSW:RVec3;
  FSE:RVec3;

  { --- 2D Vars --- }
  sHNE:RVec2;
  sHNW:RVec2;
  sHSW:RVec2;
  sHSE:RVec2;

  sFNE:RVec2;
  sFNW:RVec2;
  sFSW:RVec2;
  sFSE:RVec2;

  { --- Box Width --- }
  bw:Single=3.75;



  bFailed:Boolean=False;
begin

  Head3D:=en^[Index].pos;
  Feet3D:=en^[Index].pos;
  Feet3D.z-=15;
  Head3d.z+=2;

  { --- Head Vertices --- }
  HNE:=Head3D;
  HNE.x+=bw;
  HNE.y+=bw;

  HNW:=Head3D;
  HNW.x-=bw;
  HNW.y+=bw;

  HSW:=Head3D;
  HSW.x-=bw;
  HSW.y-=bw;

  HSE:=Head3D;
  HSE.x+=bw;
  HSE.y-=bw;

  { --- Feet Vertices --- }
  FNE:=Feet3D;
  FNE.x+=bw;
  FNE.y+=bw;

  FNW:=Feet3D;
  FNW.x-=bw;
  FNW.y+=bw;

  FSW:=Feet3D;
  FSW.x-=bw;
  FSW.y-=bw;

  FSE:=Feet3D;
  FSE.x+=bw;
  FSE.y-=bw;

  { --- Projecting --- }
  { -> Head            }
  if not glW2S(HNE) then bFailed:=True else sHNE:=scrcord;
  if not glW2S(HNW) then bFailed:=True else sHNW:=scrcord;
  if not glW2S(HSW) then bFailed:=True else sHSW:=scrcord;
  if not glW2S(HSE) then bFailed:=True else sHSE:=scrcord;

  { -> Feet }
  if not glW2S(FNE) then bFailed:=True else sFNE:=scrcord;
  if not glW2S(FNW) then bFailed:=True else sFNW:=scrcord;
  if not glW2S(FSW) then bFailed:=True else sFSW:=scrcord;
  if not glW2S(FSE) then bFailed:=True else sFSE:=scrcord;

  { --- Drawing --- }
  if not bFailed then begin
   glEnable(GL_BLEND);
   glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
   glEnable(GL_LINE_SMOOTH);
   glColor3f(1,0,0);
  { -> Head         }
    DrawLine(sHNE.x,sHNE.y,sHNW.x,sHNW.y,lw); //North Line
    DrawLine(sHNE.x,sHNE.y,sHSE.x,sHSE.y,lw); //East Line
    DrawLine(sHSW.x,sHSW.y,sHSE.x,sHSE.y,lw); //South Line
    DrawLine(sHSW.x,sHSW.y,sHNW.x,sHNW.y,lw); //West Line

  { -> Feet         }
    DrawLine(sFNE.x,sFNE.y,sFNW.x,sFNW.y,lw); //North Line
    DrawLine(sFNE.x,sFNE.y,sFSE.x,sFSE.y,lw); //East Line
    DrawLine(sFSW.x,sFSW.y,sFSE.x,sFSE.y,lw); //South Line
    DrawLine(sFSW.x,sFSW.y,sFNW.x,sFNW.y,lw); //West Line

  { -> Vetical      }
    DrawLine(sHNE.x,sHNE.y,sFNE.x,sFNE.y,lw); //North East Line
    DrawLine(sHSE.x,sHSE.y,sFSE.x,sFSE.y,lw); //South East Line
    DrawLine(sHSW.x,sHSW.y,sFSW.x,sFSW.y,lw); //South West Line
    DrawLine(sHNW.x,sHNW.y,sFNW.x,sFNW.y,lw); //North West Line
  end;
end;






function TESP.glW2S( plypos: RVec3): Boolean; stdcall;
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
  scrcord.y := viewp[3]-scrcord.y;


  Result:=True;
  end;
end;



function TESP.IsTeamBased(): Boolean; stdcall;
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

