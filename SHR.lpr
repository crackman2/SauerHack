library SHReloaded;

{$mode objfpc}{$H+}

uses
  Classes, Swapbuffershook, Main, CPlayer, CAimbot, cfunctioncaller, CESP,
  DrawText, CNoclip, CustomTypes, cmenumain, ccontroldrawer, cmenuwindow,
  CFlagStealer, GlobalVars, GlobalObjects, GlobalOffsets;

{ --------------------------- SauerHack Reloaded  -------------------------- }
{ -> Aims to be more tidy and more better in general and with waaay more     }
{    readable code. And more features. Because Sauerbraten is the easiest    }
{    game in the world when it comes to hacking                              }
{ -> This section here is the entry point upon injection.                    }

{$R *.res}

begin
     HookSwapBuffers();
end.

