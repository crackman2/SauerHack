library OGL;

{$mode objfpc}{$H+}

uses
  Classes, gl
  { you can add units after this };
procedure TestFunction();
var MemoryLoc:^LongInt;
begin
    MemoryLoc:=Pointer($10300);
    MemoryLoc^:=MemoryLoc^+1;

    //glClear(GL_COLOR_BUFFER_BIT);

    glBegin(GL_LINES);
    glVertex2f(10, 10);
    glVertex2f(20, 20);
    glEnd();

end;

exports
       TestFunction;


begin
end.

