unit CMenuMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, gl, windows,
  GlobalVars, GlobalOffsets, cmenuwindow, ccontroldrawer, CustomTypes, DrawText;

type

  { TMenu }

  TMenu = class
    constructor Create(PosX: single; PosY: single; DimX: single; DimY: single;
      Title: ansistring; Scale: single; const AMenuPointersA: array of Pointer; const CheckBoxStrings: array of String);
    procedure DrawMenu;
    procedure DrawCursor;
    procedure PollControls;
    procedure InitMain;
    procedure CheckDragWindow(mx:Single; my:Single);
    procedure SetPos(x:Single; y:Single);

  public
    mainwin: TWindow;
    menupos: RVec2;
    menudim: RVec2;
    menutitle: ansistring;
    menuscale: single;
    MouseX:Single;
    MouseY:Single;
    CheckBoxes:array of TCheckbox;
    CheckBoxStrings:array of String;
    CheckBoxNumber:Cardinal;
    dwLibMikModBase:DWORD;
    MenuPointersA:array of Pointer;

    bMReleaser:Boolean;
    bDragging:Boolean;
    MenuPosX:Single;
    MenuPosY:Single;
    MouseXOri:Single;
    MouseYOri:Single;

    bInitialSetup:Boolean;
  end;


implementation

{ TMenu }

constructor TMenu.Create(PosX: single; PosY: single; DimX: single; DimY: single;
  Title: ansistring; Scale: single; const AMenuPointersA: array of Pointer; const CheckBoxStrings: array of String);
begin
  MenuPosX  := posx;
  MenuPosy  := posy;
  menupos.x := posx;
  menupos.y := posy;
  menudim.x := dimx * Scale;
  menudim.y := dimy * Scale + 13 * Scale;
  menutitle := title;
  menuscale := Scale;

  
  SetLength(Self.MenuPointersA,Length(AMenuPointersA));
  Move(AMenuPointersA[0],Self.MenuPointersA[0],Length(AMenuPointersA) * SizeOf(Pointer));

  SetLength(Self.CheckBoxes,Length(AMenuPointersA));

  SetLength(Self.CheckBoxStrings,Length(CheckBoxStrings));
  Move(CheckBoxStrings[0],Self.CheckBoxStrings[0],Length(CheckBoxStrings) * SizeOf(Pointer));

  CheckBoxNumber:=High(CheckBoxes);

  InitMain;
end;


procedure TMenu.InitMain();
var
  i:Cardinal;
begin
  mainwin := TWindow.Create(menupos, menudim, menutitle, menuscale);

  for i:= 0 to CheckBoxNumber do begin
      CheckBoxes[i]:= TCheckbox.Create(@mainwin, 3*menuscale, (13*menuscale)+((8*menuscale)*i), CheckBoxStrings[i], menuscale, True, MenuPointersA[i]);
  end;
end;


procedure TMenu.CheckDragWindow(mx: Single; my: Single);
begin
  if bDragging then begin
     MenuPosX:=mx-MouseXOri;
     MenuPosY:=my-MouseYOri;
  end
  else if (mx > menupos.x) and (mx < menupos.x + menudim.x) and
          (my > menupos.y) and (my < menupos.y + mainwin.TitleBarHeight) then
  begin
    bDragging:=True;
    MouseXOri:=mx - MenuPosX;
    MouseYOri:=my - MenuPosY;
  end;

  if not bMReleaser then bDragging:=False;
end;


procedure TMenu.DrawMenu;
var
  i:Cardinal;
begin
  menupos.x:=MenuPosX;
  menupos.y:=MenuPosY;

  mainwin.pos.x:=MenuPosX;
  mainwin.pos.y:=MenuPosY;

  mainwin.DrawWindow;
  for i:=0 to CheckBoxNumber do begin
      CheckBoxes[i].DrawCheckBox();
  end;
  DrawCursor;
end;


procedure TMenu.DrawCursor;
var
  viewp: array[0..3] of GLint = (0,0,0,0);
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
  FPS := Pointer(g_offset_SauerbratenBase+ g_offset_FPS);      //uptodate
  glGetIntegerv(GL_VIEWPORT, viewp);
  PMouseX := Pointer(g_offset_SauerbratenBase + g_offset_MouseCursorPosX);  //uptodate
  PMouseY := Pointer(g_offset_SauerbratenBase + g_offset_MouseCursorPosY);  //uptodate
  MouseX:=PSingle(PMouseX)^*viewp[2];
  MouseY:=PSingle(PMouseY)^*viewp[3];

  { --- wiggle --- }
  MouseVec[1][0]:=18.5+sin((g_pCounter/((PInteger(FPS)^/10)+1)))*2;
  MouseVec[3][1]:=27+sin((g_pCounter/((PInteger(FPS)^/10)+1)))*2;

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
  Clicked:Boolean=False;
  i:Cardinal;
  viewp: array[0..3] of GLint = (0,0,0,0);
  PMouseX: Pointer;
  PMouseY: Pointer;
begin
  glGetIntegerv(GL_VIEWPORT, viewp);
  PMouseX := Pointer(g_offset_SauerbratenBase + g_offset_MouseCursorPosX);  //uptodate
  PMouseY := Pointer(g_offset_SauerbratenBase + g_offset_MouseCursorPosY);  //uptodate
  MouseX:=PSingle(PMouseX)^*viewp[2];
  MouseY:=PSingle(PMouseY)^*viewp[3];

  if (GetAsyncKeyState($01) <> 0) and (not bMReleaser) then begin
    Clicked:=True;
    bMReleaser:=True;
  end;

  if (not (GetAsyncKeyState($01) <> 0)) and (not Clicked) then begin
    bMReleaser:=False;
  end;

  if Clicked then begin
    for i:=0 to CheckBoxNumber do begin
        CheckBoxes[i].WasThisClicked(MouseX,MouseY);
    end;
  end;

  CheckDragWindow(MouseX,MouseY);
end;


procedure TMenu.SetPos(x:Single; y:Single);
begin
  Self.MenuPosX:=x;
  Self.MenuPosY:=y;
end;


end.
