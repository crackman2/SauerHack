unit CustomTypes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

{ --- Custom Types --- }
{ -> commonly used     }
{    types should get  }
{    their own unit    }

type
  RVec3 = record
    x:Single;
    y:Single;
    z:Single;
  end;
  PRVec3 = ^RVec3;
  RVec2i = record
    x:Integer;
    y:Integer
  end;
  MVPmatrix = array[0..15] of single;
   RVec4 = record
    x:single;
    y:single;
    z:single;
    w:single;
  end;
  RVec2 = record
    x:single;
    y:single;
  end;

implementation

end.

