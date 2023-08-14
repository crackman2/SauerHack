unit CMenuMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, gl, windows,
  globalvars, cmenuwindow, ccontroldrawer, CustomTypes, DrawText;

type

  { TMenu }

  TMenu = class
    constructor Create(PosX: single; PosY: single; DimX: single; DimY: single;
      Title: ansistring; Scale: single; const AMenuPointersA: array of Pointer);
    procedure DrawMenu;
    procedure DrawCursor;
    procedure PollControls;
    procedure InitMain;
    procedure CheckDragWindow(mx:Single; my:Single);

  public
    mainwin: TWindow;
    menupos: RVec2;
    menudim: RVec2;
    menutitle: ansistring;
    menuscale: single;
    MouseX:Single;
    MouseY:Single;
    CheckBoxes:array [0..5] of TCheckbox;
    CheckBoxStrings:array [0..5] of String;
    CheckBoxNumber:Cardinal;
    dwLibMikModBase:DWORD;
    MenuPointersA:array of Pointer;
  end;


implementation

{ TMenu }

constructor TMenu.Create(PosX: single; PosY: single; DimX: single; DimY: single;
  Title: ansistring; Scale: single; const AMenuPointersA: array of Pointer);
begin
  menupos.x := posx;
  menupos.y := posy;
  menudim.x := dimx;
  menudim.y := dimy;
  menutitle := title;
  menuscale := Scale;


  SetLength(Self.MenuPointersA,Length(AMenuPointersA));
  //Self.MenuPointersA:=AMenuPointersA;
  Move(AMenuPointersA[0],Self.MenuPointersA[0],Length(AMenuPointersA) * SizeOf(Pointer));
  CheckBoxNumber:=High(CheckBoxes);

  { ------ View Main.pas for more info ------ }
  //dwLibMikModBase:=GetModuleHandle('libmikmod-2.dll')+$35090; //old, dont use

  InitMain;
end;

procedure TMenu.InitMain;
var
  i:Cardinal;
begin
  mainwin := TWindow.Create(menupos, menudim, menutitle);

  CheckBoxStrings[0]:='Enable ESP';
  CheckBoxStrings[1]:='Enable Aimbot';
  CheckBoxStrings[2]:='Enable Lockaim';
  CheckBoxStrings[3]:='Enable Noclipping';
  CheckBoxStrings[4]:='Enable Teleport all to you';
  CheckBoxStrings[5]:='Enable autocapture flag';

  for i:= 0 to CheckBoxNumber do begin
      CheckBoxes[i]:= TCheckbox.Create(@mainwin, 10, 40+((8*menuscale)*i), CheckBoxStrings[i], menuscale, True, MenuPointersA[i]);
  end;
end;

procedure TMenu.CheckDragWindow(mx: Single; my: Single);
//var
    //Dragging:Pointer=nil;
    //MouseXOri:Pointer=nil;
    //MouseYOri:Pointer=nil;
    //MReleaser:PByte=nil;
    //MenuPosX:Pointer=nil;
    //MenuPosY:Pointer=nil;
begin
    //Dragging:=Pointer (cave + $508);
    //MouseXOri:=Pointer(cave + $50C);
    //MouseYOri:=Pointer(cave + $510);
    //MReleaser:=PByte  (cave + $3F0);
    //MenuPosX:=Pointer (cave + $500);
    //MenuPosY:=Pointer (cave + $504);

  if global_Dragging=1 then begin
     global_MenuPosX:=mx-global_MouseXOri;
     global_MenuPosY:=my-global_MouseYOri;
  end
  else if (mx > menupos.x) and (mx < menupos.x + menudim.x) and
          (my > menupos.y) and (my < menupos.y + mainwin.TitleBarHeight) then
  begin
    Dragging:=1;
    global_MouseXOri:=mx - global_MenuPosX;
    global_MouseYOri:=my - global_MenuPosY;
  end;

  if global_MReleaser=0 then global_Dragging:=0;
end;

procedure TMenu.DrawMenu;
var
  i:Cardinal;
begin
  mainwin.DrawWindow;
  for i:=0 to CheckBoxNumber do begin
      CheckBoxes[i].DrawCheckBox();
  end;
  DrawCursor;
end;

procedure TMenu.DrawCursor;
var
  viewp: array[0..3] of GLint;
  PMouseX: Pointer;
  PMouseY: Pointer;
  MouseVec: array [0..3] of array [0..1] of single =
    {//////////////////////}((0,  0),/////
    {//////////////////////}(17, 17),/////
    {//////////////////////}( 8, 21),/////
    {//////////////////////}( 0, 27) /////
    {//////////////////////});////////////
  i:Cardinal;
  FPS:Pointer;
begin
  FPS := Pointer(GetModuleHandle('sauerbraten.exe') + $39A644);      //uptodate
  glGetIntegerv(GL_VIEWPORT, viewp);
  PMouseX := Pointer(GetModuleHandle('sauerbraten.exe') + $2A6010);  //uptodate
  PMouseY := Pointer(GetModuleHandle('sauerbraten.exe') + $2A600C);  //uptodate
  MouseX:=PSingle(PMouseX)^*viewp[2];
  MouseY:=PSingle(PMouseY)^*viewp[3];

  { --- wiggle --- }
  MouseVec[1][0]:=18.5+sin((global_pCounter/((PInteger(FPS)^/10)+1)))*2;
  MouseVec[3][1]:=27+sin((global_pCounter/((PInteger(FPS)^/10)+1)))*2;

  glColor3f(1,1,1);
  glBegin(GL_QUADS);
  for i:=0 to 3 do begin
  glVertex2f(MouseX+MouseVec[i][0],MouseY+MouseVec[i][1]);
  end;
  glEnd();

  glColor3f(0.1,0.2,0.1);
  glLineWidth(1);
  glBegin(GL_LINES);
  for i:=0 to 3 do begin
  glVertex2f(MouseX+MouseVec[i][0],MouseY+MouseVec[i][1]);
  end;
  glEnd();
end;

procedure TMenu.PollControls;
var
  //MReleaser:PByte=PByte(cave + $3F0);
  //MReleaser:PByte=nil;
  Clicked:Boolean=False;
  i:Cardinal;
  viewp: array[0..3] of GLint;
  PMouseX: Pointer;
  PMouseY: Pointer;
begin
  //MReleaser:=PByte(cave + $3F0);
  //MReleaser:PByte=PByte(cave + $3F0);
  //MReleaser:=PByte(dwLibMikModBase + $0F0);
  glGetIntegerv(GL_VIEWPORT, viewp);
  PMouseX := Pointer(GetModuleHandle('sauerbraten.exe') + $2A6010);  //uptodate
  PMouseY := Pointer(GetModuleHandle('sauerbraten.exe') + $2A600C);  //uptodate
  MouseX:=PSingle(PMouseX)^*viewp[2];
  MouseY:=PSingle(PMouseY)^*viewp[3];

  if (GetAsyncKeyState($01) <> 0) and (global_MReleaser=0) then begin
    Clicked:=True;
    global_MReleaser:=1;
  end;

  if (not (GetAsyncKeyState($01) <> 0)) and (not Clicked) then begin
    global_MReleaser:=0;
  end;

  if Clicked then begin
    for i:=0 to CheckBoxNumber do begin
        CheckBoxes[i].WasThisClicked(MouseX,MouseY);
    end;
  end;

  CheckDragWindow(MouseX,MouseY);
end;

end.
