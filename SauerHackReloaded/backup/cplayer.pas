unit CPlayer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows;
type
  RVec3 = record
    x:Single;
    y:Single;
    z:Single;
  end;

  RVec2i = record
    x:Integer;
    y:Integer
  end;

  { TPlayer }
  { This class is for both enemies and the localplayer }

  TPlayer = class
    procedure FindPlayerPointer; stdcall;
    procedure GetPlayerData;stdcall;
    procedure SetCamera(camH:Single; camV:Single);stdcall;
    procedure CalibrateMouse;stdcall;
    constructor Create(TheIndex:Cardinal);

    public
    pos:RVec3;     //World Position
    TeamString:array[0..99] of Char;  //Team name
    TeamStringLength:Integer;
    PlayerNameString:array[0..99] of Char;
    PlayerNameStringLength:Integer;

    PlayerBase:PDWORD; //Pointer to Player
    Index:Cardinal;    //Position in EntityList (0 is localplayer)
    hp:Integer;        //Health
    ClientNumber:DWORD; //ClientNumber (CN)
    IsSpectating:Boolean;
    BaseAddress:DWORD;

    CursorPosition:RVec2i; //Cursor Position needed for PixelSearch triggerbot

  end;
  PTPlayer=^TPlayer;

implementation

{ TPlayer }

procedure TPlayer.FindPlayerPointer; stdcall;
var
  EntityList:PDWORD; //Pointer to EntityList
  List:PDWORD;       //Actual List aka Pointer to first entity (the player)
begin
  { ---------------------- Setting PlayerBase ---------------------- }
  { -> $29CD34 is the offset from sauerbraten.exe to the EntityList  }
  {    Pointer                                                       }
  { -> Index determines which entry in the list should be read       }
  EntityList:=PDWORD(GetModuleHandle('sauerbraten.exe') + $29CD34);
  List:=PDWORD(EntityList^);
  PlayerBase:=PDWORD(PDWORD(List + Index * $1)^);

  if GetAsyncKeyState(VK_P) <> 0 then
  begin
       MessageBox(0,PChar('Playerbase: 0x' + IntToHex(DWORD(PlayerBase),8)),'e',0);
  end;

end;

procedure TPlayer.GetPlayerData; stdcall;
var
  TempFloat:PSingle; //for conversion, there is maybe a better way to do this
  TeamStringPointer:PDWORD;
  TeamStringCounter:Cardinal; //for looping through chars to extract the string
  PlayerNamePointer:PDWORD;
  PlayerNameCounter:Cardinal;
begin
  FindPlayerPointer();

  if PlayerBase <> PDWORD(0) then
    begin
    { ------------------------ Read PlayerBase ----------------------- }
    { -> for debug                                                     }
    BaseAddress:=DWORD(PlayerBase);



    { ----------------------- Reading Position ----------------------- }
    { -> offsets $0, $4, $8 correspond to the players X, Y and Z       }
    {    Position                                                      }
    { -> this is the position located at the feet of the player as     }
    {    opposed to the actual camera position (specifically Z)        }
    {    but this doesn't really matter because you can't duck in this }
    {    game                                                          }
    TempFloat:=PSingle(PlayerBase + $0);
    pos.x:=TempFloat^;
    TempFloat:=PSingle(PlayerBase + $1);
    pos.y:=TempFloat^;
    TempFloat:=PSingle(PlayerBase + $2);
    pos.z:=TempFloat^;



    { -------------------------- Team String ------------------------- }
    { -> reading the Team name to differentiate between enemies and    }
    {    friends. $354 is the offset to team string                    }
    { -> cycle through all chars of the string until we hit the null   }
    {    termination                                                   }
    TeamStringPointer:=PlayerBase + round($354/4); //fuck this
    TeamStringCounter:=0;
    TeamStringLength:=0;
    while PChar(TeamStringPointer)[TeamStringCounter] <> Char(0) do
    begin
      TeamString[TeamStringCounter]:=PChar(TeamStringPointer)[TeamStringCounter];
      Inc(TeamStringCounter);
    end;
    { - Null Termination. I hope nothing important was overwritten - }
    TeamString[TeamStringCounter + 1]:= Char(0);
    TeamStringLength:=TeamStringCounter + 1;


    { -------------------------- Name String ------------------------- }
    { -> reading the playername to display on ESP                      }
    { -> cycle through all chars of the string until we hit the null   }
    {    termination                                                   }
    PlayerNamePointer:=Pointer(PlayerBase + round($250/4)); //fuck this
    PlayerNameCounter:=0;
    PlayerNameStringLength:=0;
    while PChar(PlayerNamePointer)[PlayerNameCounter] <> Char(0) do
    begin
      PlayerNameString[PlayerNameCounter]:=PChar(PlayerNamePointer)[PlayerNameCounter];
      Inc(PlayerNameCounter);
    end;
    { - Null Termination. I hope nothing important was overwritten - }
    PlayerNameString[PlayerNameCounter + 1]:= Char(0);
    PlayerNameStringLength:=PlayerNameCounter + 1;





    { ----------------------- Enemy Related Data --------------------- }
    if Index > 0 then
    begin
         { ---------- Read Health --------- }
         { -> relevant for target selection }
         { -> offset from playerbase = $15C }
         hp:=PInteger(PlayerBase + round($15C/4))^;


         { ------------ Read CN ----------- }
         { -> relevant for identification   }
         { -> offset from playerbase = $1B4 }
         ClientNumber:=PDWORD(PlayerBase + round($1B4/4))^;


         { -------- Read Spectating ------- }
         { -> relevant for target selection }
         { -> offset from playerbase = $7C }
         if PBYTE(PlayerBase + ($7C/4))^ = $5 then IsSpectating:=true;
    end; // Enemy Related Data
  end; // if Playerbase <> 0
end;

procedure TPlayer.SetCamera(camH: Single; camV: Single); stdcall;
var
  addCamH:Pointer;
  addCamV:Pointer;
  Original:Pointer;
  addPSingleCamH:PSingle;
  addPSingleCamV:PSingle;

begin
  { -------------------------- Set Camera Pointer ------------------------- }
  { -> There is a different struct for engine related settings that is not  }
  {    within the entity list. there we can set the actual camera angles    }
  {    offset $216454 is a pointer to this struct. $3C is the offset to the }
  {    horizontal camera angle and the vertical one is right next to it     }

  Original:=Pointer(GetModuleHandle('sauerbraten.exe') + $216454);
  addCamH:=Pointer(Original^) + $3C;
  addCamV:=addcamH + $4;

  addPSingleCamH:=addCamH;
  addPSingleCamV:=addCamV;
  addPSingleCamV^:=camV;
  addPSingleCamH^:=camH;
end;

procedure TPlayer.CalibrateMouse; stdcall;
var
  CurPos:POINT;
begin
  { -------------------------- Cursor Position ------------------------- }
  { -> Essentially finds the center of the game window via a very crude  }
  {    Method that requires the player to hold still while ingame in     }
  {    order to center the mouse cursor (center of crosshair)            }
  { -> the position is used for the PixelSearch triggerbot. it triggers  }
  {    when the pixel to check is the right color                        }
  GetCursorPos(CurPos);
  CursorPosition.x:=CurPos.x;
  CursorPosition.y:=CurPos.y;
end;

constructor TPlayer.Create(TheIndex: Cardinal);
begin
  { ----- Set Index In EntityList ----- }
  { -> 0 is localplayer                 }
  Index:=TheIndex;

  { ---------- Init Variables --------- }
  IsSpectating:=False;
end;

end.

