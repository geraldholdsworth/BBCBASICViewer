unit BBCBasicDetokeniser;

{$mode ObjFPC}{$H+}

interface

uses
 Classes, SysUtils,{$IFDEF LCL} Graphics,{$ENDIF} StrUtils;

{$M+}

type
 {$IFNDEF LCL}
 TColor=Cardinal;
 {$ENDIF}
 TListStyle = record
  Bold  : Boolean;
  Italic: Boolean;
  Colour: TColor;
 end;
 TBBCBasicDetokeniser = class
  private
   FKeywordStyle: TListStyle;
   FLineNumStyle: TListStyle;
   FQuoteStyle  : TListStyle;
   FHTMLBgColour: TColor;
   FHTMLFgColour: TColor;
   FFilename    : String;
   FBuffer      : array of Byte;
   FLength      : Cardinal;
   FHTMLOutput  : TStringList;
   FTextOutput  : TStringList;
   FFormOutput  : TStringList;
   FBasicVer    : Byte;
   FSpcLineNum  : Boolean;
  published
   function BasicVersion: String;
   constructor Create;
   procedure DecodeBasicFile;
   function IsBasicFile: Boolean;
   function IsTextFile: Boolean;
   function LoadFile(LFilename: String): Boolean;
   property Filename      : String      read FFilename;
   property FileLength    : Cardinal    read FLength;
   property FormattedText : TStringList read FFormOutput;
   property HTML          : TStringList read FHTMLOutput;
   property HTMLBgColour  : TColor      read FHTMLBgColour write FHTMLBgColour;
   property HTMLFgColour  : TColor      read FHTMLFgColour write FHTMLFgColour;
   property SpaceAfterLine: Boolean     read FSpcLineNum   write FSpcLineNum;
   property Text          : TStringList read FTextOutput;
  public
   destructor Destroy; override;
   property KeywordStyle  : TListStyle  read FKeywordStyle write FKeywordStyle;
   property LineNumStyle  : TListStyle  read FLineNumStyle write FLineNumStyle;
   property QuoteStyle    : TListStyle  read FQuoteStyle   write FQuoteStyle;
 end;
 {$IFNDEF LCL}
 const
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
 {$ENDIF}

implementation

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
 //Set the styles
 FKeywordStyle.Bold  :=True;
 FKeywordStyle.Italic:=False;
 FKeywordStyle.Colour:=clYellow;
 FLineNumStyle.Bold  :=False;
 FLineNumStyle.Italic:=False;
 FLineNumStyle.Colour:=clLime;
 FQuoteStyle.Bold    :=False;
 FQuoteStyle.Italic  :=True;
 FQuoteStyle.Colour  :=clAqua;
 FHTMLBgColour       :=clBlack;
 FHTMLFgColour       :=clWhite;
 //Create the output containers
 FHTMLOutput         :=TStringList.Create;
 FTextOutput         :=TStringList.Create;
 FFormOutput         :=TStringList.Create;
 //BBC Basic Version
 FBasicVer           :=0;
 //Space after line number
 FSpcLineNum         :=True;
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
 if FileExists(LFilename) then
 begin
  FFilename:=LFilename;
  try
   F:=TFileStream.Create(LFilename,fmOpenRead or fmShareDenyNone);
   SetLength(FBuffer,F.Size);
   F.Read(FBuffer[0],F.Size);
   Result :=True;
   FLength:=Length(Fbuffer);
   FHTMLOutput.Clear;
   FTextOutput.Clear;
   FFormOutput.Clear;
  except
   on Exception do Result:=False;
  end;
   F.Free;
 end;
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
 function LazColToHTML(col: TColor): String;
 begin
  //Lazarus colours are BBGGRR
  //HTML colours are RRGGBB
  Result:=IntToHex( col     AND$FF,2)
         +IntToHex((col>> 8)AND$FF,2)
         +IntToHex((col>>16)AND$FF,2);
 end;
 function StyleHTML(LStyle: TListStyle): String;
 begin
  Result:='style="color:#'+LazColToHTML(LStyle.Colour);
  if LStyle.Bold   then Result:=Result+';font-weight: bold';
  if LStyle.Italic then Result:=Result+';font-style: italic';
  Result:=Result+'"';
 end;
 function StyleText(LStyle: TListStyle): String;
 begin
  Result:=#$1B'[38;2;'
         +IntToStr( LStyle.Colour     AND$FF)+';'  //R
         +IntToStr((LStyle.Colour>>8 )AND$FF)+';'  //G
         +IntToStr((LStyle.Colour>>16)AND$FF)+'m'; //B
  if LStyle.Bold   then Result:=Result+#$1B'[1m';
  if LStyle.Italic then Result:=Result+#$1B'[3m';
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
 HTMLKW   : String='';
 HTMLLN   : String='';
 HTMLQu   : String='';
 TextKW   : String='';
 TextLN   : String='';
 TextQu   : String='';
