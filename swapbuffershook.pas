unit Swapbuffershook;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, gl,
  { my stuff }
  Main, cavepointer;
var
  SBuffers:DWORD;

type
  ARRByte = array[0..3] of byte;

procedure HookSwapBuffers();stdcall;
//procedure WriteCodeCave(Location: DWORD; addMyFunc: DWORD; JumpBackTo: DWORD); stdcall;
procedure WriteJump(J_FROM: DWORD; J_TO: DWORD; J0C1: boolean); stdcall;
procedure CreateRenderingContext(); stdcall;
procedure CodeCaveCodeASM(); stdcall;

implementation

procedure HookSwapBuffers();stdcall;
var
  CodeCave:Pointer;
  SBuffers:DWORD;
  Garbage :DWORD;
  ErrorMsg:string;

  JumpToCodeCaveOffset:DWORD=0;
  JumpToSwapBuffersOffset:DWORD=0;

  OriginalCode: array[0..4] of byte = ($8B,$FF,$55,$8B,$EC);
  i: cardinal;

begin
  { ------------------------ CodeCave ----------------------- }
  { -> This is the origin of the CodeCave. It is also used a  }
  {    lot to store variables used in the MainFunc such as    }
  {    values that must remain for each frame ,such as menu   }
  {    settings and options                                   }
  { -> the pointers are easily visible as being defined as    }
  {    cave + <offset> where cave is defined below (32 bytes) }
  {    after my function call to give some room to work with  }
  CodeCave:=AllocMem(8192);
  SBuffers:=DWORD(GetProcAddress(GetModuleHandle('opengl32.dll'),'wglSwapBuffers'));

  if (VirtualProtect(CodeCave,8192,PAGE_EXECUTE_READWRITE,@Garbage)) then begin
      VirtualProtect(Pointer(SBuffers),5,PAGE_EXECUTE_READWRITE,@Garbage);
      cave:=Pointer(DWORD(CodeCave) + 32); { setup cave pointer     }
      caveHDC:=0;                          { setup device context   }
      caveNewRC:=0;                        { setup rendering context}


      WriteJump(SBuffers,DWORD(CodeCave), False);
      PBYTE(CodeCave + 00)^:=$60; //pushad
      PBYTE(CodeCave + 01)^:=$9C; //pushfd
      WriteJump(DWORD(CodeCave + 02),DWORD(@CodeCaveCodeASM),True);   // + 5 bytes
      PBYTE(CodeCave + 07)^:=$9D; //popfd
      PBYTE(CodeCave + 08)^:=$61; //popad

      for i := 0 to 4 do  //write original code
      begin
        PBYTE(CodeCave + 09 + i)^ := OriginalCode[i];
      end;

      WriteJump(DWORD(CodeCave)+14,SBuffers+5,False);

      MessageBox(0,PChar('SUCCESS Cave at: ' + IntToHex(DWORD(CodeCave),8)),PChar('oh yes'),0);
  end else begin
      ErrorMsg := SysErrorMessage(GetLastError);
      MessageBox(0,PChar('ERROR All is lost. Cave at: ' + IntToHex(DWORD(CodeCave),8)),PChar('oh no'),0);
      MessageBox(0,PChar('ErrorMsg:' + ErrorMsg),'e',0);
  end;

end;

{  -------------------- Jump Writer -------------------- }
{  -> Jump offsets are calculated using a simple formula }
{     JumpOffset = Jump_to - Jump_from                   }
{     so if the jump is written at 0x100 and we want to  }
{     jump to 0x150 the offset will be 0x50.             }
{     in x86 the code would looks like E9 50000000       }
{     look out for edianness.                            }
procedure WriteJump(J_FROM: DWORD; J_TO: DWORD; J0C1: boolean); stdcall;
var
  JCode: DWORD;
  FinalCode: ARRBYTE = (0, 0, 0, 0);
  PWriter: PBYTE;
  i: cardinal;
begin
  JCode := J_TO - J_FROM - $5;
  FinalCode := ARRBYTE(JCode);

  PWriter := PBYTE(J_FROM);
  if J0C1 then
    PWriter^ := $E8 //CALL
  else
    PWriter^ := $E9; //JMP

  for i := 0 to 3 do
  begin
    PWriter := PBYTE(J_FROM + 1 + i);
    PWriter^ := FinalCode[i];
  end;
end;


{ ----------------- CreateRenderingContext ---------------- }
{ -> used to generate our own rendering context to draw on  }
{ -> the result is stored in caveNewRC which is located in  }
{    cavepointer.pas (global variable)                      }
{ -> this can then be switched to before drawing calls in   }
{    MainFunc                                               }
procedure CreateRenderingContext(); stdcall;
begin
    if caveHDC <> 0  then
    begin
      if caveNewRC = 0 then begin
          caveNewRC:= wglCreateContext(HDC(caveHDC));
          if caveNewRC = 0 then
          begin
              MessageBox(0,'wglCreateContext did not work','Error',0);
          end;
        end;
    end
    else
    begin
      MessageBox(0,'DC (found on the stack) is 0 for some reason','Error while creating context',0);
    end;
end;

{ -------------------- CodeCaveCodeASM -------------------- }
{ -> Grabs the handle to the device context (the parameter  }
{    that swapbuffers was called with) and stores it in     }
{    caveHDC                                                }
{ -> HDC is used to created the OpenGL rendering context    }
{ -> caveHDC in cavepointer.pas (global variable)           }
procedure CodeCaveCodeASM(); stdcall;
begin
  {$ASMMODE intel}
  asm
     mov eax, [esp + $30] //grabs HDC
     mov caveHDC, eax
  end;
     CreateRenderingContext(); //create rendering context from HDC
     MainFunc();               //call main fucntion
end;

end.

