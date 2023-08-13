unit CNoclip;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, Math, DrawText, gl;

type

  { TNoclip }

  TNoclip = class
    constructor Create;
    procedure PollControls; stdcall;
    procedure NOPFalling(State1Kill0Fix: boolean); stdcall;
    procedure MovePlayer(Direction: char); stdcall;

  public
    addposx: Pointer;
    addposy: Pointer;
    addposz: Pointer;
    addcamx: Pointer;
    addcamy: Pointer;
    posx: PSingle;
    posy: PSingle;
    posz: PSingle;
    camx: PSingle;
    camy: PSingle;

    SpeedNormal: single;
    SpeedFast: single;
    SpeedSlow: single;
    SpeedCurrent: single;
  end;

implementation

{ TNoclip }

constructor TNoclip.Create;
var
  Original: Pointer;
  FPS: Pointer;
begin
  { ------- Setup Pointers To Writiable Player Positon ------- }
  { -> not the same as the one in the entity list              }
  { -> has some implications for taty          ..or mabye not  }
  Original := Pointer(GetModuleHandle('sauerbraten.exe') + $317110); //uptodate 2023/08/12
  addposx := Pointer(Original^) + $30;
  addposy := addposx + $4;
  addposz := addposx + $8;
  addcamx := addposx + $C;
  addcamy := addposx + $10;

  camx := addcamx;
  camy := addcamy;
  posx := addposx;
  posy := addposy;
  posz := addposz;

  { -------- Init Variables -------- }
  FPS := Pointer(GetModuleHandle('sauerbraten.exe') + $39A644); //uptodate 2023/08/12
  SpeedNormal := 200 / PInteger(FPS)^;
  SpeedFast := SpeedNormal * 3;
  SpeedSlow := SpeedNormal / 3;
  SpeedCurrent := SpeedNormal;
end;

procedure TNoclip.PollControls; stdcall;
var
  viewp: array [0..3] of Glint;
  ResetFallSpeed: Pointer;
begin
  if GetAsyncKeyState(VK_LSHIFT) <> 0 then
    SpeedCurrent := SpeedFast;
  if GetAsyncKeyState(VK_LCONTROL) <> 0 then
    SpeedCurrent := SpeedSlow;
  if GetAsyncKeyState(VK_W) <> 0 then
    MovePlayer('W');
  if GetAsyncKeyState(VK_A) <> 0 then
    MovePlayer('A');
  if GetAsyncKeyState(VK_S) <> 0 then
    MovePlayer('S');
  if GetAsyncKeyState(VK_D) <> 0 then
    MovePlayer('D');
  if GetAsyncKeyState(VK_SPACE) <> 0 then
    MovePlayer('U');


  ResetFallSpeed := Pointer(PCardinal(GetModuleHandle('sauerbraten.exe') + $216454)^ + $20);
  //PSingle(ResetFallSpeed)^ := 0;    //CURRENTLY BROKEN
  glColor3f(0.8, 0.8, 0.8);
  glGetIntegerv(GL_VIEWPORT, viewp);
  glxDrawString(20, viewp[3] - 115, 'Noclip active', 2, True);
end;


{ ------------------------------ NOP Falling ------------------------------- }
{ -> This function replaces the the instructions to move the player when     }
{    falling with NOP (no operation) aka $90                                 }
{ -> the parameter 1 will kill the code, replacing the sections with NOP     }
{ -> the parameter 0 will restore the original code, enabling gravity        }
procedure TNoclip.NOPFalling(State1Kill0Fix: boolean); stdcall;
var
  OriginalCodeZ: array [0..2] of byte = ($D8, $6B, $20);
  OriginalCodeXY: array [0..4] of byte = ($66, $0F, $D6, $46, $30);
  SauerBase: Pointer;
  PosWriter: Pointer;
  TheKiller: PByte;
  Garbage: DWORD;
  i: cardinal;
begin
  Sauerbase := Pointer(GetModuleHandle('sauerbraten.exe'));


  if State1Kill0Fix = False then
  begin //Fixing code
    { ---- Z Axis ---- }
    PosWriter := Pointer(SauerBase + $A5EC0);  //uptodate 2023/08/13
    VirtualProtect(PosWriter, 3, PAGE_EXECUTE_READWRITE, Garbage);
    TheKiller := PosWriter;
    for i := 0 to 2 do
    begin
      PByte(TheKiller + i)^ := OriginalCodeZ[i];   //CURRENTLY BROKEN
    end;

    { ---- X/Y Axis ---- }
    PosWriter := Pointer(SauerBase + $E88DD);   //FIX THIS
    TheKiller := PosWriter;
    for i := 0 to 4 do
    begin
      //PByte(TheKiller + i)^ := OriginalCodeXY[i];   //CURRENTLY BROKEN
    end;
  end
  else
  begin //Killing Code
    { ---- Z Axis ---- }
    PosWriter := Pointer(SauerBase + $A5EC0);  //uptodate 2023/08/13
    VirtualProtect(PosWriter, 3, PAGE_EXECUTE_READWRITE, Garbage);
    TheKiller := PosWriter;
    for i := 0 to 2 do
    begin
      PByte(TheKiller + i)^ := $90; //CURRENTLY BROKEN
    end;

    { ---- X/Y Axis ---- }
    PosWriter := Pointer(SauerBase + $E88DD); //FIX THIS
    TheKiller := PosWriter;
    for i := 0 to 4 do
    begin
      //PByte(TheKiller + i)^ := $90;   //CURRENTLY BROKEN
    end;

  end;

end;

procedure TNoclip.MovePlayer(Direction: char); stdcall;
begin
  case Direction of
    'W':
    begin
      posx^ := posx^ + (cos((camx^ + 90) / 57.2958) * SpeedCurrent) *
        (1.57079576 -  (abs((camy^ / 57.2958))));
      posy^ := posy^ + (sin((camx^ + 90) / 57.2958) * SpeedCurrent) *
        (1.57079576 -  (abs((camy^ / 57.2958))));
      posz^ := posz^ + (sin((camy^ / 57.2958)) * SpeedCurrent);
    end;
    'A':
    begin
      posx^ := posx^ + (cos((camx^ + 00) / 57.2958) * SpeedCurrent);
      posy^ := posy^ + (sin((camx^ + 00) / 57.2958) * SpeedCurrent);
    end;
    'S':
    begin
      posx^ := posx^ + (cos((camx^ - 90) / 57.2958) * SpeedCurrent) *
        (1.57079576 -  (abs((camy^ / 57.2958))));
      posy^ := posy^ + (sin((camx^ - 90) / 57.2958) * SpeedCurrent) *
        (1.57079576 -  (abs((camy^ / 57.2958))));
      posz^ := posz^ - (sin((camy^ / 57.2958)) * SpeedCurrent);
    end;
    'D':
    begin
      posx^ := posx^ + (cos((camx^ - 180) / 57.2958) * SpeedCurrent);
      posy^ := posy^ + (sin((camx^ + 180) / 57.2958) * SpeedCurrent);
    end;
    'U': posz^ := posz^ + SpeedCurrent;

  end;

end;

end.
