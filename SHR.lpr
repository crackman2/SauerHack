library SHReloaded;

{$mode objfpc}{$H+}

uses
  Classes, Swapbuffershook, Main, CPlayer, Aimbot, FunctionCaller, CESP,
  DrawText, CNoclip, CustomTypes, cmenumain, ccontroldrawer, cmenuwindow,
  CFlagStealer, cmemoryallocator, cavepointer
  { you can add units after this };







{ ------------------- SauerHack Reloaded  ------------------- }
{ -> Aims to be more tidy and more better in general and with }
{    waaay more readable code. And more features. Because     }
{    Sauerbraten is the easiest game in the world when it     }
{    Comes to hacking                                         }



begin
     HookSwapBuffers();
end.