const
 // $80 onwards, single token per keyword
 tokens: array[0..127] of String = (
  'AND'   ,'DIV'    ,'EOR'     ,'MOD'    ,'OR'       ,'ERROR' ,'LINE'    ,'OFF',
  'STEP'  ,'SPC'    ,'TAB('    ,'ELSE'   ,'THEN'     ,'line'  ,'OPENIN'  ,'PTR',
  'PAGE'  ,'TIME'   ,'LOMEM'   ,'HIMEM'  ,'ABS'      ,'ACS'   ,'ADVAL'   ,'ASC',
  'ASN'   ,'ATN'    ,'BGET'    ,'COS'    ,'COUNT'    ,'DEG'   ,'ERL'     ,'ERR',
  'EVAL'  ,'EXP'    ,'EXT'     ,'FALSE'  ,'FN'       ,'GET'   ,'INKEY'   ,'INSTR(',
  'INT'   ,'LEN'    ,'LN'      ,'LOG'    ,'NOT'      ,'OPENUP','OPENOUT' ,'PI',
  'POINT(','POS'    ,'RAD'     ,'RND'    ,'SGN'      ,'SIN'   ,'SQR'     ,'TAN',
  'TO'    ,'TRUE'   ,'USR'     ,'VAL'    ,'VPOS'     ,'CHR$'  ,'GET$'    ,'INKEY$',
  'LEFT$(','MID$('  ,'RIGHT$(' ,'STR$'   ,'STRING$(' ,'EOF'   ,'SUM'     ,'WHILE',
  'CASE'  ,'WHEN'   ,'OF'      ,'ENDCASE','OTHERWISE','ENDIF' ,'ENDWHILE','PTR',
  'PAGE'  ,'TIME'   ,'LOMEM'   ,'HIMEM'  ,'SOUND'    ,'BPUT'  ,'CALL'    ,'CHAIN',
  'CLEAR' ,'CLOSE'  ,'CLG'     ,'CLS'    ,'DATA'     ,'DEF'   ,'DIM'     ,'DRAW',
  'END'   ,'ENDPROC','ENVELOPE','FOR'    ,'GOSUB'    ,'GOTO'  ,'GCOL'    ,'IF',
  'INPUT' ,'LET'    ,'LOCAL'   ,'MODE'   ,'MOVE'     ,'NEXT'  ,'ON'      ,'VDU',
  'PLOT'  ,'PRINT'  ,'PROC'    ,'READ'   ,'REM'      ,'REPEAT','REPORT'  ,'RESTORE',
  'RETURN','RUN'    ,'STOP'    ,'COLOUR' ,'TRACE'    ,'UNTIL' ,'WIDTH'   ,'OSCLI');
 //Extended tokens, $C6 then $8E onwards
 exttokens1: array[0..1] of String = ('SUM', 'BEAT');
 //Extended tokens, $C7 then $8E onwards
 exttokens2: array[0..17] of String = (
  'APPEND','AUTO'    ,'CRUNCH'  ,'DELET','EDIT' ,'HELP',
  'LIST'  ,'LOAD'    ,'LVAR'    ,'NEW'  ,'OLD'  ,'RENUMBER',
  'SAVE'  ,'TEXTLOAD','TEXTSAVE','TWIN' ,'TWINO','INSTALL');
 //Extended tokens, $C8 then $8E onwards
 exttokens3: array[0..21] of String = (
  'CASE' ,'CIRCLE','FILL'  ,'ORIGIN','PSET'   ,'RECT'   ,'SWAP','WHILE',
  'WAIT' ,'MOUSE' ,'QUIT'  ,'SYS'   ,'INSTALL','LIBRARY','TINT','ELLIPSE',
  'BEATS','TEMPO' ,'VOICES','VOICE' ,'STEREO' ,'OVERLAY');
