unit StyleUnit;

{$mode ObjFPC}{$H+}

interface

uses
 Classes,SysUtils,Forms,Controls,Graphics,Dialogs,StdCtrls,ComCtrls,ExtCtrls,
 ColorBox,BBCBasicDetokeniser;

type

 { TStyleForm }

 TStyleForm = class(TForm)
  KeywordStyle     : TGroupBox;
  KWColLabel       : TLabel;
  KWColour         : TColorBox;
  KWBold           : TCheckbox;
  KWItalic         : TCheckbox;
  QuoteStyle       : TGroupBox;
  QuColLabel       : TLabel;
  QuColour         : TColorBox;
  QuBold           : TCheckbox;
  QuItalic         : TCheckbox;
  LineNumStyle     : TGroupBox;
  LNColour         : TColorBox;
  LNColLabel       : TLabel;
  LNBold           : TCheckbox;
  LNItalic         : TCheckbox;
  CommentStyle     : TGroupBox;
  CommentColLabel  : TLabel;
  CommentColour    : TColorBox;
  CommentBold      : TCheckbox;
  CommentItalic    : TCheckbox;
  FooterStyle      : TGroupBox;
  FooterColLabel   : TLabel;
  FooterColour     : TColorBox;
  FooterBold       : TCheckbox;
  FooterItalic     : TCheckbox;
  SubHeaderStyle   : TGroupBox;
  SubHeaderColLabel: TLabel;
  SubHeaderColour  : TColorBox;
  SubHeaderBold    : TCheckbox;
  SubHeaderItalic  : TCheckbox;
  HeaderStyle      : TGroupBox;
  HeaderColLabel   : TLabel;
  HeaderColour     : TColorBox;
  HeaderBold       : TCheckbox;
  HeaderItalic     : TCheckbox;
  HTMLFgStyle      : TGroupBox;
  HTMLFgColLabel   : TLabel;
  HTMLFgColour     : TColorBox;
  HTMLFgBold       : TCheckbox;
  HTMLFgItalic     : TCheckbox;
  HTMLBgStyle      : TGroupBox;
  HTMLBgColLabel   : TLabel;
  HTMLBgColour     : TColorBox;
  btnOK            : TButton;
  btnCancel        : TButton;
  procedure FormCreate(Sender: TObject);
  procedure KWBoldChange(Sender: TObject);
  procedure KWColourChange(Sender: TObject);
 private

 public
  DontChangeBox    : Boolean;
 end;

var
 StyleForm: TStyleForm;

implementation

{$R *.lfm}

uses MainUnit;

{ TStyleForm }

procedure TStyleForm.KWColourChange(Sender: TObject);
begin
 if not DontChangeBox then
 begin
  MainForm.FDetokeniser.KeywordStyle  :=AssignStyle(KWColour.Selected
                                                   ,KWBold.Checked
                                                   ,KWItalic.Checked);
  MainForm.FDetokeniser.LineNumStyle  :=AssignStyle(LNColour.Selected
                                                   ,LNBold.Checked
                                                   ,LNItalic.Checked);
  MainForm.FDetokeniser.QuoteStyle    :=AssignStyle(QuColour.Selected
                                                   ,QuBold.Checked
                                                   ,QuItalic.Checked);
  MainForm.FDetokeniser.CommentStyle  :=AssignStyle(CommentColour.Selected
                                                   ,CommentBold.Checked
                                                   ,CommentItalic.Checked);
  MainForm.FDetokeniser.FooterStyle   :=AssignStyle(FooterColour.Selected
                                                   ,FooterBold.Checked
                                                   ,FooterItalic.Checked);
  MainForm.FDetokeniser.SubHeaderStyle:=AssignStyle(SubHeaderColour.Selected
                                                   ,SubHeaderBold.Checked
                                                   ,SubHeaderItalic.Checked);
  MainForm.FDetokeniser.HeaderStyle   :=AssignStyle(HeaderColour.Selected
                                                   ,HeaderBold.Checked
                                                   ,HeaderItalic.Checked);
  MainForm.FDetokeniser.HTMLFgStyle   :=AssignStyle(HTMLFgColour.Selected
                                                   ,HTMLFgBold.Checked
                                                   ,HTMLFgItalic.Checked);
  MainForm.FDetokeniser.HTMLBgColour  :=HTMLBgColour.Selected;
  if MainForm.FDetokeniser.IsFileLoaded then MainForm.ShowFile;
 end;
end;

procedure TStyleForm.FormCreate(Sender: TObject);
begin
 DontChangeBox:=False;
end;

procedure TStyleForm.KWBoldChange(Sender: TObject);
begin
 KWColourChange(Sender);
end;

end.

