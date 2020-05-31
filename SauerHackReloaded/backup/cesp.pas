unit CESP;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, gl, glu,windows,

  CPlayer, DrawText;

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
  TeamStr:array[0..4] of char = (Char(0),Char(0),Char(0),Char(0),Char(0));

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
             DrawBox(pHead.y,pHead.x - (dWidth/2),pFeet.y, pFeet.x + (dWidth/2)  ,abs(dHeight/80));
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

