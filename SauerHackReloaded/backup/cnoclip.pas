unit CNoclip;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, windows, math, DrawText, gl;

type

  { TNoclip }

  TNoclip = class
    Constructor Create;
    procedure PollControls;stdcall;
    procedure NOPFalling(State1Kill0Fix:Boolean);stdcall;
    procedure MovePlayer(Direction:Char);stdcall;
    public
    addposx:Pointer;
    addposy:Pointer;
    addposz:Pointer;
    addcamx:Pointer;
    addcamy:Pointer;
    posx:PSingle;
    posy:PSingle;
    posz:PSingle;
    camx:PSingle;
    camy:PSingle;

    SpeedNormal:Single;
    SpeedFast:Single;
    SpeedSlow:Single;
    SpeedCurrent:Single;
  end;

implementation

{ TNoclip }

constructor TNoclip.Create;
var Original:Pointer;
    FPS:Pointer;
begin
  { ------- Setup Pointers To Writiable Player Positon ------- }
  { -> not the same as the one in the entity list              }
  { -> has some implications for taty          ..or mabye not  }
  Original:=Pointer(GetModuleHandle('sauerbraten.exe') + $213EA8);
  addposx:=Pointer(Original^) + $30;
  addposy:=addposx + $4;
  addposz:=addposx + $8;
  addcamx:=addposx + $C;
  addcamy:=addposx + $10;

  camx:=addcamx;
  camy:=addcamy;
  posx:=addposx;
  posy:=addposy;
  posz:=addposz;

  {
  if GetAsyncKeyState(VK_O) <> 0 then begin
  MessageBox(0,PChar('addposx: ' + IntToHex(Cardinal(addposx),8) + LineEnding +
                     'addposy: ' + IntToHex(Cardinal(addposy),8) + LineEnding +
                     'addposz: ' + IntToHex(Cardinal(addposz),8) + LineEnding +
                     'addcamx: ' + IntToHex(Cardinal(addcamx),8) + LineEnding +
                     'addcamy: ' + IntToHex(Cardinal(addcamy),8) + LineEnding),'e',0);
  end;
  }
  { -------- Init Variables -------- }
  FPS:=Pointer(GetModuleHandle('sauerbraten.exe') + $2A0710);
  SpeedNormal:=200/PInteger(FPS)^;
  SpeedFast:=SpeedNormal*3;
  SpeedSlow:=SpeedNormal/3;
  SpeedCurrent:=SpeedNormal;
end;

procedure TNoclip.PollControls; stdcall;
var
    viewp:array [0..3] of Glint;
    ResetFallSpeed:Pointer;
begin
  //glxDrawString(200,320,'Polling Controls',2,true);
  //glxDrawString(200,360,'posx: ' + IntToStr(round(posx^)),2,true);
  //glxDrawString(200,380,'posy: ' + IntToStr(round(posy^)),2,true);
  //glxDrawString(200,400,'posz: ' + IntToStr(round(posz^)),2,true);
  //glxDrawString(200,420,'camx: ' + IntToStr(round(camx^)),2,true);
  //glxDrawString(200,440,'camy: ' + IntToStr(round(camy^)),2,true);
  //glxDrawString(200,460,'Speed: ' + IntToStr(round(SpeedCurrent)),2,true);
  if GetAsyncKeyState(VK_LSHIFT) <> 0 then SpeedCurrent:=SpeedFast;
  if GetAsyncKeyState(VK_LCONTROL) <> 0 then SpeedCurrent:=SpeedSlow;
  if GetAsyncKeyState(VK_W) <> 0 then MovePlayer('W');
  if GetAsyncKeyState(VK_A) <> 0 then MovePlayer('A');
  if GetAsyncKeyState(VK_S) <> 0 then MovePlayer('S');
  if GetAsyncKeyState(VK_D) <> 0 then MovePlayer('D');
  if GetAsyncKeyState(VK_SPACE) <> 0 then MovePlayer('U');


  ResetFallSpeed:=Pointer(Pointer(GetModuleHandle('sauerbraten.exe') + $216454)^) + $20);
  PSingle(ResetFallSpeed)^:=0;
  glColor3f(0.8,0.8,0.8);
  glGetIntegerv(GL_VIEWPORT,viewp);
  glxDrawString(20,viewp[3]- 115,'Noclip active',2,true);
end;

procedure TNoclip.NOPFalling(State1Kill0Fix:Boolean); stdcall;
var
  OriginalCodeZ:array [0..2] of Byte = ($89,$46,$38);
  OriginalCodeXY:array [0..4] of Byte = ($66,$0F,$D6,$46,$30);
  SauerBase:Pointer;
  PosWriter:Pointer;
  TheKiller:PByte;
  Garbage:DWORD;
  i:Cardinal;
begin
     Sauerbase:=Pointer(GetModuleHandle('sauerbraten.exe'));


  if State1Kill0Fix = False then begin //Fixing code
     { ---- Z Axis ---- }
     PosWriter:=Pointer(SauerBase + $E88E2);
     VirtualProtect(PosWriter,3,PAGE_EXECUTE_WRITECOPY,Garbage);
     TheKiller:=PosWriter;
     for i:=0 to 2 do begin
               PByte(TheKiller + i)^:=OriginalCodeZ[i];
     end;

     { ---- X/Y Axis ---- }
     PosWriter:=Pointer(SauerBase + $E88DD);
     TheKiller:=PosWriter;
     for i:=0 to 4 do begin
         PByte(TheKiller + i)^:=OriginalCodeXY[i];
     end;
  end
  else begin //Killing Code
     { ---- Z Axis ---- }
     PosWriter:=Pointer(SauerBase + $E88E2);
     VirtualProtect(PosWriter,3,PAGE_EXECUTE_WRITECOPY,Garbage);
     TheKiller:=PosWriter;
     for i:=0 to 2 do begin
               PByte(TheKiller + i)^:=$90;
     end;

     { ---- X/Y Axis ---- }
     PosWriter:=Pointer(SauerBase + $E88DD);
     TheKiller:=PosWriter;
     for i:=0 to 4 do begin
          PByte(TheKiller + i)^:=$90;
     end;


  end;

end;

procedure TNoclip.MovePlayer(Direction: Char); stdcall;
begin
  case Direction of
  'W': begin
            posx^:=posx^+(cos((camx^+90)/57.2958)*SpeedCurrent)*(1.57079576 - (abs((camy^ / 57.2958))));
            posy^:=posy^+(sin((camx^+90)/57.2958)*SpeedCurrent)*(1.57079576 - (abs((camy^ / 57.2958))));
            posz^:=posz^ + (sin((camy^ / 57.2958)) * SpeedCurrent)
       end;
  'A': begin
            posx^:=posx^+(cos((camx^+00)/57.2958)*SpeedCurrent);
            posy^:=posy^+(sin((camx^+00)/57.2958)*SpeedCurrent);
       end;
  'S': begin
            posx^:=posx^+(cos((camx^-90)/57.2958)*SpeedCurrent)*(1.57079576 - (abs((camy^ / 57.2958))));
            posy^:=posy^+(sin((camx^-90)/57.2958)*SpeedCurrent)*(1.57079576 - (abs((camy^ / 57.2958))));
            posz^:=posz^ - (sin((camy^ / 57.2958)) * SpeedCurrent);
       end;
  'D': begin
            posx^:=posx^+(cos((camx^-180)/57.2958)*SpeedCurrent);
            posy^:=posy^+(sin((camx^+180)/57.2958)*SpeedCurrent);
       end;
  'U': posz^:=posz^+SpeedCurrent;

  end;

end;

end.

