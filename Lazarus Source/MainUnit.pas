unit MainUnit;

{
BBC BASIC File Viewer V1.04 written by Gerald Holdsworth
This was originally written just to get the code written to detokenise BASIC
files for Disc Image Manager.

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

interface

uses
 Classes,SysUtils,Forms,Controls,Graphics,Dialogs,StdCtrls,ExtCtrls,Buttons,
 ComCtrls,IpHtml,StrUtils,BBCBasicDetokeniser,GJHCustomComponents;

type

 { TMainForm }

 TMainForm = class(TForm)
  Memo1      : TIpHtmlPanel;
  StatusBar1 : TStatusBar;
  Panel1     : TPanel;
  btnSaveText: TButton;
  btnSaveHTML: TButton;
  SaveFile   : TSaveDialog;
  btnConfig  : TButton;
  cbHeaders  : TCheckBox;
  cbFooters  : TCheckBox;
  cbLNSpace  : TCheckBox;
  procedure btnConfigClick(Sender: TObject);
  procedure btnSaveHTMLClick(Sender: TObject);
  procedure btnSaveTextClick(Sender: TObject);
  procedure cbFootersChange(Sender: TObject);
  procedure cbHeadersChange(Sender: TObject);
  procedure cbLNSpaceChange(Sender: TObject);
  procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  procedure FormCreate(Sender: TObject);
  procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
  procedure FormShow(Sender: TObject);
  procedure ShowFile;
 private
  regkey : TGJHRegistry;
  const
   AppName = 'BBC BASIC File Viewer';
   AppVers = 'V1.04';
 public
  FDetokeniser: TBBCBasicDetokeniser;
 end;

var
 MainForm: TMainForm;

implementation

uses StyleUnit;

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormDropFiles(Sender:TObject;const FileNames:array of String);
begin
 if FDetokeniser.LoadFile(FileNames[0])then
  if(FDetokeniser.IsBasicFile)
  or(FDetokeniser.IsTextFile)then
  begin
   ShowFile;
   StatusBar1.Panels[0].Text:=FDetokeniser.BasicVersion;
   StatusBar1.Panels[1].Text:=FileNames[0];
   btnSaveText.Enabled      :=True;
   btnSaveHTML.Enabled      :=True;
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
 Left  :=RegKey.GetRegValI('PositionLeft',Left);
 Top   :=RegKey.GetRegValI('PositionTop' ,Top);
 Width :=RegKey.GetRegValI('SizeWidth'   ,Width);
 Height:=RegKey.GetRegValI('SizeHeight'  ,Height);
end;

procedure TMainForm.ShowFile;
var
 Index: Integer;
 fs   : TStringStream;
 pHTML: TIpHtml;
begin
 FDetokeniser.DecodeBasicFile;
 if FDetokeniser.HTML.Count>0 then
 begin
  fs:=TStringStream.Create;
  for Index:=0 to FDetokeniser.HTML.Count-1 do
   fs.WriteString(FDetokeniser.HTML.Strings[Index]);
  pHTML      :=TIpHtml.Create;
  fs.Position:=0;
  pHTML.LoadFromStream(fs);
  fs.Free;
  Memo1.SetHtml(pHTML);
 end;
end;

procedure TMainForm.btnSaveTextClick(Sender: TObject);
begin
 SaveFile.DefaultExt:='txt';
 SaveFile.Title     :='Save as text file';
 SaveFile.FileName  :=FDetokeniser.Filename;
 if SaveFile.Execute then FDetokeniser.Text.SaveToFile(SaveFile.Filename);
end;

procedure TMainForm.cbFootersChange(Sender: TObject);
begin
 FDetokeniser.IncludeFooter:=cbFooters.Checked;
 RegKey.SetRegValB('IncludeFooter',FDetokeniser.IncludeFooter);
 if FDetokeniser.IsFileLoaded then ShowFile;
end;

procedure TMainForm.cbHeadersChange(Sender: TObject);
begin
 FDetokeniser.IncludeHeader:=cbHeaders.Checked;
 RegKey.SetRegValB('IncludeHeader',FDetokeniser.IncludeHeader);
 if FDetokeniser.IsFileLoaded then ShowFile;
end;

procedure TMainForm.cbLNSpaceChange(Sender: TObject);
begin
 FDetokeniser.SpaceAfterLine:=cbLNSpace.Checked;
 RegKey.SetRegValB('SpaceAfterLine',FDetokeniser.SpaceAfterLine);
 if FDetokeniser.IsFileLoaded then ShowFile;
end;

procedure TMainForm.btnSaveHTMLClick(Sender: TObject);
begin
 SaveFile.DefaultExt:='html';
 SaveFile.Title     :='Save as HTML file';
 SaveFile.FileName  :=FDetokeniser.Filename;
 if SaveFile.Execute then FDetokeniser.HTML.SaveToFile(SaveFile.Filename);
end;

procedure TMainForm.btnConfigClick(Sender: TObject);
var
 LKeywordStyle  : TListStyle=();
 LLineNumStyle  : TListStyle=();
 LQuoteStyle    : TListStyle=();
 LCommentStyle  : TListStyle=();
 LSubHeaderStyle: TListStyle=();
 LHeaderStyle   : TListStyle=();
 LFooterStyle   : TListStyle=();
 LHTMLFgStyle   : TListStyle=();
 LHTMLBgColour  : TColor=clBlack;
begin
 StyleForm.DontChangeBox           :=True;
 LKeywordStyle                     :=FDetokeniser.KeywordStyle;
 StyleForm.KWColour.Selected       :=FDetokeniser.KeywordStyle.Colour;
 StyleForm.KWBold.Checked          :=FDetokeniser.KeywordStyle.Bold;
 StyleForm.KWItalic.Checked        :=FDetokeniser.KeywordStyle.Italic;
 LLineNumStyle                     :=FDetokeniser.LineNumStyle;
 StyleForm.LNColour.Selected       :=FDetokeniser.LineNumStyle.Colour;
 StyleForm.LNBold.Checked          :=FDetokeniser.LineNumStyle.Bold;
 StyleForm.LNItalic.Checked        :=FDetokeniser.LineNumStyle.Italic;
 LQuoteStyle                       :=FDetokeniser.QuoteStyle;
 StyleForm.QuColour.Selected       :=FDetokeniser.QuoteStyle.Colour;
 StyleForm.QuBold.Checked          :=FDetokeniser.QuoteStyle.Bold;
 StyleForm.QuItalic.Checked        :=FDetokeniser.QuoteStyle.Italic;
 LCommentStyle                     :=FDetokeniser.CommentStyle;
 StyleForm.CommentColour.Selected  :=FDetokeniser.CommentStyle.Colour;
 StyleForm.CommentBold.Checked     :=FDetokeniser.CommentStyle.Bold;
 StyleForm.CommentItalic.Checked   :=FDetokeniser.CommentStyle.Italic;
 LFooterStyle                      :=FDetokeniser.FooterStyle;
 StyleForm.FooterColour.Selected   :=FDetokeniser.FooterStyle.Colour;
 StyleForm.FooterBold.Checked      :=FDetokeniser.FooterStyle.Bold;
 StyleForm.FooterItalic.Checked    :=FDetokeniser.FooterStyle.Italic;
 LSubHeaderStyle                   :=FDetokeniser.SubHeaderStyle;
 StyleForm.SubHeaderColour.Selected:=FDetokeniser.SubHeaderStyle.Colour;
 StyleForm.SubHeaderBold.Checked   :=FDetokeniser.SubHeaderStyle.Bold;
 StyleForm.SubHeaderItalic.Checked :=FDetokeniser.SubHeaderStyle.Italic;
 LHeaderStyle                      :=FDetokeniser.HeaderStyle;
 StyleForm.HeaderColour.Selected   :=FDetokeniser.HeaderStyle.Colour;
 StyleForm.HeaderBold.Checked      :=FDetokeniser.HeaderStyle.Bold;
 StyleForm.HeaderItalic.Checked    :=FDetokeniser.HeaderStyle.Italic;
 LHTMLFgStyle                      :=FDetokeniser.HTMLFgStyle;
 StyleForm.HTMLFgColour.Selected   :=FDetokeniser.HTMLFgStyle.Colour;
 StyleForm.HTMLFgBold.Checked      :=FDetokeniser.HTMLFgStyle.Bold;
 StyleForm.HTMLFgItalic.Checked    :=FDetokeniser.HTMLFgStyle.Italic;
 LHTMLBgColour                     :=FDetokeniser.HTMLBgColour;
 StyleForm.HTMLBgColour.Selected   :=FDetokeniser.HTMLBgColour;
 StyleForm.DontChangeBox           :=False;
 StyleForm.ShowModal;
 if StyleForm.ModalResult=mrOK then
 begin
  RegKey.SetRegValI('KeywordColour'  ,FDetokeniser.KeywordStyle.Colour);
  RegKey.SetRegValB('KeywordBold'    ,FDetokeniser.KeywordStyle.Bold);
  RegKey.SetRegValB('KeywordItalic'  ,FDetokeniser.KeywordStyle.Italic);
  RegKey.SetRegValI('LineNumColour'  ,FDetokeniser.LineNumStyle.Colour);
  RegKey.SetRegValB('LineNumBold'    ,FDetokeniser.LineNumStyle.Bold);
  RegKey.SetRegValB('LineNumItalic'  ,FDetokeniser.LineNumStyle.Italic);
  RegKey.SetRegValI('QuoteColour'    ,FDetokeniser.QuoteStyle.Colour);
  RegKey.SetRegValB('QuoteBold'      ,FDetokeniser.QuoteStyle.Bold);
  RegKey.SetRegValB('QuoteItalic'    ,FDetokeniser.QuoteStyle.Italic);
  RegKey.SetRegValI('CommentColour'  ,FDetokeniser.CommentStyle.Colour);
  RegKey.SetRegValB('CommentBold'    ,FDetokeniser.CommentStyle.Bold);
  RegKey.SetRegValB('CommentItalic'  ,FDetokeniser.CommentStyle.Italic);
  RegKey.SetRegValI('FooterColour'   ,FDetokeniser.FooterStyle.Colour);
  RegKey.SetRegValB('FooterBold'     ,FDetokeniser.FooterStyle.Bold);
  RegKey.SetRegValB('FooterItalic'   ,FDetokeniser.FooterStyle.Italic);
  RegKey.SetRegValI('SubHeaderColour',FDetokeniser.SubHeaderStyle.Colour);
  RegKey.SetRegValB('SubHeaderBold'  ,FDetokeniser.SubHeaderStyle.Bold);
  RegKey.SetRegValB('SubHeaderItalic',FDetokeniser.SubHeaderStyle.Italic);
  RegKey.SetRegValI('HeaderColour'   ,FDetokeniser.HeaderStyle.Colour);
  RegKey.SetRegValB('HeaderBold'     ,FDetokeniser.HeaderStyle.Bold);
  RegKey.SetRegValB('HeaderItalic'   ,FDetokeniser.HeaderStyle.Italic);
  RegKey.SetRegValI('HTMLFgColour'   ,FDetokeniser.HTMLFgStyle.Colour);
  RegKey.SetRegValB('HTMLFgBold'     ,FDetokeniser.HTMLFgStyle.Bold);
  RegKey.SetRegValB('HTMLFgItalic'   ,FDetokeniser.HTMLFgStyle.Italic);
  RegKey.SetRegValI('HTMLBgColour'   ,FDetokeniser.HTMLBgColour);
 end;
 if StyleForm.ModalResult=mrCancel then
 begin
  FDetokeniser.KeywordStyle  :=LKeywordStyle;
  FDetokeniser.LineNumStyle  :=LLineNumStyle;
  FDetokeniser.QuoteStyle    :=LQuoteStyle;
  FDetokeniser.CommentStyle  :=LCommentStyle;
  FDetokeniser.FooterStyle   :=LFooterStyle;
  FDetokeniser.SubHeaderStyle:=LSubHeaderStyle;
  FDetokeniser.HeaderStyle   :=LHeaderStyle;
  FDetokeniser.HTMLFgStyle   :=LHTMLFgStyle;
  FDetokeniser.HTMLBgColour  :=LHTMLBgColour;
  if FDetokeniser.IsFileLoaded then ShowFile;
 end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
 RegKey                         :=TGJHRegistry.Create('\Software\GJH Software\'+AppName);
 FDetokeniser                   :=TBBCBasicDetokeniser.Create;
 FDetokeniser.IncludeHeader     :=RegKey.GetRegValB('IncludeHeader' ,DefIncludeHeader);
 FDetokeniser.IncludeFooter     :=RegKey.GetRegValB('IncludeFooter' ,DefIncludeFooter);
 FDetokeniser.SpaceAfterLine    :=RegKey.GetRegValB('SpaceAfterLine',DefSpaceAfterLine);
 FDetokeniser.KeywordStyle      :=AssignStyle(RegKey.GetRegValI('KeywordColour'  ,DefKeywordStyle.Colour)
                                             ,RegKey.GetRegValB('KeywordBold'    ,DefKeywordStyle.Bold)
                                             ,RegKey.GetRegValB('KeywordItalic'  ,DefKeywordStyle.Italic));
 FDetokeniser.LineNumStyle      :=AssignStyle(RegKey.GetRegValI('LineNumColour'  ,DefLineNumStyle.Colour)
                                             ,RegKey.GetRegValB('LineNumBold'    ,DefLineNumStyle.Bold)
                                             ,RegKey.GetRegValB('LineNumItalic'  ,DefLineNumStyle.Italic));
 FDetokeniser.QuoteStyle        :=AssignStyle(RegKey.GetRegValI('QuoteColour'    ,DefQuoteStyle.Colour)
                                             ,RegKey.GetRegValB('QuoteBold'      ,DefQuoteStyle.Bold)
                                             ,RegKey.GetRegValB('QuoteItalic'    ,DefQuoteStyle.Italic));
 FDetokeniser.CommentStyle      :=AssignStyle(RegKey.GetRegValI('CommentColour'  ,DefCommentStyle.Colour)
                                             ,RegKey.GetRegValB('CommentBold'    ,DefCommentStyle.Bold)
                                             ,RegKey.GetRegValB('CommentItalic'  ,DefCommentStyle.Italic));
 FDetokeniser.FooterStyle       :=AssignStyle(RegKey.GetRegValI('FooterColour'   ,DefFooterStyle.Colour)
                                             ,RegKey.GetRegValB('FooterBold'     ,DefFooterStyle.Bold)
                                             ,RegKey.GetRegValB('FooterItalic'   ,DefFooterStyle.Italic));
 FDetokeniser.SubHeaderStyle    :=AssignStyle(RegKey.GetRegValI('SubHeaderColour',DefSubHeaderStyle.Colour)
                                             ,RegKey.GetRegValB('SubHeaderBold'  ,DefSubHeaderStyle.Bold)
                                             ,RegKey.GetRegValB('SubHeaderItalic',DefSubHeaderStyle.Italic));
 FDetokeniser.HeaderStyle       :=AssignStyle(RegKey.GetRegValI('HeaderColour'   ,DefHeaderStyle.Colour)
                                             ,RegKey.GetRegValB('HeaderBold'     ,DefHeaderStyle.Bold)
                                             ,RegKey.GetRegValB('HeaderItalic'   ,DefHeaderStyle.Italic));
 FDetokeniser.HTMLFgStyle       :=AssignStyle(RegKey.GetRegValI('HTMLFgColour'   ,DefHTMLFgStyle.Colour)
                                             ,RegKey.GetRegValB('HTMLFgBold'     ,DefHTMLFgStyle.Bold)
                                             ,RegKey.GetRegValB('HTMLFgItalic'   ,DefHTMLFgStyle.Italic));
 FDetokeniser.HTMLBgColour      :=RegKey.GetRegValI('HTMLBgColour',DefHTMLBgColour);
 Caption                        :=AppName+' '+AppVers;
 FDetokeniser.ApplicationName   :=AppName;
 FDetokeniser.ApplicationVersion:=AppVers;
 cbHeaders.Checked              :=FDetokeniser.IncludeHeader;
 cbFooters.Checked              :=FDetokeniser.IncludeFooter;
 cbLNSpace.Checked              :=FDetokeniser.SpaceAfterLine;
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
 RegKey.SetRegValI('PositionTop' ,Top);
 RegKey.SetRegValI('PositionLeft',Left);
 RegKey.SetRegValI('SizeWidth'   ,Width);
 RegKey.SetRegValI('SizeHeight'  ,Height);
 RegKey.Free;
 FDetokeniser.Free;
end;

end.

