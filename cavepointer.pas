unit cavepointer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, gl, glu, windows;
var
  { --------- cave pointer  -------- }
  { -> main code cave pointer        }
  { -> value set during hook setup   }
  { -> cave starts right after the   }
  {    jump back to wglSwapbuffers   }
  cave:Pointer;
  caveHDC:HDC;
  caveNewRC:HGLRC;

implementation

end.

