unit CNoclip;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, Math, DrawText, gl, GlobalVars,

  { my stuff }

  GlobalOffsets;

type

  { TNoclip }

  TNoclip = class
    constructor Create;
    procedure Poll; stdcall;
    procedure PollControls; stdcall;
    procedure NOPFalling(State1Kill0Fix: boolean); stdcall;
    procedure ZeroVelocities(); stdcall;
    procedure MovePlayer(Direction: char); stdcall;

  public
    addposx: Pointer;
    addposy: Pointer;
    addposz: Pointer;
    addvelx: Pointer;
    addvely: Pointer;
    addvelz: Pointer;
    addcamx: Pointer;
    addcamy: Pointer;
    posx: PSingle;
    posy: PSingle;
    posz: PSingle;
    velx: PSingle;
    vely: PSingle;
    velz: PSingle;
    camx: PSingle;
    camy: PSingle;

    SpeedNormal: single;
    SpeedFast: single;
    SpeedSlow: single;
    SpeedCurrent: single;

    bEnableNoclip:Boolean;
    bNoclipButtonPressed:Boolean;
  end;

implementation

{ TNoclip }

constructor TNoclip.Create;
var
  Original: Pointer;
begin
  { ------- Setup Pointers To Writiable Player Positon ------- }
  { -> not the same as the one in the entity list              }
  { -> has some implications for taty          ..or mabye not  }
  Original := Pointer(g_offset_SauerbratenBase + g_offset_EntityList); //uptodate 2023/08/12
  addposx := PPointer(Pointer(Original^) + 0)^ + g_offset_Player_PosXW; // 0 indexes the local player
  addposy := PPointer(Pointer(Original^) + 0)^ + g_offset_Player_PosYW;
  addposz := PPointer(Pointer(Original^) + 0)^ + g_offset_Player_PosZW;
  addvelx := PPointer(Pointer(Original^) + 0)^ + g_offset_Player_VelXW;
  addvely := PPointer(Pointer(Original^) + 0)^ + g_offset_Player_VelYW;
  addvelz := PPointer(Pointer(Original^) + 0)^ + g_offset_Player_VelZW;
  addcamx := PPointer(Pointer(Original^) + 0)^ + g_offset_Player_CamXW;
  addcamy := PPointer(Pointer(Original^) + 0)^ + g_offset_Player_CamYW;

  posx := addposx;
  posy := addposy;
  posz := addposz;
  velx := addvelx;
  vely := addvely;
  velz := addvelz;
  camx := addcamx;
  camy := addcamy;


end;

{ ---------------------------------- Poll ---------------------------------- }
{ -> is executed every frame by MainFunc                                     }
{ -> handles the 'V' hotkey to enable and disable noclip and also checks     }
{    the menu setting g_EnableNoclipping                                     }
{ -> includes a mechanism to prevent spamming                                }
procedure TNoclip.Poll; stdcall;
begin
    if (GetAsyncKeyState(VK_V) <> 0) and (not Self.bNoclipButtonPressed) and
    (not Self.bEnableNoclip) and (g_EnableNoclipping = 1) then
  begin
    Self.bEnableNoclip := True;
    Self.bNoclipButtonPressed := True;
  end;

  if (GetAsyncKeyState(VK_V) <> 0) and (not Self.bNoclipButtonPressed) and
    (Self.bEnableNoclip) then
  begin
    Self.bEnableNoclip := False;
    Self.bNoclipButtonPressed := True;
  end;

  if (GetAsyncKeyState(VK_V) = 0) then
    Self.bNoclipButtonPressed := False;

  if Self.bEnableNoclip then
  begin
    Self.PollControls;
    Self.NOPFalling(True);
    Self.ZeroVelocities();
  end
  else
  begin
    Self.NOPFalling(False);
  end;
end;

procedure TNoclip.PollControls; stdcall;
var
  viewp: array [0..3] of Glint = (0,0,0,0);
  FPS: Pointer;
