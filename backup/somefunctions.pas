unit SomeFunctions;

{$mode objfpc}{$H+}

interface

procedure Log(Msg:String);


uses
  Classes, SysUtils;

implementation

procedure Log(Msg:String);
begin
   LogBox.AddItem('Initializing...',nil);
   LogBox.ItemIndex:= Logbox.Items.Count-1;
end;

end.



