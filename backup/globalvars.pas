unit globalvars;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, gl, glu, windows;
var
  { ----------------------------- cave pointer  ---------------------------- }
  { -> main code cave pointer                                                }
  { -> value set during hook setup                                           }
  { -> cave starts right after the jump back to wglSwapbuffers               }
  cave:Pointer;
  caveHDC:HDC;
  caveNewRC:HGLRC;

  global_LockAim:Byte;
  global_ReleasedRBM:Byte;
  global_EnableNoclip:Byte;
  global_NoclipButtonPressed:Byte;
  global_MReleaser:Byte;
  global_MenuPosX:Single;
  global_MenuPosY:Single;
  global_Dragging:Byte;
  global_MouseXOri:Single;
  global_MouseYOri:Single;

  global_MenuInitialSetup:Byte=0;


  { --- Checkboxes for Menu --- }
  global_EnableESP:Byte;          //0
  global_EnableAimbot:Byte;       //1
  global_EnableLockAim:Byte;      //2
  global_EnableNoclipping:Byte;   //3
  global_EnableTATY:Byte;         //4
  global_EnableFlagSteal:Byte;    //5

  MenuPointers:array of Pointer;

  pCounter:Cardinal=0;



  EnableDebug:Byte;
  DebugButtonPressed:Byte;




  {
  LockAim:= PByte         (cave + $3C0);
  ReleasedRBM:=PByte      (cave + $3C8);
  EnableNoclip := PByte   (cave + $3D0);
  NoclipButtonPressed:=   (cave + $3D8);
  MReleaser:=PByte        (cave + $3F0);
  MenuPosX:=Pointer       (cave + $500);
  MenuPosY:=Pointer       (cave + $504);
  Dragging:=Pointer       (cave + $508);
  MouseXOri:=Pointer      (cave + $50C);
  MouseYOri:=Pointer      (cave + $510);
  EnableESP:=PByte        (cave + $600);
  EnableAimbot:=PByte     (cave + $604);
  EnableLockAim:=PByte    (cave + $608);
  EnableNoclipping:=PByte (cave + $60C);
  EnableTATY:=PByte       (cave + $610);
  EnableFlagSteal:=PByte  (cave + $614);
  }

implementation

end.

