unit GlobalVars;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, gl, glu, windows;
var
  { ------------------------------ Hook Setup ------------------------------ }
  { -> g_cave is a pointer to the newly allocated memory where the detour to }
  {    call MainFunc() lives. Previously used for storage, now it's a waste- }
  {    land of unused space                                                  }
  { -> g_HDC  is where the handle to the device context is saved. we grab it }
  {    from the stack when wglSwapBuffers is hooked. used to create our own  }
  {    rendering context                                                     }
  { -> g_NewRC is our new rendering context where all the drawing happens.   }
  {    it is created only once. afterwards we switch to it when we want to   }
  {    draw and then return to the old context when we are done. also        }
  {    created when hooking wglSwapBuffers                                   }
  g_cave:Pointer;
  g_HDC:HDC;
  g_NewRC:HGLRC;



  { --------------------------- General Settings --------------------------- }
  { -> these variables are used to store the active configuration            }
  { -> the frist sentence was a lie. there are also odd things like button   }
  {    checks                                                                }
  { -> these were originally pointers to memory in a codecave, because i had }
  {    didn't know how to store values between frames                        }
  { -> THE BEST WAY TO SOLVE THIS MESS IS TO INITIALIZE THE OBJECTS WHEN THE }
  {    HOOK IS CREATED in contrast to creating and destroying everything     }
  {    every frame. but i have yet to implement this... :(                   }
  g_LockAim:Byte;
  g_ReleasedRBM:Byte;
  g_EnableNoclip:Byte;
  g_NoclipButtonPressed:Byte;
  g_MReleaser:Byte;
  g_MenuPosX:Single;
  g_MenuPosY:Single;
  g_Dragging:Byte;
  g_MouseXOri:Single;
  g_MouseYOri:Single;
  g_EnableDebug:Byte;
  g_DebugButtonPressed:Byte;


  { -------------------------- Checkboxes for Menu ------------------------- }
  { -> The numbered entires correspond to the ingame menu that is drawn      }
  { -> There is probably a much smarter way to do this rather than definign  }
  {    global variables                                                      }
  g_EnableESP:Byte;          //0
  g_EnableAimbot:Byte;       //1
  g_EnableLockAim:Byte;      //2
  g_EnableNoclipping:Byte;   //3
  g_EnableTATY:Byte;         //4
  g_EnableFlagSteal:Byte;    //5
  g_EnableTriggerbot:Byte;

  g_MenuInitialSetup:Byte=0; //used to initilize the variables above once... the dumb way
  g_MenuPointers:array of Pointer; //used to store pointers for the vars above


  g_pCounter:Cardinal;


  { // historical values when i was even dumber than i am now
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

