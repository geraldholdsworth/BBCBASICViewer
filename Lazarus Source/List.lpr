program List;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}
 cthreads,
 {$ENDIF}
 Classes,BBCBasicDetokeniser
 { you can add units after this };

var
 Index     : Integer;
 LContainer: TBBCBasicDetokeniser;
 HTMLout   : Boolean;

begin
 if ParamCount>0 then
 begin
  LContainer:=TBBCBasicDetokeniser.Create;
  if LContainer.LoadFile(ParamStr(1)) then
  begin
   if(LContainer.IsBasicFile)
   or(LContainer.IsTextFile)then
   begin
    LContainer.DecodeBasicFile;
    if ParamCount<3 then
     if LContainer.FormattedText.Count>0 then
      for Index:=0 to LContainer.FormattedText.Count-1 do
       WriteLn(LContainer.FormattedText.Strings[Index]);
    HTMLOut:=False;
    if ParamCount>3 then
     if ParamStr(4)='html' then HTMLout:=True;
    if ParamCount>2 then
     if ParamStr(2)='to' then
      if HTMLOut then LContainer.HTML.SaveToFile(ParamStr(3))
                 else LContainer.Text.SaveToFile(ParamStr(3));
   end;
  end
  else WriteLn(ParamStr(1),' not found');
  LContainer.Free;
 end;
end.

