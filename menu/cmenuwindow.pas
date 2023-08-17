unit CMenuWindow;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, gl,
  CustomTypes, DrawText;

type

  { TWindow }

  TWindow = class
    constructor Create(Position: RVec2; Dimensions: RVec2; WindowTitle: ansistring; scale:Single);
    procedure DrawWindow;

  public
    pos: RVec2;
    dim: RVec2;
    title: ansistring;
      TitleBarHeight: single;
    scale: Single;
  end;

  PTWindow = ^TWindow;

implementation

{ TWindow }

constructor TWindow.Create(Position: RVec2; Dimensions: RVec2; WindowTitle: ansistring; scale:Single);
begin
  pos := Position;
  dim := Dimensions;
  title := WindowTitle;
  Self.scale := scale;

  TitleBarHeight:=10*scale;
end;

procedure TWindow.DrawWindow;
begin
  { ------------------------------- Main Area ------------------------------ }
  glColor3f(0.6, 0.6, 0.6);
  glBegin(GL_QUADS);
  glVertex2f(pos.x, pos.y);
  glVertex2f(pos.x + dim.x, pos.y);
  glVertex2f(pos.x + dim.x, pos.y + dim.y);
  glVertex2f(pos.x, pos.y + dim.y);
  glEnd();

  { ------------------------------- Titlebar ------------------------------- }
  glColor3f(0.2, 0.2, 0.2);
  glBegin(GL_QUADS);
  glVertex2f(pos.x, pos.y);
  glVertex2f(pos.x + dim.x, pos.y);
  glVertex2f(pos.x + dim.x, pos.y + TitleBarHeight);
  glVertex2f(pos.x, pos.y + TitleBarHeight);
  glEnd();

  { ----------------------------- Titlebar Text ---------------------------- }
  glColor3f(0.8,0.8,0.8);
  glxDrawString(pos.x+TitleBarHeight/2,pos.y+TitleBarHeight/4,title,TitleBarHeight/10,true);
end;

end.
