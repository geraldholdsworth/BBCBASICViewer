unit BBCBasicDetokeniser;

{
TBBCBasicDetokeniser class V1.01 written by Gerald Holdsworth
Class to detokenise and list BBC BASIC files in HTML/Formatted text/plain text

Copyright (C) 2026 Gerald Holdsworth gerald@hollypops.co.uk

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

{$mode ObjFPC}{$H+}

interface

uses
 Classes, SysUtils,{$IFDEF LCL} Graphics,{$ENDIF} StrUtils;

{$M+}

type
 {$IFNDEF LCL}
 TColor=Cardinal;
 {$ENDIF}
 //Style type
 TListStyle = record
  Bold  : Boolean;   //If False this gets ignored
  Italic: Boolean;   //If False this gets ignored
  Colour: TColor;    //If set to clNone or clDefault, this gets ignored
  Size  : String;    //Only valid for HTML - if blank, it gets ignored
 end;
 //Because you can't assign to the individual styles, but can to the entire set
 function AssignStyle(LC: TColor;LBold,LItalic: Boolean;LSize: String=''): TListStyle;
type
 //Class definition
 TBBCBasicDetokeniser = class
  private
   FKeywordStyle: TListStyle;
   FLineNumStyle: TListStyle;
   FQuoteStyle  : TListStyle;
   FHTMLBgColour: TColor;
   FHTMLFgStyle : TListStyle;
   FHeaderStyle : TListStyle;
   FSubHdrStyle : TListStyle;
   FFooterStyle : TListStyle;
   FCommentStyle: TListStyle;
   FFilename    : String;
   FBuffer      : array of Byte;
   FLength      : Cardinal;
   FHTMLOutput  : TStringList;
   FTextOutput  : TStringList;
   FFormOutput  : TStringList;
   FBasicVer    : Byte;
   FSpcLineNum  : Boolean;
   FAppName     : String;
   FAppVersion  : String;
   FIncludeHdr  : Boolean;
   FIncludeFtr  : Boolean;
   function FileLoaded: Boolean;
  published
   //Returns a string with the minimum Basic version
   function BasicVersion: String;
   //Creates the class
   constructor Create;
   //Decodes the file. Needs to have something loaded.
   procedure DecodeBasicFile;
   //Returns true if BBC BASIC. Needs to have something loaded.
   function IsBasicFile: Boolean;
   //Returns true if Text. Needs to have something loaded.
   function IsTextFile: Boolean;
   //Loads a file into memory. Returns True on success
   function LoadFile(LFilename: String): Boolean;
   //Allows customisation of the application name
   property ApplicationName   : String      read FAppName      write FAppName;
   //Allows customisation of the application version
   property ApplicationVersion: String      read FAppVersion   write FAppVersion;
   //Filename of the loaded file (read only)
   property Filename          : String      read FFilename;
   //Container for the formatted text (read only)
   property FormattedText     : TStringList read FFormOutput;
   //Container for the HTML (read only)
   property HTML              : TStringList read FHTMLOutput;
   //HTML Background colour
   property HTMLBgColour      : TColor      read FHTMLBgColour write FHTMLBgColour;
   //Returns true if a file is currently loaded (read only)
   property IsFileLoaded      : Boolean     read FileLoaded;
   //Flag to indicate if footers should be included in the output
   property IncludeFooter     : Boolean     read FIncludeFtr   write FIncludeFtr;
   //Flag to indicate if headers should be included in the output
   property IncludeHeader     : Boolean     read FIncludeHdr   write FIncludeHdr;
   //Flag to indicate if a space should appear after the line number
   property SpaceAfterLine    : Boolean     read FSpcLineNum   write FSpcLineNum;
   //Container for the plain text (read only)
   property Text              : TStringList read FTextOutput;
  public
   //Destructor for the class
   destructor Destroy; override;
   //Style properties
   //Comments (all text after 'REM')
   property CommentStyle      : TListStyle  read FCommentStyle write FCommentStyle;
   //Footer (HTML Bold has no effect)
   property FooterStyle       : TListStyle  read FFooterStyle  write FFooterStyle;
   //Header (HTML Bold has no effect)
   property HeaderStyle       : TListStyle  read FHeaderStyle  write FHeaderStyle;
   //HTML Foreground (bold and italic override others)
   property HTMLFgStyle       : TListStyle  read FHTMLFgStyle  write FHTMLFgStyle;
   //Keywords
   property KeywordStyle      : TListStyle  read FKeywordStyle write FKeywordStyle;
   //Line numbers
   property LineNumStyle      : TListStyle  read FLineNumStyle write FLineNumStyle;
   //Quotes (strings)
   property QuoteStyle        : TListStyle  read FQuoteStyle   write FQuoteStyle;
   //Sub Header (HTML Bold has no effect)
   property SubHeaderStyle    : TListStyle  read FSubHdrStyle  write FSubHdrStyle;
 end;
 const
 {$IFNDEF LCL}
  //Taken from the Graphics unit - reproduced here as this unit is not available
  //when not used in GUI
  clBlack     =$000000;
  clMaroon    =$000080;
  clGreen     =$008000;
  clOlive     =$008080;
  clNavy      =$800000;
  clPurple    =$800080;
  clTeal      =$808000;
  clGray      =$808080;
  clSilver    =$C0C0C0;
  clRed       =$0000FF;
  clLime      =$00FF00;
  clYellow    =$00FFFF;
  clBlue      =$FF0000;
  clFuchsia   =$FF00FF;
  clAqua      =$FFFF00;
  clLtGray    =$C0C0C0;
  clDkGray    =$808080;
  clWhite     =$FFFFFF;
  clMoneyGreen=$C0DCC0;
  clSkyBlue   =$F0CAA6;
  clCream     =$F0FBFF;
  clMedGray   =$A4A0A0;
  clNone      =$1FFFFFFF;
  clDefault   =$20000000;
 {$ENDIF}
  //Default settings
  DefApplicationName   = 'BBC BASIC Lister';
  DefApplicationVersion= 'V1.01';
  DefCommentStyle      : TListStyle=(Bold:False;Italic:True ;Colour:clSilver;Size:'');
  DefFooterStyle       : TListStyle=(Bold:True ;Italic:False;Colour:clAqua  ;Size:'');
  DefHeaderStyle       : TListStyle=(Bold:True ;Italic:False;Colour:clBlue  ;Size:'');
  DefHTMLFgStyle       : TListStyle=(Bold:False;Italic:False;Colour:clWhite ;Size:'');
  DefHTMLBgColour      = clBlack;
  DefIncludeHeader     = True;
  DefIncludeFooter     = True;
  DefKeywordStyle      : TListStyle=(Bold:True ;Italic:False;Colour:clYellow;Size:'');
  DefLineNumStyle      : TListStyle=(Bold:False;Italic:False;Colour:clLime  ;Size:'');
  DefQuoteStyle        : TListStyle=(Bold:False;Italic:False;Colour:clAqua  ;Size:'');
  DefSpaceAfterLine    = False;
  DefSubHeaderStyle    : TListStyle=(Bold:True ;Italic:False;Colour:clRed   ;Size:'');

implementation

{-------------------------------------------------------------------------------
Because you can't assign to the individual styles, but can to the entire set
-------------------------------------------------------------------------------}
function AssignStyle(LC: TColor;LBold, LItalic: Boolean;LSize: String=''): TListStyle;
begin
 Result.Colour:=LC;
 Result.Bold  :=LBold;
 Result.Italic:=LItalic;
 Result.Size  :=LSize;
end;

{-------------------------------------------------------------------------------
Class creator - initialises the global variables
-------------------------------------------------------------------------------}
constructor TBBCBasicDetokeniser.Create;
begin
 inherited Create;
 //Reset the length
 FLength             :=0;
 //Reset the buffer
 SetLength(FBuffer,0);
 //Reset the filename
 FFilename           :='';
 //Create the output containers
 FHTMLOutput         :=TStringList.Create;    //For HTML output
 FTextOutput         :=TStringList.Create;    //For plain text output
 FFormOutput         :=TStringList.Create;    //For formatted text output
 //BBC Basic Version
 FBasicVer           :=0;
 //Set the styles
 FKeywordStyle       :=DefKeywordStyle;
 FLineNumStyle       :=DefLineNumStyle;
 FQuoteStyle         :=DefQuoteStyle;
 FHTMLBgColour       :=DefHTMLBgColour;
 FHTMLFgStyle        :=DefHTMLFgStyle;
 FHeaderStyle        :=DefHeaderStyle;
 FSubHdrStyle        :=DefSubHeaderStyle;
 FFooterStyle        :=DefFooterStyle;
 FCommentStyle       :=DefCommentStyle;
 //Space after line number
 FSpcLineNum         :=DefSpaceAfterLine;
 //Application Name and Version
 FAppName            :=DefApplicationName;
 FAppVersion         :=DefApplicationVersion;
 //Whether to include a header and footer
 FIncludeHdr         :=DefIncludeHeader;
 FIncludeFtr         :=DefIncludeFooter;
end;

{-------------------------------------------------------------------------------
Class destructor - frees up anything that was created during the class
-------------------------------------------------------------------------------}
destructor TBBCBasicDetokeniser.Destroy;
begin
 FHTMLOutput.Free;
 FTextOutput.Free;
 FFormOutput.Free;
 inherited Destroy;
end;

{-------------------------------------------------------------------------------
Open the file and load into memory
-------------------------------------------------------------------------------}
function TBBCBasicDetokeniser.LoadFile(LFilename: String): Boolean;
var
 F: TFileStream;
begin
 Result:=False;
 //Make sure the file exists first
 if FileExists(LFilename) then
 begin
  try
   //Open the file
   F:=TFileStream.Create(LFilename,fmOpenRead or fmShareDenyNone);
   //Setup the buffer to receive it
   SetLength(FBuffer,F.Size);
   //And read it in
   F.Read(FBuffer[0],F.Size);
   //All OK? indicate it as such
   Result :=True;
   //Set our internal variable (this could change, but the buffer length won't)
   FLength:=Length(Fbuffer);
   //Set the filename
   FFilename:=LFilename;
   //Clear the output containers, as we haven't read it in yet
   FHTMLOutput.Clear;
   FTextOutput.Clear;
   FFormOutput.Clear;
  except
   //Oh dear - reset the flag to indicate a failure
   on Exception do Result:=False;
  end;
  //Free up the stream.
  F.Free;
 end;
end;

{-------------------------------------------------------------------------------
Returns True if there is a file loaded
-------------------------------------------------------------------------------}
function TBBCBasicDetokeniser.FileLoaded: Boolean;
begin
 Result:=FLength>0;
end;

{-------------------------------------------------------------------------------
Analysis a file to see if it is a BASIC file or not
-------------------------------------------------------------------------------}
function TBBCBasicDetokeniser.IsBasicFile: Boolean;
var
 ptr: Integer=0;
begin
 //It should start with 0x0D, then two bytes later should have a pointer to the
 //next 0x0D, all the way to the end of the file.
 Result:=False;
 if FLength=0 then FLength:=Length(Fbuffer);
 if FLength>0 then
  if Fbuffer[0]=$0D then
  begin
   Result:=True;
   ptr:=0;
   // $0D is followed by two byte line number, then the line length
   while(ptr+3<FLength)and(Result)do
   begin
    // $FF marks the end of file, which doesn't always happen at the end
    if(Fbuffer[ptr+1]=$FF)and(Fbuffer[ptr+3]<5) then
     FLength:=ptr+1 //So we truncate the file
    else
    begin
     //Move onto the next pointer
     inc(ptr,Fbuffer[ptr+3]);
     if ptr<Length(Fbuffer) then
      if Fbuffer[ptr]<>$0D then Result:=False;
    end;
   end;
  end;
end;

{-------------------------------------------------------------------------------
Analysis a file to see if it is a Text file or not
-------------------------------------------------------------------------------}
function TBBCBasicDetokeniser.IsTextFile: Boolean;
var
 ptr: Integer=0;
begin
 //We will just see if all the characters are between 32 and 126. Can also
 //permit 10 (LF), 13 (CR) and 9 (HT).
 Result:=True;
 if FLength=0 then FLength:=Length(Fbuffer);
 for ptr:=0 to FLength-1 do
  if((Fbuffer[ptr]<32)
  and(Fbuffer[ptr]<>10)
  and(Fbuffer[ptr]<>13)
  and(Fbuffer[ptr]<>9))
   or(Fbuffer[ptr]>126)then Result:=False;
end;

{-------------------------------------------------------------------------------
Detokenises into HTML, Formatted console text and plain text
-------------------------------------------------------------------------------}
procedure TBBCBasicDetokeniser.DecodeBasicFile;
 //Converts Lazarus colour to HTML colour
 function LazColToHTML(col: TColor): String;
 begin
  //Lazarus colours are BBGGRR,HTML colours are RRGGBB
  Result:=IntToHex( col     AND$FF,2)
         +IntToHex((col>> 8)AND$FF,2)
         +IntToHex((col>>16)AND$FF,2);
 end;
 //Converts a style into a CSS definition
 function StyleHTML(LStyle: TListStyle): String;
 begin
  Result:='';
  //Colour (clNone and clDefault are >$FFFFFF, so leave)
  if LStyle.Colour<=$FFFFFF then Result:='color:#'+LazColToHTML(LStyle.Colour);
  //Bold
  if LStyle.Bold            then Result:=Result+';font-weight: bold';
  //Italic
  if LStyle.Italic          then Result:=Result+';font-style: italic';
  //Size (if blank, leave as default)
  if LStyle.Size<>''        then Result:=Result+';font-size: '+LStyle.Size;
  //Ending semicolon
  if Result<>''             then Result:=Result+';';
 end;
 //Converts a style into a formatted text escape sequence
 function StyleText(LStyle: TListStyle): String;
 begin
  Result:='';
  //Colour (clNone and clDefault are >$FFFFFF, so leave)
  if LStyle.Colour<=$FFFFFF then
   Result:=#$1B'[38;2;'
          +IntToStr( LStyle.Colour     AND$FF)+';'  //R
          +IntToStr((LStyle.Colour>>8 )AND$FF)+';'  //G
          +IntToStr((LStyle.Colour>>16)AND$FF)+'m'; //B
  if LStyle.Bold   then Result:=Result+#$1B'[1m';   //Bold
  if LStyle.Italic then Result:=Result+#$1B'[3m';   //Italic
  //Size is ignored as we can't change the font size.
 end;
var
 ptr      : Integer=0;
 linenum  : Integer=0;
 linelen  : Byte=0;
 lineptr  : Byte=0;
 c        : Byte=0;
 cn       : Byte=0;
 t        : Byte=0;
 tmp      : String='';
 plaintxt : String='';
 formattxt: String='';
 htmltxt  : String='';
 detok    : Boolean=False;
 rem      : Boolean=False;
 TextKW   : String='';
 TextLN   : String='';
 TextQu   : String='';
 TextHdr  : String='';
 TextSub  : String='';
 TextFtr  : String='';
 TextRem  : String='';
const
 //$80 onwards, single token per keyword - BBC BASIC I-IV
 tokens: array[$80..$FF] of String = (
  'AND'   ,'DIV'     ,'EOR'     ,'MOD'    ,'OR'       ,'ERROR'   ,'LINE'    ,'OFF',
  'STEP'  ,'SPC'     ,'TAB('    ,'ELSE'   ,'THEN'     ,'line'    ,'OPENIN'  ,'PTR',
  'PAGE'  ,'TIME'    ,'LOMEM'   ,'HIMEM'  ,'ABS'      ,'ACS'     ,'ADVAL'   ,'ASC',
  'ASN'   ,'ATN'     ,'BGET'    ,'COS'    ,'COUNT'    ,'DEG'     ,'ERL'     ,'ERR',
  'EVAL'  ,'EXP'     ,'EXT'     ,'FALSE'  ,'FN'       ,'GET'     ,'INKEY'   ,'INSTR(',
  'INT'   ,'LEN'     ,'LN'      ,'LOG'    ,'NOT'      ,'OPENUP'  ,'OPENOUT' ,'PI',
  'POINT(','POS'     ,'RAD'     ,'RND'    ,'SGN'      ,'SIN'     ,'SQR'     ,'TAN',
  'TO'    ,'TRUE'    ,'USR'     ,'VAL'    ,'VPOS'     ,'CHR$'    ,'GET$'    ,'INKEY$',
  'LEFT$(','MID$('   ,'RIGHT$(' ,'STR$'   ,'STRING$(' ,'EOF'     ,'SUM'     ,'WHILE',
  'CASE'  ,'WHEN'    ,'OF'      ,'ENDCASE','OTHERWISE','ENDIF'   ,'ENDWHILE','PTR',
  'PAGE'  ,'TIME'    ,'LOMEM'   ,'HIMEM'  ,'SOUND'    ,'BPUT'    ,'CALL'    ,'CHAIN',
  'CLEAR' ,'CLOSE'   ,'CLG'     ,'CLS'    ,'DATA'     ,'DEF'     ,'DIM'     ,'DRAW',
  'END'   ,'ENDPROC' ,'ENVELOPE','FOR'    ,'GOSUB'    ,'GOTO'    ,'GCOL'    ,'IF',
  'INPUT' ,'LET'     ,'LOCAL'   ,'MODE'   ,'MOVE'     ,'NEXT'    ,'ON'      ,'VDU',
  'PLOT'  ,'PRINT'   ,'PROC'    ,'READ'   ,'REM'      ,'REPEAT'  ,'REPORT'  ,'RESTORE',
  'RETURN','RUN'     ,'STOP'    ,'COLOUR' ,'TRACE'    ,'UNTIL'   ,'WIDTH'   ,'OSCLI');
 //Extended tokens, $C6 then $8E onwards - BBC BASIC V & VI
 exttokens: array[$C6..$C8] of array of String = (
 ('SUM'   ,'BEAT'),
 ('APPEND','AUTO'    ,'CRUNCH'  ,'DELET'  ,'EDIT'     ,'HELP',
  'LIST'  ,'LOAD'    ,'LVAR'    ,'NEW'    ,'OLD'      ,'RENUMBER',
  'SAVE'  ,'TEXTLOAD','TEXTSAVE','TWIN'   ,'TWINO'    ,'INSTALL'),
 ('CASE'  ,'CIRCLE'  ,'FILL'    ,'ORIGIN' ,'PSET'     ,'RECT'    ,'SWAP'    ,'WHILE',
  'WAIT'  ,'MOUSE'   ,'QUIT'    ,'SYS'    ,'INSTALL'  ,'LIBRARY' ,'TINT'    ,'ELLIPSE',
  'BEATS' ,'TEMPO'   ,'VOICES'  ,'VOICE'  ,'STEREO'   ,'OVERLAY'));
 //Copyright notice for bottom of document
 copyright = 'BBC BASIC Lister (C)2026 GJH Software';
 normal    = #$1B'[0m';
begin
 //Convert the formatted text styles to console strings
 TextKW :=StyleText(FKeywordStyle);
 TextLN :=StyleText(FLineNumStyle);
 TextQu :=StyleText(FQuoteStyle);
 TextHdr:=StyleText(FHeaderStyle);
 TextSub:=StyleText(FSubHdrStyle);
 TextFtr:=StyleText(FFooterStyle);
 TextRem:=StyleText(FCommentStyle);
 //Basic version
 FBasicVer:=0; //Undefined
 //Our pointer into the file
 ptr:=0;
 //Write the HTML Header
 if(IsBasicFile)or(IsTextFile)then
 begin
  //Clear the output container and write the headers
  FHTMLOutput.Clear;
  FTextOutput.Clear;
  FFormOutput.Clear;
  //HTML Header
  FHTMLOutput.Add('<!DOCTYPE html>');
  FHTMLOutput.Add('<!-- '+FAppName+' '+FAppVersion+' -->');
  FHTMLOutput.Add('<!-- '+copyright+' -->');
  FHTMLOutput.Add('<html>');
  FHTMLOutput.Add('<head>');
  //Convert the HTML styles to a CSS style we can use
  FHTMLOutput.Add('<style type="text/css">');
  FHTMLOutput.Add('.keyword {'+StyleHTML(FKeywordStyle)+'}');
  FHTMLOutput.Add('.linenum {'+StyleHTML(FLineNumStyle)+'}');
  FHTMLOutput.Add('.quote   {'+StyleHTML(FQuoteStyle)+'}');
  FHTMLOutput.Add('.comment {'+StyleHTML(FCommentStyle)+'}');
  FHTMLOutput.Add('.footer  {font-weight: bold;font-style: italic;font-size: 50%;}');
  //Takes care of clNone and clDefault
  if FHTMLBgColour<=$FFFFFF then tmp:='background-color:#'+LazColToHTML(FHTMLBgColour);
  if tmp<>'' then tmp:=tmp+';';
  tmp:='body     {'+tmp;
  tmp:=tmp+StyleHTML(FHTMLFgStyle)+'}';
  FHTMLOutput.Add(tmp);
  FHTMLOutput.Add('h1       {'+StyleHTML(FHeaderStyle)+'margin:0px;}');
  FHTMLOutput.Add('h2       {'+StyleHTML(FSubHdrStyle)+'margin:0px;}');
  FHTMLOutput.Add('h3       {'+StyleHTML(FFooterStyle)+'margin:0px;}');
  FHTMLOutput.Add('</style>');
  //Title of the webpage
  if IsBasicFile then FHTMLOutput.Add('<title>Basic Listing</title>');
  if IsTextFile then FHTMLOutput.Add('<title>Text Output</title>');
  FHTMLOutput.Add('</head>');
  FHTMLOutput.Add('<body>');
 end;
 //Is it a BBC BASIC file?
 if IsBasicFile then
 begin
  //Are we including headers in the body?
  if FIncludeHdr then
  begin
   tmp:='Listing of '+ExtractFileName(FFilename);
   FHTMLOutput.Add('<H1>'+tmp+'</H1>');
   FHTMLOutput.Add('<H2>'+FAppName+' '+FAppVersion+'</H2>');
   FTextOutput.Add(tmp);
   FTextOutput.Add(FAppName+' '+FAppVersion);
   FFormOutput.Add(TextHdr+tmp+normal);
   FFormOutput.Add(TextSub+FAppName+' '+FAppVersion+normal);
  end;
  //BBC BASIC version
  FBasicVer:=1;
  //Continue until the end of the file
  while ptr+3<FLength do
  begin
   //Read in the line
   if Fbuffer[ptr]=$0D then
   begin
    //Line number
    linenum  :=Fbuffer[ptr+2]+Fbuffer[ptr+1]<<8;
    htmltxt  :='<span class="linenum">'
              +StringReplace(PadLeft(IntToStr(linenum),5),' ','&nbsp;',[rfReplaceAll])
              +'</span>';
    plaintxt :=PadLeft(IntToStr(linenum),5);
    formattxt:=TextLN+plaintxt+normal;
    //Space after the line number?
    if FSpcLineNum then
    begin
     htmltxt  :=htmltxt  +'&nbsp;';
     plaintxt :=plaintxt +' ';
     formattxt:=formattxt+' ';
    end;
    //Line length
    linelen:=Fbuffer[ptr+3];
    //Move our line pointer one
    lineptr:=4;
    //Whether to detokenise or not (i.e. within quotes or not)
    detok:=True;
    //Has a REM been issued?
    rem:=False;
    //While we are within bounds
    while lineptr<linelen do
    begin
     //Get the next character
     c:=Fbuffer[ptr+lineptr];
     //And move on
     inc(lineptr);
     //Is it a token?
     if(c>=Low(tokens))and(detok)then
     begin
      //Is token a REM?
      if c=$F4 then
      begin
       detok:=False;
       rem:=True;
      end;
      //Set the BASIC version
      case c of
       $AD,$FF        : FBasicVer:=2;
       $CA,$CB,$CD,$CE: FBasicVer:=5;
      end;
      tmp:='';
      //Normal token (BASIC I,II,III and IV)
      if(c<Low(exttokens))or(c>High(exttokens))then
      begin
       if(c>=Low(tokens))and(c<=High(tokens))then
        if tokens[c]<>'line' then tmp:=tokens[c]
        else
        begin //Line number
         tmp:=IntToStr(((Fbuffer[ptr+lineptr  ]XOR$54)AND$30)<< 2
                     OR((Fbuffer[ptr+lineptr  ]XOR$54)AND$03)<<14
                     OR (Fbuffer[ptr+lineptr+1]       AND$3F)
                     OR (Fbuffer[ptr+lineptr+2]       AND$3F)<< 8);
         inc(lineptr,3);
        end;
       htmltxt  :=htmltxt  +'<span class="keyword">'+tmp+'</span>';
       formattxt:=formattxt+TextKW+tmp+normal;
       plaintxt :=plaintxt +tmp;
      end
      else //Extended tokens (BASIC V)
      begin
       FBasicVer:=5;
       //Extended token number
       t:=Fbuffer[ptr+lineptr];
       //Move on
       inc(lineptr);
       //Decode the token
       if t>$8D then
       begin
        if(c>=Low(exttokens))and(c<=High(exttokens))then
         if t-$8E<=High(exttokens[c])then tmp:=exttokens[c,t-$8E];
        htmltxt  :=htmltxt  +'<span class="keyword">'+tmp+'</span>';
        formattxt:=formattxt+TextKW+tmp+normal;
        plaintxt :=plaintxt +tmp;
       end;
      end;
      //Reset c
      c:=0;
      if rem then
      begin
       htmltxt  :=htmltxt  +'<span class="comment">';
       formattxt:=formattxt+TextRem;
      end;
     end;
     //We can get control characters in BBC BASIC, but macOS can't deal with them
     if c>31 then
     begin
      if not rem then
       if(c=34)AND(detok)then
       begin
        htmltxt  :=htmltxt  +'<span class="quote">';
        formattxt:=formattxt+TextQu;
       end;
      case c of
       32: htmltxt:=htmltxt+'&nbsp;';
       34: htmltxt:=htmltxt+'&quot;';
       38: htmltxt:=htmltxt+'&amp;';
       39: htmltxt:=htmltxt+'&apos;';
       60: htmltxt:=htmltxt+'&lt;';
       62: htmltxt:=htmltxt+'&gt;';
       else htmltxt:=htmltxt+Chr(c AND$7F);
      end;
      formattxt:=formattxt+Chr(c AND$7F);
      plaintxt :=plaintxt +Chr(c AND$7F);
      if not rem then if(c=34)and(not detok)then
      begin
       htmltxt  :=htmltxt+'</span>';
       formattxt:=formattxt+normal;
      end;
      //Do not detokenise within quotes
      if(c=34)and(not rem)then detok:=not detok;
     end;
    end;
    if rem then
    begin
     htmltxt  :=htmltxt+'</span>';
     formattxt:=formattxt+normal;
    end;
    //Add the complete line to the output container
    FHTMLOutput.Add(htmltxt+'<br>');
    FTextOutput.Add(plaintxt);
    FFormOutput.Add(formattxt);
    //And move onto the next line
    inc(ptr,linelen);
   end;
  end;
  if FIncludeFtr then
  begin
   tmp:='Minimum version: '+BasicVersion;
   FHTMLOutput.Add('<H3>'+tmp+'</H3>');
   FTextOutput.Add(tmp);
   FFormOutput.Add(TextSub+tmp+normal);
  end;
 end
 else //Display as text file, if it is a text file
 if IsTextFile then
 begin
  if FIncludeHdr then
  begin
   FHTMLOutput.Add('<H1>Output of '+FFilename+'</H1>');
   FHTMLOutput.Add('<H2>'+FAppName+' '+FAppVersion+'</H2>');
  end;
  plaintxt:='';
  while ptr<FLength do
  begin
   //Read the character in
   c:=Fbuffer[ptr];
   //Move on
   inc(ptr);
   //Read the next character, if not at the end
   if ptr<FLength then cn:=Fbuffer[ptr+1] else cn:=0;
   //Can't deal with control characters on macOS
   if(c>31)and(c<127)then plaintxt:=plaintxt+chr(c);
   //New line
   if((c=$0A)and(cn<>$0D))
   or((c=$0D)and(cn<>$0A))then
   begin
    FHTMLOutput.Add(plaintxt+'<br>');
    FTextOutput.Add(plaintxt);
    FFormOutput.Add(plaintxt);
    plaintxt:='';
   end;
  end;
  //At the end, anything left then push to the output container
  if plaintxt<>'' then
  begin
   FHTMLOutput.Add(plaintxt);
   FTextOutput.Add(plaintxt);
   FFormOutput.Add(plaintxt);
  end;
 end;
 //HTML Footer
 if(IsBasicFile)or(IsTextFile)then
 begin
  if FIncludeFtr then
  begin
   FHTMLOutput.Add('<span class="footer">'
                   +StringReplace(copyright,'(C)','&copy;',[rfReplaceAll])
                   +'</span>');
   FTextOutput.Add(StringReplace(copyright,'(C)',#194#169,[rfReplaceAll]));
   FFormOutput.Add(StringReplace(copyright,'(C)',#194#169,[rfReplaceAll]));
  end;
  FHTMLOutput.Add('</body>');
  FHTMLOutput.Add('</html>');
 end;
end;

{-------------------------------------------------------------------------------
Returns the minimum Basic version as a string
-------------------------------------------------------------------------------}
function TBBCBasicDetokeniser.BasicVersion: String;
begin
 Result:='Undefined';
 if IsBasicFile then
 case FBasicVer of
  1: Result:='BBC BASIC I';  //Acorn Atom/BBC Micro
  2: Result:='BBC BASIC II'; //BBC Micro/Acorn Electron
  3: Result:='BBC BASIC III';//US BBC Micro
  4: Result:='BBC BASIC IV'; //BBC Master
  5: Result:='BBC BASIC V';  //Archimedes/RiscPC
  6: Result:='BBC BASIC VI'; //Archimedes/RiscPC
 end;
 if IsTextFile then Result:='Text File';
end;

end.

