unit Swapbuffershook;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows,
  { my stuff }
  Main;

type
  ARRByte = array[0..3] of byte;

procedure HookSwapBuffers();stdcall;
procedure WriteCodeCave(Location: DWORD; addMyFunc: DWORD;
  JumpBackTo: DWORD); stdcall;
procedure WriteJump(J_FROM: DWORD; J_TO: DWORD; J0C1: boolean); stdcall;

implementation

procedure HookSwapBuffers();stdcall;
var
  CodeCave:DWORD;
  SBuffers:DWORD;
  Garbage:DWORD;
begin
  CodeCave:=DWORD(GetModuleHandle('opengl32.dll') + $25521);
  SBuffers:=DWORD(GetProcAddress(GetModuleHandle('opengl32.dll'),'wglSwapBuffers'));
  VirtualProtect(Pointer(CodeCave),30,PAGE_EXECUTE_WRITECOPY,Garbage);
  VirtualProtect(Pointer(SBuffers),5,PAGE_EXECUTE_WRITECOPY,Garbage);
  WriteCodeCave(CodeCave,DWORD(@MainFunc),SBuffers + $5);
  WriteJump(SBuffers,CodeCave,False);
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


procedure WriteCodeCave(Location: DWORD; addMyFunc: DWORD;
  JumpBackTo: DWORD); stdcall;
var
  OriginalCode: array[0..4] of byte = ($8B,$FF,$55,$8B,$EC);
  i: cardinal;
begin
  PBYTE(Location + 00)^ := $60;//pushad
  PBYTE(Location + 01)^ := $9C;//pushfd
  WriteJump(Location + 02, addMyFunc, True); //call my function
  PBYTE(Location + 07)^ := $9D;//popfd
  PBYTE(Location + 08)^ := $61;//popfd
  for i := 0 to 4 do  //write original code
  begin
    PBYTE(Location + 9 + i)^ := OriginalCode[i];
  end;
  WriteJump(Location + 14, JumpBackTo, False); //jump back to hooked function
end;


end.