begin
 HTMLKW:=StyleHTML(FKeywordStyle);
 HTMLLN:=StyleHTML(FLineNumStyle);
 HTMLQu:=StyleHTML(FQuoteStyle);
 TextKW:=StyleText(FKeywordStyle);
 TextLN:=StyleText(FLineNumStyle);
 TextQu:=StyleText(FQuoteStyle);
 FBasicVer:=0; //Undefined
 //Our pointer into the file
 ptr:=0;
 //Is it a BBC BASIC file?
 if IsBasicFile then
 begin
  //Clear the output container and write the headers
  FHTMLOutput.Clear;
  FTextOutput.Clear;
  FFormOutput.Clear;
  FHTMLOutput.Add('<html><head><title>Basic Listing</title></head>');
  tmp:='<body style="background-color:#'
      +LazColToHTML(FHTMLBgColour)+';color:#'
      +LazColToHTML(FHTMLFgColour)+'">';
  FHTMLOutput.Add(tmp);
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
    htmltxt  :='<span '+HTMLLN+'>'
              +StringReplace(PadLeft(IntToStr(linenum),5),' ','&nbsp;',[rfReplaceAll])
              +'</span>';
    plaintxt :=PadLeft(IntToStr(linenum),5);
    formattxt:=TextLN+plaintxt+#$1B'[0m';
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
     if(c>$7F)and(detok)then
     begin
      //Is token a REM?
      if c=$F4 then
      begin
       detok:=False;
       rem:=True;
      end;
      //Set the BASIC version
      if(c=$AD)or(c=$FF)                  then FBasicVer:=2;
      if(c=$CA)or(c=$CB)or(c=$CD)or(c=$CE)then FBasicVer:=5;
      tmp:='';
      //Normal token (BASIC I,II,III and IV)
      if(c<$C6)or(c>$C8)then
      begin
       if c-$80<=High(tokens) then
        if c-$80<>$D then
         tmp:=tokens[c-$80]
        else
        begin //Line number
         tmp:=IntToStr(((Fbuffer[ptr+lineptr  ]XOR$54)AND$30)<< 2
                     OR((Fbuffer[ptr+lineptr  ]XOR$54)AND$03)<<14
                     OR (Fbuffer[ptr+lineptr+1]       AND$3F)
                     OR (Fbuffer[ptr+lineptr+2]       AND$3F)<< 8);
         inc(lineptr,3);
        end;
       htmltxt  :=htmltxt  +'<span '+HTMLKW+'>'+tmp+'</span>';
       formattxt:=formattxt+TextKW+tmp+#$1B'[0m';
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
        if c=$C6 then if t-$8E<=High(exttokens1)then tmp:=exttokens1[t-$8E];
        if c=$C7 then if t-$8E<=High(exttokens2)then tmp:=exttokens2[t-$8E];
        if c=$C8 then if t-$8E<=High(exttokens3)then tmp:=exttokens3[t-$8E];
        htmltxt  :=htmltxt  +'<span '+HTMLKW+'>'+tmp+'</span>';
        formattxt:=formattxt+TextKW+tmp+#$1B'[0m';
        plaintxt :=plaintxt +tmp;
       end;
      end;
      //Reset c
      c:=0;
     end;
     //We can get control characters in BBC BASIC, but macOS can't deal with them
     if c>31 then
     begin
      if not rem then
       if(c=34)AND(detok)then
       begin
        htmltxt  :=htmltxt  +'<span '+HTMLQu+'>';
        formattxt:=formattxt+TextQu;
       end;
      if(c<>32)and(c<>38)and(c<>60)and(c<>62)then
       htmltxt:=htmltxt+Chr(c AND$7F);
      if c=32 then htmltxt:=htmltxt+'&nbsp;';
      if c=38 then htmltxt:=htmltxt+'&amp;';
      if c=60 then htmltxt:=htmltxt+'&lt;';
      if c=62 then htmltxt:=htmltxt+'&gt;';
      formattxt:=formattxt+Chr(c AND$7F);
      plaintxt :=plaintxt +Chr(c AND$7F);
      if not rem then if(c=34)and(not detok)then
      begin
       htmltxt  :=htmltxt+'</span>';
       formattxt:=formattxt+#$1B'[0m';
      end;
      //Do not detokenise within quotes
      if(c=34)and(not rem)then detok:=not detok;
     end;
    end;
    //Add the complete line to the output container
    FHTMLOutput.Add(htmltxt+'<br>');
    FTextOutput.Add(plaintxt);
    FFormOutput.Add(formattxt);
    //And move onto the next line
    inc(ptr,linelen);
   end;
  end;
  FHTMLOutput.Add('</body>');
  FHTMLOutput.Add('</html>');
 end
 else //Display as text file, if it is a text file
 if IsTextFile then
 begin
  //Clear the output container and write the headers
  FHTMLOutput.Clear;
  FTextOutput.Clear;
  FFormOutput.Clear;
  FHTMLOutput.Add('<html><head><title>Text Output</title></head>');
  tmp:='<body style="background-color:#'
      +IntToHex(FHTMLBgColour,6)+';color:#'
      +IntToHex(FHTMLFgColour,6)+'">';
  FHTMLOutput.Add(tmp);
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
   FHTMLOutput.Add(plaintxt+'<br>');
   FTextOutput.Add(plaintxt);
   FFormOutput.Add(plaintxt);
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
  1: Result:='BBC BASIC I';
  2: Result:='BBC BASIC II';
  3: Result:='BBC BASIC III';
  4: Result:='BBC BASIC IV';
  5: Result:='BBC BASIC V';
 end;
 if IsTextFile then Result:='Text File';
end;

end.

