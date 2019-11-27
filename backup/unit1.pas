unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Windows;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnInit: TButton;
    LogBox: TListBox;
    TimerFly: TTimer;
    procedure btnInitClick(Sender: TObject);
    procedure CheckBoxFlyChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LogBoxClick(Sender: TObject);
    procedure TimerFlyTimer(Sender: TObject);
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

  Velocity: single = 3.0;
  BoostVelocity:Single=0;

  FirstFly: boolean = True;
  EnableFly: boolean = False;

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
      BoostVelocity:=3*Velocity;
  end
  else
  begin
      BoostVelocity:=Velocity;
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
      posx := posx + (cos((camx + 90) / 57.2958) * BoostVelocity) * (1.57079576-(abs((camy / 57.2958))));
      posy := posy + (sin((camx + 90) / 57.2958) * BoostVelocity) * (1.57079576-(abs((camy / 57.2958))));
      posz := posz + (sin((camy / 57.2958)) * BoostVelocity);
    end;

    if (GetAsyncKeyState(VK_S) <> 0) then
    begin
      posx := posx + (cos((camx - 90) / 57.2958) * BoostVelocity) * (1.57079576-(abs((camy / 57.2958))));
      posy := posy + (sin((camx - 90) / 57.2958) * BoostVelocity) * (1.57079576-(abs((camy / 57.2958))));
      posz := posz - (sin((camy / 57.2958)) * BoostVelocity);
    end;

    if (GetAsyncKeyState(VK_A) <> 0) then
    begin
      posx := posx + (cos((camx) / 57.2958) * BoostVelocity);
      posy := posy + (sin((camx) / 57.2958) * BoostVelocity);
    end;

    if (GetAsyncKeyState(VK_D) <> 0) then
    begin
      posx := posx + (cos((camx+180) / 57.2958) * BoostVelocity);
      posy := posy + (sin((camx+180) / 57.2958) * BoostVelocity);
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
    WriteByte($1434F94, $90); //Disable function which sets POSZ
    WriteByte($1434F95, $90);
    WriteByte($1434F96, $90);

    WriteByte($3D4F8E, $90); //Disable Posx
    WriteByte($3D4F8F, $90);
    WriteByte($3D4F90, $90);

    WriteByte($3D4F91, $90); //Disable Posy
    WriteByte($3D4F92, $90);
    WriteByte($3D4F93, $90);

    WriteByte($3D4F94, $90); //Disable Posz again
    WriteByte($3D4F95, $90);
    WriteByte($3D4F96, $90);




   // WriteByte($462649, $90); //Disable falling physics
   // WriteByte($46264A, $90);      //BROKEN
   // WriteByte($46264B, $90);
    Log('maybe entering loop');

  end;

  if (GetAsyncKeyState(VK_V) <> 0) and EnableFly then
  begin
    Log('Flying disabled');
    EnableFly := False;
    WriteByte($1434F94, $89); //enable function which sets POSZ
    WriteByte($1434F95, $46);
    WriteByte($1434F96, $38);

    WriteByte($3D4F8E, $89); //Disable Posx
    WriteByte($3D4F8F, $4E);
    WriteByte($3D4F90, $30);

    WriteByte($3D4F91, $89); //Disable Posy
    WriteByte($3D4F92, $56);
    WriteByte($3D4F93, $34);

    WriteByte($3D4F94, $89); //Disable Posz again
    WriteByte($3D4F95, $46);
    WriteByte($3D4F96, $38);

    WriteByte($462649, $D9); //enable falling physics
    WriteByte($46264A, $5F);        //BROKEN
    WriteByte($46264B, $20);
    while (GetAsyncKeyState(VK_V) <> 0) do
    begin
      Sleep(50);
    end;
  end;

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
    ReadProcessMemory(hProcess, Pointer($320000 + $1E6C20), @Base,
      SizeOf(addposx), nil);
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

procedure TForm1.CheckBoxFlyChange(Sender: TObject);
begin
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Form1.btnInitClick(nil);
end;

end.




