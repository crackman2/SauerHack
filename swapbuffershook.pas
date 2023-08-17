unit Swapbuffershook;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, gl,
  { my stuff }
  Main, GlobalVars, GlobalObjects, GlobalOffsets, CPlayer, CAimbot, CESP, CTeleportAllEnemiesToYou, CNoclip, CMenuMain,
  CFlagStealer;
var
  SBuffers:DWORD;

type
  ARRByte = array[0..3] of byte;

procedure HookSwapBuffers();stdcall;
procedure WriteJump(J_FROM: DWORD; J_TO: DWORD; J0C1: boolean); stdcall;
procedure CreateRenderingContext(); stdcall;
procedure CodeCaveCodeASM(); stdcall;
procedure InitGlobalObjects(); stdcall;

implementation

procedure HookSwapBuffers();stdcall;
var
  CodeCave:Pointer;
  SBuffers:DWORD;
  Garbage :DWORD;
  ErrorMsg:string;

  OriginalCode: array[0..4] of byte = ($8B,$FF,$55,$8B,$EC);
  i: cardinal;

begin
  { -------------------------------- CodeCave ------------------------------ }
  { -> This is the origin of the CodeCave. It is also used a lot to store    }
  {    variables used in the MainFunc such as values that must remain for    }
  {    each frame ,such as menu settings and options                         }
  { -> the pointers are easily visible as being defined as cave + <offset>   }
  {    where cave is defined below (32 bytes) after my function call to give }
  {    some room to work with                                                }
  { -> originally it used to be an actual code cave I found in opengl32.dll  }
  {    but now I just allocate some memory                                   }
  CodeCave:=AllocMem(8192);
  SBuffers:=DWORD(GetProcAddress(GetModuleHandle('opengl32.dll'),'wglSwapBuffers'));

  if (VirtualProtect(CodeCave,8192,PAGE_EXECUTE_READWRITE,@Garbage)) then begin
      VirtualProtect(Pointer(SBuffers),5,PAGE_EXECUTE_READWRITE,@Garbage);
      g_cave:=Pointer(DWORD(CodeCave) + 32); { setup cave pointer     }
      g_HDC:=0;                          { setup device context   }
      g_NewRC:=0;                        { setup rendering context}


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

      InitGlobalObjects();
  end
  else begin
      ErrorMsg := SysErrorMessage(GetLastError);
      MessageBox(0,PChar('ERROR All is lost. Cave at: ' + IntToHex(DWORD(CodeCave),8)),PChar('oh no'),0);
      MessageBox(0,PChar('ErrorMsg:' + ErrorMsg),'e',0);
  end;

end;

{  ------------------------------ Jump Writer ------------------------------ }
{  -> Jump offsets are calculated using a simple formula                     }
{        JumpOffset = Jump_to - Jump_from                                    }
{     so if the jump is written at 0x100 and we want to                      }
{     jump to 0x150 the offset will be 0x50. in x86 the code would look like }
{        E9 50000000                                                         }
{     look out for edianness.                                                }
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


{ -------------------------- CreateRenderingContext ------------------------ }
{ -> used to generate our own rendering context to draw on                   }
{ -> the result is stored in caveNewRC which is located in                   }
{    cavepointer.pas (global variable)                                       }
{ -> this can then be switched to before drawing calls in MainFunc           }
procedure CreateRenderingContext(); stdcall;
begin
    if g_HDC <> 0  then
    begin
      if g_NewRC = 0 then begin
          g_NewRC:= wglCreateContext(HDC(g_HDC));
          if g_NewRC = 0 then
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

{ ----------------------------- CodeCaveCodeASM ---------------------------- }
{ -> Grabs the handle to the device context (the parameter that swapbuffers  }
{    was called with) and stores it in caveHDC                               }
{ -> HDC is used to created the OpenGL rendering context                     }
{ -> caveHDC in cavepointer.pas (global variable)                            }
procedure CodeCaveCodeASM(); stdcall;
begin
  {$ASMMODE intel}
  asm
     mov eax, [esp + $30] //grabs HDC from Stack
     mov g_HDC, eax     //and stores it
  end;
     CreateRenderingContext();
     MainFunc();
end;

{ ---------------------------- InitGlobalObjects --------------------------- }
{ -> GlobalVars unit contains Objects that need to be initialized            }
{ -> We should only need to do it once, so we do it here                     }
procedure InitGlobalObjects(); stdcall;
var
  CheckBoxStrings:array of String;
  MaxStringLength, i:Cardinal;
begin
  g_offset_SauerbratenBase := GetModuleHandle('sauerbraten.exe');

  g_Player:= TPlayer.Create(0);
  g_Aimer := TAimbot.Create(g_Player);
  g_ESP   := TESP.Create(g_Player);
  g_TATY  := TTeleAETY.Create(g_Player);
  g_FlagStealer:= TFlagStealer.Create(g_Player);
  g_Noclip:= TNoclip.Create();


  { ---------------------- Initial Values for Pointers --------------------- }
  { -> mostly used for the TMenu object, so that's why it's here             }
  g_EnableAimbot := 1;
  g_EnableTriggerbot:=1;
  g_EnableESP := 1;
  g_EnableNoclipping := 1;
  g_EnableLockAim := 1;
  g_EnableMenu := PByte(g_offset_SauerbratenBase + g_offset_MenuState);
  //uptodate 09/08/2023
  g_MenuInitialSetup := 1;

  SetLength(g_MenuPointers, 8);
  SetLength(CheckBoxStrings, 8);

  CheckBoxStrings[0]:='Enable ESP';
  CheckBoxStrings[1]:='Enable Aimbot';
  CheckBoxStrings[2]:='Enable Lockaim';
  CheckBoxStrings[3]:='Enable Noclipping';
  CheckBoxStrings[4]:='Enable Teleport all to you';
  CheckBoxStrings[5]:='Enable autocapture flag';
  CheckBoxStrings[6]:='Enable Triggerbot';
  CheckBoxStrings[7]:='Enable FrameShot (requires lockaim)';


  g_MenuPointers[0] := @g_EnableESP;
  g_MenuPointers[1] := @g_EnableAimbot;
  g_MenuPointers[2] := @g_EnableLockAim;
  g_MenuPointers[3] := @g_EnableNoclipping;
  g_MenuPointers[4] := @g_EnableTATY;
  g_MenuPointers[5] := @g_EnableFlagSteal;
  g_MenuPointers[6] := @g_EnableTriggerbot;
  g_MenuPointers[7] := @g_EnableFrameShot;

  MaxStringLength:=0;

  for i:=0 to High(CheckBoxStrings) do begin
    if MaxStringLength < Length(CheckBoxStrings[i]) then MaxStringLength:= Length(CheckBoxStrings[i]);
  end;

  g_Menu  := TMenu.Create(0, 0, 15 + MaxStringLength * 5, 8 * Length(g_MenuPointers), 'SauerHack Reloaded', 2.5, g_MenuPointers, CheckBoxStrings);


end;

end.

