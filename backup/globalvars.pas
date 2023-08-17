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
  g_EnableDebug:Byte;
  g_DebugButtonPressed:Byte;


  { -------------------------- Checkboxes for Menu ------------------------- }
  { -> The numbered entires correspond to the ingame menu that is drawn      }
  { -> There is probably a much smarter way to do this rather than definign  }
  {    global variables                                                      }
  g_EnableMenu: PByte = nil; //Pointer to in-game value

  g_EnableESP:Byte;          //0
  g_EnableAimbot:Byte;       //1
  g_EnableLockAim:Byte;      //2
  g_EnableNoclipping:Byte;   //3
  g_EnableTATY:Byte;         //4
  g_EnableFlagSteal:Byte;    //5
  g_EnableTriggerbot:Byte;   //6


  g_MenuInitialSetup:Byte=0; //used to initilize the variables above once... the dumb way
  g_MenuPointers:array of Pointer; //used to store pointers for the vars above


  g_pCounter:Cardinal;

implementation

end.

