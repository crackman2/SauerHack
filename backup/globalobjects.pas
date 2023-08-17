unit GlobalObjects;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  { my stuff }
  CPlayer, CAimbot, CESP, CTeleportAllEnemiesToYou, CNoclip, CMenuMain,
  CFlagStealer;

var
  { -------------------------------- Objects ------------------------------- }
  { -> Objects used to be created and destroyed every frame                  }
  { -> Let's not do that. Also made it hard to store any information         }
  g_Player: TPlayer;
  g_Aimer : TAimbot;
  g_ESP   : TESP;
  g_TATY  : TTeleAETY;
  g_Noclip: TNoclip;
  g_Menu  : TMenu;
  g_FlagStealer: TFlagStealer;

implementation

end.

