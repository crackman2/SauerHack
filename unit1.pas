unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Windows;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnInit: TButton;
    LogBox: TListBox;
    procedure btnInitClick(Sender: TObject);
    procedure LogBoxClick(Sender: TObject);
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

  hProcess: HANDLE = 0;
  ProcId: DWORD = 0;

implementation


{$R *.lfm}

{ TForm1 }

procedure Log(Msg: string);
begin
  Form1.LogBox.Items.Add(Msg);
  Form1.LogBox.ItemIndex := Form1.Logbox.Items.Count - 1;
end;

procedure TForm1.LogBoxClick(Sender: TObject);
begin

end;

procedure TForm1.btnInitClick(Sender: TObject);
var
  hWindow: HWND;
  Base: DWORD;
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
    ReadProcessMemory(hProcess, Pointer($1380000 + $1E6C20), @Base, SizeOf(addposx), nil);
    Log('Base read: ' + IntToHex(Base, 6));
    addposx := Base + $30;
    addposy := Base + $34;
    addposz := Base + $38;
    addcamx := Base + $3C;
    addcamy := Base + $40;

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

end.




