program List;

{
BBC BASIC File Viewer (CLI) V1.01 written by Gerald Holdsworth
This was originally written just to get the code written to detokenise BASIC
files for Disc Image Manager. This is the CLI version.

Copyright (C) 2021-2026 Gerald Holdsworth gerald@hollypops.co.uk

This source is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public Licence as published by the Free
Software Foundation; either version 3 of the Licence, or (at your option)
any later version.

This code is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public Licence for more
details.

A copy of the GNU General Public Licence is available on the World Wide Web
at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
to the Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor,
Boston, MA 02110-1335, USA.
}

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}
 cthreads,
 {$ENDIF}
 Classes,BBCBasicDetokeniser
 { you can add units after this };

var
 Index       : Integer;
 FDetokeniser: TBBCBasicDetokeniser;
 HTMLout     : Boolean;
 DisplOut    : Boolean;
 ok          : Boolean;

begin
 if ParamCount>0 then
 begin
  FDetokeniser:=TBBCBasicDetokeniser.Create;
  FDetokeniser.ApplicationName   :='BBC BASIC File Viewer Console';
  FDetokeniser.ApplicationVersion:='V1.01';
  FDetokeniser.IncludeHeader     :=True;
  FDetokeniser.IncludeFooter     :=True;
  if FDetokeniser.LoadFile(ParamStr(1)) then
  begin
   if(FDetokeniser.IsBasicFile)
   or(FDetokeniser.IsTextFile)then
   begin
    FDetokeniser.DecodeBasicFile;
    DisplOut:=True;
    HTMLOut :=False;
    if ParamCount>2 then if ParamStr(2)='to'   then DisplOut:=False;
    if ParamCount>3 then if ParamStr(4)='html' then HTMLOut:=True;
    if DisplOut     then if FDetokeniser.FormattedText.Count>0 then
     begin
      for Index:=0 to FDetokeniser.FormattedText.Count-1 do
       WriteLn(FDetokeniser.FormattedText.Strings[Index]);
     end;
    if not DisplOut then if FDetokeniser.HTML.Count>0 then
     begin
      if HTMLOut then FDetokeniser.HTML.SaveToFile(ParamStr(3))
                 else FDetokeniser.Text.SaveToFile(ParamStr(3));
      WriteLn(#$1B'[92m Output saved to ',ParamStr(3),#$1B'[0m');
     end;
   end;
  end
  else WriteLn(ParamStr(1),' not found');
  FDetokeniser.Free;
 end;
end.

