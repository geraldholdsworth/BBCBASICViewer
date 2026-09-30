unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
 Buttons, ComCtrls, IpHtml, StrUtils, BBCBasicDetokeniser;

type

 { TMainForm }

 TMainForm = class(TForm)
  Memo1: TIpHtmlPanel;
  StatusBar1: TStatusBar;
  Panel1: TPanel;
  btnSaveText: TButton;
  btnSaveHTML: TButton;
  SaveFile: TSaveDialog;
  procedure btnSaveHTMLClick(Sender: TObject);
  procedure btnSaveTextClick(Sender: TObject);
  procedure FormCreate(Sender: TObject);
  procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
 private
  LContainer: TBBCBasicDetokeniser;
 public

 end;

var
 MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormDropFiles(Sender: TObject; const FileNames: array of String
 );
var
 Index     : Integer;
 fs        : TStringStream;
 pHTML     : TIpHtml;
begin
 if LContainer.LoadFile(FileNames[0]) then
  if(LContainer.IsBasicFile)
  or(LContainer.IsTextFile)then
  begin
   LContainer.DecodeBasicFile;
   if LContainer.HTML.Count>0 then
   begin
    fs:=TStringStream.Create;
    for Index:=0 to LContainer.HTML.Count-1 do
     fs.WriteString(LContainer.HTML.Strings[Index]);
   end;
   pHTML:=TIpHtml.Create;
   fs.Position:=0;
   pHTML.LoadFromStream(fs);
   fs.Free;
   Memo1.SetHtml(pHTML);
   StatusBar1.Panels[0].Text:=LContainer.BasicVersion;
   btnSaveText.Enabled:=True;
   btnSaveHTML.Enabled:=True;
  end;
end;

procedure TMainForm.btnSaveTextClick(Sender: TObject);
begin
 SaveFile.DefaultExt:='txt';
 SaveFile.Title     :='Save as text file';
 SaveFile.FileName  :=LContainer.Filename;
 if SaveFile.Execute then LContainer.Text.SaveToFile(SaveFile.Filename);
end;

procedure TMainForm.btnSaveHTMLClick(Sender: TObject);
begin
 SaveFile.DefaultExt:='html';
 SaveFile.Title     :='Save as HTML file';
 SaveFile.FileName  :=LContainer.Filename;
 if SaveFile.Execute then LContainer.HTML.SaveToFile(SaveFile.Filename);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
 LContainer:=TBBCBasicDetokeniser.Create;
end;

end.

