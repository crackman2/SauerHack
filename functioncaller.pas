unit FunctionCaller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows;

type
  TPrintf = procedure(PMsg: PChar); stdcall;
  PTPrintf = ^TPrintf;

  { TFuncCall }
  { -> the printf thing is not functional but is a good example for }
  {    calling exported (or not exported functions from the game    }
  { -> maybe finds some use later                                   }

  TFuncCall = class
    constructor Create;
  public
    dbglog: TPrintf;

  end;

implementation

{ TFuncCall }

constructor TFuncCall.Create;
var
  Sauerbase: Pointer;
begin
  Sauerbase := Pointer(GetModuleHandle('sauerbraten.exe') + $2C0B0);
  dbglog := TPrintf(Sauerbase);
end;

end.