begin
  FPS := Pointer(g_offset_SauerbratenBase + g_offset_FPS); //uptodate 2023/08/12
  SpeedNormal := 200 / PInteger(FPS)^;
  SpeedFast := SpeedNormal * 3;
  SpeedSlow := SpeedNormal / 3;
  SpeedCurrent := SpeedNormal;

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
  OriginalCodeZ: array [0..2] of byte = ($D8, $6B, $20); //uptodate 2023/08/13
  OriginalCodeZDrift: array [0..2] of byte = ($89, $45, $38); //uptodate 2023/08/13
  OriginalCodeXY: array [0..1] of byte = ($D8, $CA);     //uptodate 2023/08/13
  PosWriter: Pointer;
  TheKiller: PByte;
  Garbage: DWORD;
  i: cardinal;
begin


  if State1Kill0Fix = False then
  begin //Fixing code
    { ---- Z Axis ---- }
    PosWriter := Pointer(g_offset_SauerbratenBase + $A5EC0);  //uptodate 2023/08/13
    VirtualProtect(PosWriter, 3, PAGE_EXECUTE_READWRITE, Garbage);
    TheKiller := PosWriter;
    for i := 0 to 2 do
    begin
      PByte(TheKiller + i)^ := OriginalCodeZ[i];
    end;

    { - Z Axis Drift - }
    PosWriter := Pointer(g_offset_SauerbratenBase + $AE610);  //uptodate 2023/08/13
    VirtualProtect(PosWriter, 3, PAGE_EXECUTE_READWRITE, Garbage);
    TheKiller := PosWriter;
    for i := 0 to 2 do
    begin
      PByte(TheKiller + i)^ := OriginalCodeZDrift[i];
    end;

    { ---- X Axis ---- }
    PosWriter := Pointer(g_offset_SauerbratenBase + $A59FC);   //uptodate 2023/08/13
    TheKiller := PosWriter;
    for i := 0 to 1 do
    begin
      PByte(TheKiller + i)^ := OriginalCodeXY[i];
    end;

    { ---- Y Axis ---- }
    PosWriter := Pointer(g_offset_SauerbratenBase + $A5A0C);   //uptodate 2023/08/13
    TheKiller := PosWriter;
    for i := 0 to 1 do
    begin
      PByte(TheKiller + i)^ := OriginalCodeXY[i];
    end;

  end
  else
  begin //Killing Code
    { ---- Z Axis ---- }
    PosWriter := Pointer(g_offset_SauerbratenBase + $A5EC0);  //uptodate 2023/08/13
    VirtualProtect(PosWriter, 3, PAGE_EXECUTE_READWRITE, Garbage);
    TheKiller := PosWriter;
    for i := 0 to 2 do
    begin
      PByte(TheKiller + i)^ := $90;
    end;

    { - Z Axis Drift - }
    PosWriter := Pointer(g_offset_SauerbratenBase + $AE610);  //uptodate 2023/08/13
    VirtualProtect(PosWriter, 3, PAGE_EXECUTE_READWRITE, Garbage);
    TheKiller := PosWriter;
    for i := 0 to 2 do
    begin
      PByte(TheKiller + i)^ := $90;
    end;

    { ---- X Axis ---- }
    PosWriter := Pointer(g_offset_SauerbratenBase + $A59FC); //FIX THIS
    TheKiller := PosWriter;
    for i := 0 to 1 do
    begin
      PByte(TheKiller + i)^ := $90;
    end;

    { ---- X Axis ---- }
    PosWriter := Pointer(g_offset_SauerbratenBase + $A5A0C); //FIX THIS
    TheKiller := PosWriter;
    for i := 0 to 1 do
    begin
      PByte(TheKiller + i)^ := $90;
    end;

  end;

end;


procedure TNoclip.ZeroVelocities(); stdcall;
begin
  velx^:=0;
  vely^:=0;
  velz^:=0;
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
