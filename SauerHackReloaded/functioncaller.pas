unit FunctionCaller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,windows;

type
  TPrintf = procedure (PMsg:PChar);stdcall;
  PTPrintf = ^TPrintf;

  { TFuncCall }

  TFuncCall = class
    Constructor Create;
    public
      dbglog:TPrintf;

  end;

implementation

{ TFuncCall }

constructor TFuncCall.Create;
var Sauerbase:Pointer;
begin
  Sauerbase:=Pointer(GetModuleHandle('sauerbraten.exe') + $2C0B0);
  dbglog:=TPrintf(Sauerbase);
end;

end.

