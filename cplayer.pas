unit CPlayer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows,
  CustomTypes, GlobalOffsets;

type

  { TPlayer }
  { This class is for both enemies and the localplayer }

  TPlayer = class
    constructor Create(TheIndex: cardinal);
    procedure FindPlayerPointer; stdcall;
    procedure GetPlayerData; stdcall;
    procedure SetCamera(camH: single; camV: single); stdcall;
    procedure SetPos(x: single; y: single; z: single);
    procedure SetPosAlt(x: single; y: single; z: single);
    procedure CalibrateMouse; stdcall;


  public
    pos: RVec3;//World Position
    cam: RVec2; //camera horizontal
    TeamString: array[0..99] of char;  //Team name
    TeamStringLength: integer;
    PlayerNameString: array[0..99] of char;
    PlayerNameStringLength: integer;

    { -------------------------- Pointer to Player ------------------------- }
    {-> IMPORTANT !! Pointers must be of type Pointer or else adding offsets }
    {   breaks for some reason :( Cast Type when dereferencing               }
    {   (e.g. PByte(VarHoldingPointerValue)^:=$100;)                         }
    PlayerBase: Pointer;

    Index: cardinal;     //Position in EntityList (0 is localplayer)
    hp: integer;         //Health
    ClientNumber: DWORD; //ClientNumber (CN) (unused)
    IsSpectating: boolean;
    BaseAddress:  Pointer;

    CursorPosition: RVec2i; //Cursor Position needed for PixelSearch triggerbot

  end;

  PTPlayer = ^TPlayer;

implementation

{ TPlayer }

constructor TPlayer.Create(TheIndex: cardinal);
begin
  { ------------------------ Set Index In EntityList ----------------------- }
  { -> 0 is localplayer                                                      }
  Index := TheIndex;

  { ----------------------------- Init Variables --------------------------- }
  IsSpectating := False;
end;

procedure TPlayer.FindPlayerPointer; stdcall;
var
  EntityList: Pointer; //Pointer to EntityList
  List: Pointer;       //Actual List aka Pointer to first entity (the player)
begin
  { -------------------------- Setting PlayerBase -------------------------- }
  { -> $29CD34 is the offset from sauerbraten.exe to the EntityList          }
  {    Pointer                                                               }
  { -> Index determines which entry in the list should be read               }
  EntityList := Pointer(g_offset_SauerbratenBase + g_offset_EntityList);  //uptodate 2023/08/12
  List := Pointer(EntityList^);
  PlayerBase := Pointer(Pointer(List + Index * $4)^);

end;

procedure TPlayer.GetPlayerData; stdcall;
var
  TeamStringPointer: Pointer;
  TeamStringCounter: cardinal; //for looping through chars to extract the string
  PlayerNamePointer: Pointer;
  PlayerNameCounter: cardinal;
begin
  FindPlayerPointer();

  if PlayerBase <> PDWORD(0) then
  begin
    { --------------------------- Read PlayerBase -------------------------- }
    { -> for debug                                                           }
    BaseAddress := Pointer(PlayerBase);



    { -------------------------- Reading Position -------------------------- }
    { -> offsets $0, $4, $8 correspond to the players X, Y and Z position    }
    { -> this is the position located at the feet of the player as           }
    {    opposed to the actual camera position (specifically Z)              }
    {    but this doesn't really matter because you can't duck in this game  }
    pos.x := PSingle(PlayerBase + g_offset_player_posxR)^;
    pos.y := PSingle(PlayerBase + g_offset_player_posyR)^;
    pos.z := PSingle(PlayerBase + g_offset_player_poszR)^;

    cam.x  := PSingle(PlayerBase + g_offset_player_camxW)^;
    cam.y  := PSingle(PlayerBase + g_offset_player_camyW)^;

    { ----------------------------- Team String ---------------------------- }
    { -> reading the Team name to differentiate between enemies and friends  }
    {    $354 is the offset to team string                                   }
    { -> cycle through all chars of the string until we hit the null         }
    {    termination                                                         }
    TeamStringPointer := Pointer(PlayerBase + g_offset_player_teamstring); //fuck this //uptodate 2023/08/14 old $354
    TeamStringCounter := 0;
    TeamStringLength := 0;
    while PChar(TeamStringPointer)[TeamStringCounter] <> char(0) do
    begin
      TeamString[TeamStringCounter] := PChar(TeamStringPointer)[TeamStringCounter];
      Inc(TeamStringCounter);
    end;
    { ----- Null Termination. I hope nothing important was overwritten ----- }
    TeamString[TeamStringCounter + 1] := char(0);
    TeamStringLength := TeamStringCounter + 1;


    { ----------------------------- Name String ---------------------------- }
    { -> reading the playername to display on ESP                            }
    { -> cycle through all chars of the string until we hit the null         }
    {    termination                                                         }
    PlayerNamePointer := Pointer(PlayerBase + g_offset_player_namestring); //fuck this //uptodate 2023/08/14 old $250
    PlayerNameCounter := 0;
    PlayerNameStringLength := 0;
    while PChar(PlayerNamePointer)[PlayerNameCounter] <> char(0) do
    begin
      PlayerNameString[PlayerNameCounter] := PChar(PlayerNamePointer)[PlayerNameCounter];
      Inc(PlayerNameCounter);
    end;
    { ----- Null Termination. I hope nothing important was overwritten ----- }
    PlayerNameString[PlayerNameCounter + 1] := char(0);
    PlayerNameStringLength := PlayerNameCounter + 1;



    { -------------------------- Enemy Related Data ------------------------ }
    if Index > 0 then
    begin
      { ---------------------------- Read Health --------------------------- }
      { -> relevant for target selection                                     }
      { -> offset from playerbase = $154                                    }
      hp := PInteger(PlayerBase + g_offset_player_health)^; //uptodate 2023/08/14 old $15C


      { ------------------------------ Read CN ----------------------------- }
      { -> client number                                                     }
      { -> relevant for identification                                       }
      { -> offset from playerbase = $1B4                                     }
      ClientNumber := PDWORD(PlayerBase + g_offset_player_clientnumber)^; // UNKNOWN 2023/08/14 i'll just leave it for now


      { -------------------------- Read Spectating ------------------------- }
      { -> relevant for target selection                                     }
      { -> offset from playerbase = $77                                      }
      if PBYTE(PlayerBase + g_offset_player_spectating)^ = $5 then   //uptodate 2023/08/14 old $15C
        IsSpectating := True;
    end;
  end;
end;

procedure TPlayer.SetCamera(camH: single; camV: single); stdcall;
var
  addCamH: Pointer;
  addCamV: Pointer;
  Original: Pointer;
  addPSingleCamH: PSingle;
  addPSingleCamV: PSingle;

begin
  { --------------------------- Set Camera Pointer ------------------------- }
  { -> There is a different struct for engine related settings that is not   }
  {    within the entity list. there we can set the actual camera angles     }
  {    offset $216454 is a pointer to this struct. $3C is the offset to the  }
  {    horizontal camera angle and the vertical one is right next to it      }

  Original := Pointer(g_offset_SauerbratenBase + g_offset_EntityList );  //uptodate 2023/08/12
  addCamH := PPointer(Pointer(Original^) + 0)^ + g_offset_Player_CamXW; //0 indexes the local player
  addCamV := PPointer(Pointer(Original^) + 0)^ + g_offset_Player_CamYW;

  addPSingleCamH := addCamH;
  addPSingleCamV := addCamV;
  addPSingleCamV^ := camV;
  addPSingleCamH^ := camH;
end;

procedure TPlayer.SetPos(x: single; y: single; z: single); //cant work
begin
  PSingle(PlayerBase + g_offset_Player_PosXR)^ := x;
  PSingle(PlayerBase + g_offset_Player_PosYR)^ := y;
  PSingle(PlayerBase + g_offset_Player_PosZR)^ := z;
end;

procedure TPlayer.SetPosAlt(x: single; y: single; z: single);
begin
  PSingle(PlayerBase + g_offset_Player_PosXW)^ := x;
  PSingle(PlayerBase + g_offset_Player_PosYW)^ := y;
  PSingle(PlayerBase + g_offset_Player_PosZW)^ := z;
end;

procedure TPlayer.CalibrateMouse; stdcall;
var
  CurPos: POINT;
begin
  { ---------------------------- Cursor Position --------------------------- }
  { -> Essentially finds the center of the game window via a very crude      }
  {    Method that requires the player to hold still while ingame in         }
  {    order to center the mouse cursor (center of crosshair)                }
  { -> the position is used for the PixelSearch triggerbot. it triggers      }
  {    when the pixel to check is the right color                            }
  GetCursorPos(CurPos);
  CursorPosition.x := CurPos.x;
  CursorPosition.y := CurPos.y;
end;

end.


