unit CControlDrawer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, gl, Windows,
  DrawText, CustomTypes, cmenuwindow;

type

  { TCheckbox }

  TCheckbox = class
    constructor Create(ParentWindow: PTWindow; RelativePosX: single;
      RelativePosY: single; Text: ansistring; Scale: single; CheckboxEnabled: boolean; SettingPtr:Pointer);
    procedure DrawCheckBox;
    procedure SwitchCheckedState;
    procedure WasThisClicked(mx: single; my: single);
  private
    procedure DrawBox(top: single; left: single; bottom: single;
      right: single; LineThickness: single); stdcall;
    procedure DrawLine(StartX: single; StartY: single; EndX: single;
      EndY: single; LineTickness: single); stdcall;
    procedure HandleClick;
  public
    bChecked: boolean;
    parent: PTWindow;
    pos: RVec2;
    txt: ansistring;
    txtscale: single;
    CBSize: single;
    SettingPointer:Pointer;
  end;




implementation

{ TCheckbox }

constructor TCheckbox.Create(ParentWindow: PTWindow; RelativePosX: single;
  RelativePosY: single; Text: ansistring; Scale: single;
  CheckboxEnabled: boolean; SettingPtr: Pointer);
begin
  parent := ParentWindow;
  pos.x := RelativePosX;
  pos.y := RelativePosY;
  txt := Text;
  txtscale := Scale;
  CBSize := 10;
  SettingPointer:=SettingPtr;
  bChecked := Boolean(PByte(SettingPointer)^);
end;

procedure TCheckbox.DrawCheckBox;
var
  FinalPos: RVec2;
  tempCBSize:Single;
begin
  tempCBSize := CBSize * txtscale / 2;
  FinalPos.x := pos.x + parent^.pos.x;
  FinalPos.y := pos.y + parent^.pos.y;

  if bChecked then
  begin
    glColor3f(0.2, 0.5, 0.2);
    glBegin(GL_LINES);
    DrawLine(FinalPos.x, FinalPos.y, FinalPos.x + tempCBSize, FinalPos.y + tempCBSize, txtscale / 2);
    DrawLine(FinalPos.x, FinalPos.y + tempCBSize, FinalPos.x + tempCBSize, FinalPos.y, txtscale / 2);
    glEnd();
  end;

  glColor3f(0.4, 0.4, 0.4);
  DrawBox(Finalpos.y, Finalpos.x, Finalpos.y + tempCBSize, Finalpos.x + tempCBSize, txtscale );
  glxDrawString(FinalPos.x + tempCBSize + tempCBSize / 2, FinalPos.y +
    (txtscale / 2), txt, txtscale, True);
end;


procedure TCheckbox.SwitchCheckedState;
begin
  bChecked := not bChecked;
  PByte(SettingPointer)^:=Byte(bChecked);
end;

procedure TCheckbox.WasThisClicked(mx: single; my: single);
var
  FinalPos:RVec2;
  tempCBSize:Single;
begin
  FinalPos.x := pos.x + parent^.pos.x;
  FinalPos.y := pos.y + parent^.pos.y;
  tempCBSize := CBSize * txtscale / 2;
  if (mx > FinalPos.x) and (mx < (FinalPos.x + tempCBSize)) and
     (my > FinalPos.y) and (my < (FinalPos.y + tempCBSize)) then
  begin
    HandleClick;
  end;
end;


procedure TCheckbox.HandleClick;
begin
  SwitchCheckedState;
end;


procedure TCheckbox.DrawLine(StartX: single; StartY: single; EndX: single;
  EndY: single; LineTickness: single);
  stdcall;
begin
  glLineWidth(LineTickness);
  glBegin(GL_LINES);
  glVertex2f(StartX, StartY);
  glVertex2f(EndX, EndY);
  glEnd();
end;


procedure TCheckbox.DrawBox(top: single; left: single; bottom: single;
  right: single; LineThickness: single); stdcall;
begin
  DrawLine(left, top, right, top, LineThickness);       //upper border
  DrawLine(left, top, left, bottom, LineThickness);     //left border
  DrawLine(left, bottom, right, bottom, LineThickness); //bottom
  DrawLine(right, top, right, bottom, LineThickness);   //right
end;

end.

