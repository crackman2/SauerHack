unit SHRLauncherMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Menus, ExtCtrls, Windows, JwaTlHelp32, process;

type

  { TForm1 }

  TForm1 = class(TForm)
    ButtonLaunchInject: TButton;
    ButtonInject: TButton;
    ListBoxLog: TListBox;
    MainMenuBar: TMainMenu;
    MenuItemFile: TMenuItem;
    MenuItemExit: TMenuItem;
    TimerWaiting: TTimer;
    TimerProcessLauncher: TTimer;
    procedure ButtonInjectClick(Sender: TObject);
    procedure ButtonLaunchInjectClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItemExitClick(Sender: TObject);
    procedure Log(LogText: PChar);
    function InjectDLL(const ProcessName: string; const DllPath: string): boolean;
    function GetProcessID(const ProcessName: string): DWORD;
    procedure TimerProcessLauncherTimer(Sender: TObject);
    procedure TimerWaitingTimer(Sender: TObject);
  private

  public


  end;

var
  Form1: TForm1;
  WaitCounter: integer;
  WaitCounterDefault: integer = 100;

implementation

{$R *.lfm}

{ TForm1 }


procedure TForm1.FormCreate(Sender: TObject);
begin

end;

procedure TForm1.ButtonInjectClick(Sender: TObject);

begin
  if FileExists(GetCurrentDir + '\\SHR.dll') then
  begin
    Log('SHR.dll found!');
    if InjectDLL('sauerbraten.exe', GetCurrentDir + '\\SHR.dll') then
    begin
      Log('Injection successful!');
    end
    else
    begin
      Log('Error: Injection failed!');
    end;
  end
  else
  begin
    Log('Error: SHR.dll missing');
  end;
end;

procedure TForm1.ButtonLaunchInjectClick(Sender: TObject);
begin
  if FileExists(GetCurrentDir + '\\bin\\sauerbraten.exe') then
    Log('Starting Sauerbraten');

  TimerProcessLauncher.Enabled := True;
  TimerWaiting.Enabled := True;
end;

procedure TForm1.MenuItemExitClick(Sender: TObject);
begin
  halt(0);
end;

procedure TForm1.Log(LogText: PChar);
begin
  ListBoxLog.AddItem(LogText, nil);
end;

function TForm1.InjectDLL(const ProcessName: string; const DllPath: string): boolean;
var
  ProcessID: DWORD;
  ProcessHandle: THandle;
  RemoteThread: THandle;
  BytesWritten: SIZE_T = 0;
  LoadLibraryAddr: Pointer;
  DllPathLength: DWORD;
  RemoteDllPath: Pointer;
begin
  Result := False;

  ProcessID := GetProcessID(ProcessName);
  if ProcessID = 0 then
  begin
    Log('Error: Can''t find process sauerbraten.exe');
    Exit;
  end;

  ProcessHandle := OpenProcess(PROCESS_ALL_ACCESS, False, ProcessID);
  if ProcessHandle = 0 then
  begin
    Log('Error: Can''t open proceess');
    Exit;
  end;

  LoadLibraryAddr := GetProcAddress(GetModuleHandle('kernel32.dll'), 'LoadLibraryA');
  if LoadLibraryAddr = nil then
  begin
    Log('Error: LoadLibrary failed');
    CloseHandle(ProcessHandle);
    Exit;
  end;

  DllPathLength := Length(DllPath) + 1;
  RemoteDllPath := VirtualAllocEx(ProcessHandle, nil, DllPathLength,
    MEM_COMMIT, PAGE_READWRITE);
  if RemoteDllPath = nil then
  begin
    Log('Error: VirtualAlloc failed');
    CloseHandle(ProcessHandle);
    Exit;
  end;

  if not WriteProcessMemory(ProcessHandle, RemoteDllPath, PChar(DllPath),
    DllPathLength, BytesWritten) then
  begin
    Log('Error: WriteProcessMemory failed');
    VirtualFreeEx(ProcessHandle, RemoteDllPath, 0, MEM_RELEASE);
    CloseHandle(ProcessHandle);
    Exit;
  end;

  RemoteThread := CreateRemoteThread(ProcessHandle, nil, 0, LoadLibraryAddr,
    RemoteDllPath, 0, nil);
  if RemoteThread = 0 then
  begin
    Log('Error: CreateRemoteThread failed');
    VirtualFreeEx(ProcessHandle, RemoteDllPath, 0, MEM_RELEASE);
    CloseHandle(ProcessHandle);
    Exit;
  end;

  WaitForSingleObject(RemoteThread, INFINITE);

  VirtualFreeEx(ProcessHandle, RemoteDllPath, 0, MEM_RELEASE);
  CloseHandle(RemoteThread);
  CloseHandle(ProcessHandle);

  Result := True;
end;

function TForm1.GetProcessID(const ProcessName: string): DWORD;
var
  SnapshotHandle: THandle;
  ProcessEntry: TProcessEntry32;
begin
  Result := 0;
  SnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if SnapshotHandle <> INVALID_HANDLE_VALUE then
  begin
    ProcessEntry.dwSize := SizeOf(ProcessEntry);
    if Process32First(SnapshotHandle, ProcessEntry) then
    begin
      while Process32Next(SnapshotHandle, ProcessEntry) do
      begin
        if CompareText(ProcessEntry.szExeFile, ProcessName) = 0 then
        begin
          Result := ProcessEntry.th32ProcessID;
          Break;
        end;
      end;
    end;
    CloseHandle(SnapshotHandle);
  end;
end;

procedure TForm1.TimerProcessLauncherTimer(Sender: TObject);
var
  Process: TProcess;
begin
  Process := TProcess.Create(nil);
  try
    Process.Executable := GetCurrentDir + '\\bin\\sauerbraten.exe';
    Process.Parameters.Add('-q$HOME\My Games\Sauerbraten');
    Process.Parameters.Add('-glog.txt %*');
    Process.Execute;
  finally
    Process.Free;
  end;
  TimerProcessLauncher.Enabled := False;
end;

procedure TForm1.TimerWaitingTimer(Sender: TObject);
begin
  if (WaitCounter > 0) and (GetProcessID('sauerbraten.exe') = 0) then
  begin
    Dec(WaitCounter);
  end
  else
  begin
    if GetProcessID('sauerbraten.exe') <> 0 then
    begin
      if InjectDLL('sauerbraten.exe', GetCurrentDir + '\\SHR.dll') then
      begin
        Log('Injection successful!');
      end
      else
      begin
        Log('Error: Injection failed!');
      end;
    end
    else
    begin
      Log('Error: Sauerbraten failed to start? Aborting');
    end;
    WaitCounter := WaitCounterDefault;
    TimerWaiting.Enabled := False;
  end;

  if WaitCounter <= 0 then
  begin
    Log('Error: Sauerbraten failed to start? Aborting');
    WaitCounter := WaitCounterDefault;
    TimerWaiting.Enabled := False;
  end;
end;

end.
