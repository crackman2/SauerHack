unit GlobalOffsets;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  { ------------------------------ PlayerCount ----------------------------- }
  g_offset_SauerbratenBase:      longword = $0;


  { ------------------------------ PlayerCount ----------------------------- }
  { -> PInteger(sauerbraten.exe + $3C9AD8)^                                  }
  g_offset_PlayerCount:          longword = $3C9AD8;



  { ---------------------------------- FPS --------------------------------- }
  { -> Value of the in-game fps counter                                      }
  { -> PInteger(sauerbraten.exe + $39A644)^                                  }
  g_offset_FPS:                  longword = $39A644;



  { -------------------------- In-Game Menu State -------------------------- }
  { -> Value that is non zero when scoreboard, main menu etc. are shown      }
  { -> PByte(sauerbraten.exe + $30D0E8)^}
  g_offset_MenuState:            longword = $30D0E8;



  { ------------------------- Mouse Cursor Position ------------------------ }
  { -> Position of in-game mouse cursor                                      }
  { -> top-left values are (0,0) and bottom-right are (1,1)                  }
  { -> PSingle(sauerbraten.exe + $2A6010)^   -> X Coordinate                 }
  { -> PSingle(sauerbraten.exe + $2A601C)^   -> Y Coordinate                 }
  g_offset_MouseCursorPosX:      longword = $2A6010;
  g_offset_MouseCursorPosY:      longword = $2A600C;



  { ------------------------------ EntityList ------------------------------ }
  { -> A list of pointers that point to each player                          }
  { -> the very first one is the local player                                }
  { -> Example for calculating the address fo the writable Z coordinate      }
  {    of the local player:                                                  }
  {             ((sauerbraten.exe + $3C9AD0)^ + 0)^ + $3C                    }
  {    0 is the index (increasing by 4 for the next one) and $3C is the      }
  {    offset to point to the writable Z coordinate                          }
  g_offset_EntityList:           longword = $3C9AD0;



  { ---------------------------- Player Offsets ---------------------------- }
  { -> Offsets for a player object                                           }
  { -> R means read, W means write (which can also be read, though)          }
  { -> offsets are relative to the player's base address                     }
  g_offset_Player_PosXR:         longword = $0;   //Single
  g_offset_Player_PosYR:         longword = $4;
  g_offset_Player_PosZR:         longword = $8;

  g_offset_Player_PosXW:         longword = $30;  //Single
  g_offset_Player_PosYW:         longword = $34;
  g_offset_Player_PosZW:         longword = $38;

  g_offset_Player_VelXW:         longword = $C;   //Single
  g_offset_Player_VelYW:         longword = $10;
  g_offset_Player_VelZW:         longword = $14;

  g_offset_Player_CamXW:         longword = $3C;  //Single
  g_offset_Player_CamYW:         longword = $40;

  g_offset_Player_TeamString:    longword = $34C; //zero terminated str
  g_offset_Player_NameString:    longword = $248;

  g_offset_Player_Health:        longword = $154; //Integer
  g_offset_Player_ClientNumber:  longword = $1B4; //??? unused & incorrect
  g_offset_Player_Spectating:    longword = $77;  //Byte, is 5 when spectating



  { ------------------------------ ViewMatrix ------------------------------ }
  { -> PSingle((sauerbraten.exe + $399080)^ + index * 4)^                    }
  { -> is a 4x4 matrix used for World2Screen. Index values as shown          }
  g_offset_ViewMatrix:           longword = $399080;



  { ---------------------------------- Fog --------------------------------- }
  { -> PCardinal(sauerbraten.exe + $398EF8)^                                 }
  { -> Fog distance. Max value can be 1000024. Required for AutoTrigger      }
  g_offset_Fog:                  longword = $398EF8;



  { ------------------------------- ShootByte ------------------------------ }
  { -> PByte((sauerbraten.exe + $3C9ADC)^ + $1D8)^                           }
  { -> causes the player to shoot ingame when set to 1                       }
  g_offset_ShootByte_0:          longword = $3C9ADC;
  g_offset_ShootByte_1:          longword = $1D8;

  { ------------------------------- TeamValue ------------------------------ }
  { -> PByte(sauerbraten.exe + $2A636C)^                                     }
  { -> A Value that corresponds to a gamemode                                }
  { -> using a lookup table, it can be determined if the current gamemode is }
  {    team based                                                            }
  g_offset_TeamValue:            longword = $2A636C;

implementation

end.

