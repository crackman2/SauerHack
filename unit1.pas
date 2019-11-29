unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls,  jwapsapi,MouseAndKeyInput,LCLType,
  Windows;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnInit: TButton;
    LogBox: TListBox;
    Triggerbot: TTimer;
    TimerFly: TTimer;
    procedure btnInitClick(Sender: TObject);
    procedure CheckBoxFlyChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LogBoxClick(Sender: TObject);
    procedure TimerFlyTimer(Sender: TObject);
    procedure TriggerbotTimer(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;
  posx: single;
  posy: single;
  posz: single;
  camx: single;
  camy: single;

  addposx: DWORD;
  addposy: DWORD;
  addposz: DWORD;
  addcamx: DWORD;
  addcamy: DWORD;
  addwepdelay:DWORD;

  Velocity: single = 3.0;
  BoostVelocity: single = 0;

  FirstFly: boolean = True;
  EnableFly: boolean = False;

  MouseX: integer = 0;
  MouseY: integer = 0;
  TriggerEnabled:Boolean = False;

  hProcess: HANDLE = 0;
  ProcId: DWORD = 0;
  hWindow: HWND;

implementation


{$R *.lfm}

{ TForm1 }

procedure Log(Msg: string);
begin
  Form1.LogBox.Items.Add(Msg);
  Form1.LogBox.ItemIndex := Form1.Logbox.Items.Count - 1;
end;

function ReadFloat(Address: DWORD): single;
begin
  ReadProcessMemory(hProcess, Pointer(Address), @Result, sizeof(Result), nil);
end;

procedure WriteFloat(Address: DWORD; Value: single);
begin
  WriteProcessMemory(hProcess, Pointer(Address), @Value, sizeof(Value), nil);
end;

procedure WriteByte(Address: DWORD; Value: byte);
begin
  WriteProcessMemory(hProcess, Pointer(Address), @Value, sizeof(Value), nil);
end;

procedure TForm1.LogBoxClick(Sender: TObject);
begin

end;

procedure TForm1.TimerFlyTimer(Sender: TObject);

begin
  if (GetAsyncKeyState(VK_LSHIFT) <> 0) then
  begin
    BoostVelocity := 3 * Velocity;
  end
  else
  begin
    BoostVelocity := Velocity;
  end;

  if EnableFly then
  begin
    if FirstFly then
    begin
      posx := ReadFloat(addposx);
      posy := ReadFloat(addposy);
      posz := ReadFloat(addposz);
      FirstFly := False;
    end;
    camx := ReadFloat(addcamx);
    camy := ReadFloat(addcamy);

    if (GetAsyncKeyState(VK_W) <> 0) then
    begin
      posx := posx + (cos((camx + 90) / 57.2958) * BoostVelocity) *
        (1.57079576 - (abs((camy / 57.2958))));
      posy := posy + (sin((camx + 90) / 57.2958) * BoostVelocity) *
        (1.57079576 - (abs((camy / 57.2958))));
      posz := posz + (sin((camy / 57.2958)) * BoostVelocity);
    end;

    if (GetAsyncKeyState(VK_S) <> 0) then
    begin
      posx := posx + (cos((camx - 90) / 57.2958) * BoostVelocity) *
        (1.57079576 - (abs((camy / 57.2958))));
      posy := posy + (sin((camx - 90) / 57.2958) * BoostVelocity) *
        (1.57079576 - (abs((camy / 57.2958))));
      posz := posz - (sin((camy / 57.2958)) * BoostVelocity);
    end;

    if (GetAsyncKeyState(VK_A) <> 0) then
    begin
      posx := posx + (cos((camx) / 57.2958) * BoostVelocity);
      posy := posy + (sin((camx) / 57.2958) * BoostVelocity);
    end;

    if (GetAsyncKeyState(VK_D) <> 0) then
    begin
      posx := posx + (cos((camx + 180) / 57.2958) * BoostVelocity);
      posy := posy + (sin((camx + 180) / 57.2958) * BoostVelocity);
    end;


    if (GetAsyncKeyState(VK_SPACE) <> 0) then
    begin
      posz := posz + BoostVelocity;
    end;

    if (GetAsyncKeyState(VK_LCONTROL) <> 0) then
    begin
      posz := posz - BoostVelocity;
    end;


    WriteFloat(addposx, posx);
    WriteFloat(addposy, posy);
    WriteFloat(addposz, posz);
  end;


  if (GetAsyncKeyState(VK_V) <> 0) and not EnableFly then
  begin
    while (GetAsyncKeyState(VK_V) <> 0) do
    begin
      Sleep(50);
    end;
    Log('Flying enabled');
    FirstFly := True;
    EnableFly := True;
    WriteByte($4188DD, $90); //Disable Posx and Posy
    WriteByte($4188DE, $90);
    WriteByte($4188DF, $90);
    WriteByte($4188E0, $90);
    WriteByte($4188E1, $90);

    //  WriteByte($3D4F8E, $90); //Disable Posx
    //  WriteByte($3D4F8F, $90);
    //  WriteByte($3D4F90, $90);

    // WriteByte($3D4F91, $90); //Disable Posy
    // WriteByte($3D4F92, $90);
    // WriteByte($3D4F93, $90);

    WriteByte($4188E2, $90); //Disable Posz again
    WriteByte($4188E3, $90);
    WriteByte($4188E4, $90);




    // WriteByte($462649, $90); //Disable falling physics
    // WriteByte($46264A, $90);      //BROKEN
    // WriteByte($46264B, $90);

  end;

  if (GetAsyncKeyState(VK_V) <> 0) and EnableFly then
  begin
    Log('Flying disabled');
    EnableFly := False;
    WriteByte($4188DD, $66); //Disable Posx and Posy
    WriteByte($4188DE, $0F);
    WriteByte($4188DF, $D6);
    WriteByte($4188E0, $46);
    WriteByte($4188E1, $30);

    // WriteByte($3D4F8E, $89); //Disable Posx
    // WriteByte($3D4F8F, $4E);
    // WriteByte($3D4F90, $30);

    // WriteByte($3D4F91, $89); //Disable Posy
    // WriteByte($3D4F92, $56);
    // WriteByte($3D4F93, $34);

    WriteByte($4188E2, $89); //Disable Posz again
    WriteByte($4188E3, $46);
    WriteByte($4188E4, $38);

    // WriteByte($462649, $D9); //enable falling physics
    //WriteByte($46264A, $5F);        //BROKEN
    //WriteByte($46264B, $20);
    while (GetAsyncKeyState(VK_V) <> 0) do
    begin
      Sleep(50);
    end;
  end;

end;

procedure TForm1.TriggerbotTimer(Sender: TObject);
var foo:Integer=0;
    Delay:Integer=0;
begin
   if (GetAsyncKeyState(VK_X) <> 0) then
  begin
    if TriggerEnabled then
    begin
          Log('Triggerbot disabled!');
          TriggerEnabled:=false;
    end
    else
    begin
         Log('Triggerbot enabled!');
         TriggerEnabled:=true;
    end;


    while (GetAsyncKeyState(VK_X) <> 0) do
    begin
      Sleep(200);
    end;
  end;

  if (GetAsyncKeyState(VK_P) <> 0) then
  begin
    MouseX := Mouse.CursorPos.x;
    MouseY := Mouse.CursorPos.y;
    Log('Saved mouse position for triggerbot');
    Log('MouseX: ' + IntToStr(MouseX));
    Log('MouseY: ' + IntToStr(MouseY));
    while (GetAsyncKeyState(VK_P) <> 0) do
    begin
      Sleep(200);
    end;
  end;
  ReadProcessMemory(hProcess,Pointer(addwepdelay),@Delay,sizeof(delay),nil);//Check weapon delay

  {
  if (GetAsyncKeyState(VK_L) <> 0)then
  begin
      mouse_event(MOUSEEVENTF_ABSOLUTE or
      MOUSEEVENTF_LEFTDOWN,Mouse.CursorPos.x,Mouse.CursorPos.y,0,0);

      mouse_event(MOUSEEVENTF_ABSOLUTE or
      MOUSEEVENTF_LEFTUP,MouseX,MouseY,0,0);
  end;
  }

  if TriggerEnabled  and (Delay = 0) then
    begin
       foo:=GetPixel(GetDC(0),MouseX,MouseY);
       //Log(IntToHex(foo,6));
       if(foo = $02FF00)then
         begin
               //MouseInput.Click(mbLeft,[]);
               //SendMessage(hwnd_outra_win,WM_LBUTTONDOWN,MK_LBUTTON,MAKELPARAM(pos_cursor.x,pos_cursor.y));
               //SendMessage(hwnd_outra_win,WM_LBUTTONUP,MK_LBUTTON,MAKELPARAM(pos_cursor.x,pos_cursor.y));

               SendMessage(hWindow,WM_LBUTTONDOWN,MK_LBUTTON,MAKELPARAM(MouseX,MouseY));
               Sleep(10);
               SendMessage(hWindow,WM_LBUTTONUP,MK_LBUTTON,MAKELPARAM(MouseX,MouseY));


                Log('Click!');
         end;
    end;
end;

function GetModuleBaseAddress(ProcessID: cardinal; MName: string): Pointer;
var
  Modules: array of HMODULE;
  cbNeeded, i: cardinal;
  ModuleInfo: TModuleInfo;
  ModuleName: array[0..MAX_PATH] of char;
  PHandle: THandle;
begin
  Result := nil;
  SetLength(Modules, 1024);
  PHandle := OpenProcess(PROCESS_QUERY_INFORMATION + PROCESS_VM_READ,
    False, ProcessID);
  if (PHandle <> 0) then
  begin
    EnumProcessModules(PHandle, @Modules[0], 1024 * SizeOf(HMODULE), cbNeeded);
    //Getting the enumeration of modules
    SetLength(Modules, cbNeeded div SizeOf(HMODULE)); //Setting the number of modules
    for i := 0 to Length(Modules) - 1 do //Start the loop
    begin
      GetModuleBaseName(PHandle, Modules[i], ModuleName, SizeOf(ModuleName));
      //Getting the name of module
      if AnsiCompareText(MName, ModuleName) = 0 then
        //If the module name matches with the name of module we are looking for...
      begin
        GetModuleInformation(PHandle, Modules[i], ModuleInfo, SizeOf(ModuleInfo));
        //Get the information of module
        Result := ModuleInfo.lpBaseOfDll;
        //Return the information we want (The image base address)
        CloseHandle(PHandle);
        Exit;
      end;
    end;
  end;
end;




procedure TForm1.btnInitClick(Sender: TObject);
var

  Base: DWORD;
  EXEBase: DWORD;
begin
  Log('Initializing...');
  hWindow := FindWindow(nil, 'Cube 2: Sauerbraten');
  Log('Window Handle: ' + IntToStr(hWindow));
  GetWindowThreadProcessId(hWindow, @ProcId);
  Log('Process ID: ' + IntToStr(ProcID));
  hProcess := OpenProcess(PROCESS_ALL_ACCESS, False, ProcId);
  if (hProcess <> 0) then
  begin
    Log('Sauerbraten found!');
    EXEBase := DWORD(GetModuleBaseAddress(ProcId, 'sauerbraten.exe'));
    Log('Sauebraten.exe base address: ' + IntToHex(EXEBase, 6));
    ReadProcessMemory(hProcess, Pointer(EXEBase + $00216454), @Base,
      SizeOf(addposx), nil);
    Log('Base read: ' + IntToHex(Base, 6));
    addposx := Base + $30;
    addposy := Base + $34;
    addposz := Base + $38;
    addcamx := Base + $3C;
    addcamy := Base + $40;
    addwepdelay:= Base + $174;

    Log('Addposx: 0x' + IntToHex(addposx, 6));
    Log('Addposy: 0x' + IntToHex(addposy, 6));
    Log('Addposz: 0x' + IntToHex(addposz, 6));
    Log('Addcamx: 0x' + IntToHex(addcamx, 6));
    Log('Addcamx: 0x' + IntToHex(addcamy, 6));
    Log('Initialization done!');

  end
  else
  begin
    Log('Sauerbraten was not found!');
    Log('May require admin privileges');
  end;

end;

procedure TForm1.CheckBoxFlyChange(Sender: TObject);
begin
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Form1.btnInitClick(nil);
end;

end.
