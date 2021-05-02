unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
 Buttons, ComCtrls, IpHtml, StrUtils;

type

 { TMainForm }

 TMainForm = class(TForm)
  Memo1: TIpHtmlPanel;
  StatusBar1: TStatusBar;
  procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
 private
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
 F       : TFileStream;
 buffer  : array of Byte;
 ptr,
 linenum : Integer;
 linelen,
 lineptr,
 c,t,
 basicver: Byte;
 linetxt : String;
 detok,
 rem,
 isbasic : Boolean;
 fs      : TStringStream;
 pHTML   : TIpHtml;
const
 keywordstyle = 'style="color:#FFFF00"';
 linenumstyle = 'style="color:#00FF00"';
 quotestyle   = 'style="color:#00FFFF"';
begin
 //Load the entire file into the buffer
 buffer:=nil;
 F:=TFileStream.Create(FileNames[0],fmOpenRead or fmShareDenyNone);
 SetLength(buffer,F.Size);
 F.Read(buffer[0],F.Size);
 F.Free;
 //First we'll analyse the data to see if it is a BBC BASIC file
 //It should start with 0x0D, then two bytes later should have a pointer to the
 //next 0x0D, all the way to the end of the file.
 isbasic:=False;
 if buffer[0]=$0D then
 begin
  isbasic:=True;
  ptr:=0;
  // $0D is followed by two byte line number, then the line length
  while(ptr+3<Length(buffer))and(isbasic)do
  begin
   // $FF marks the end of file, which doesn't always happen at the end
   if(buffer[ptr+1]=$FF)and(buffer[ptr+3]<5) then
    SetLength(buffer,ptr+1) //So we truncate the file
   else
   begin
    //Move onto the next pointer
    linenum:=ptr;
    inc(ptr,buffer[ptr+3]);
    if buffer[ptr]<>$0D then isbasic:=False;
   end;
  end;
 end;
 //Our pointer into the file
 ptr:=0;
 //Clear the output container
 //Memo1.Clear;
 fs:=TStringStream.Create('<html><head><title>Basic Listing</title></head>');
 //Update the status bar
 StatusBar1.Panels[1].Text:=Filenames[0];
 //Is it a BBC BASIC file?
 if isbasic then
 begin
  fs.WriteString('<body style="background-color:#0000FF;color:#FFFFFF;font-weight:bold">');
  //BBC BASIC version
  basicver:=1;
  //Continue until the end of the file
  while ptr+3<Length(buffer) do
  begin
   //Read in the line
   if buffer[ptr]=$0D then
   begin
    //Line number
    linenum:=buffer[ptr+2]+buffer[ptr+1]<<8;
    linetxt:='<span '+linenumstyle+'>'
            +StringReplace(PadLeft(IntToStr(linenum),5),' ','&nbsp;',[rfReplaceAll])
            +'</span>&nbsp;';
    //Line length
    linelen:=buffer[ptr+3];
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
     c:=buffer[ptr+lineptr];
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
      if(c=$AD)or(c=$FF)then basicver:=2;
      if(c=$CA)or(c=$CB)or(c=$CD)or(c=$CE)then basicver:=5;
      //Normal token (BASIC I,II,III and IV)
      if(c<$C6)or(c>$C8)then
      begin
       if c-$80<=High(tokens) then
        linetxt:=linetxt+'<span '+keywordstyle+'>'+tokens[c-$80]+'</span>';
      end
      else //Extended tokens (BASIC V)
      begin
       basicver:=5;
       //Extended token number
       t:=buffer[ptr+lineptr];
       //Move on
       inc(lineptr);
       //Decode the token
       if t>$8D then
       begin
        if c=$C6 then
         if t-$8E<=High(exttokens1)then
          linetxt:=linetxt+'<span '+keywordstyle+'>'+exttokens1[t-$8E]+'</span>';
        if c=$C7 then
         if t-$8E<=High(exttokens2)then
          linetxt:=linetxt+'<span '+keywordstyle+'>'+exttokens2[t-$8E]+'</span>';
        if c=$C8 then
         if t-$8E<=High(exttokens3)then
          linetxt:=linetxt+'<span '+keywordstyle+'>'+exttokens3[t-$8E]+'</span>';
       end;
      end;
      //Reset c
      c:=0;
     end;
     //We can get control characters in BBC BASIC, but macOS can't deal with them
     if c>31 then
     begin
      if not rem then if(c=34)AND(detok)then linetxt:=linetxt+'<span '+quotestyle+'>';
      if(c<>32)and(c<>38)and(c<>60)and(c<>62)then linetxt:=linetxt+Chr(c AND$7F);
      if c=32 then linetxt:=linetxt+'&nbsp;';
      if c=38 then linetxt:=linetxt+'&amp;';
      if c=60 then linetxt:=linetxt+'&lt;';
      if c=62 then linetxt:=linetxt+'&gt;';
      if not rem then if(c=34)and(not detok)then linetxt:=linetxt+'</span>';
      //Do not detokenise within quotes
      if(c=34)and(not rem)then detok:=not detok;
     end;
    end;
    //Add the complete line to the output container
    fs.WriteString(linetxt+'<br>');
    //Memo1.Lines.Add(linetxt);
    //And move onto the next line
    inc(ptr,linelen);
   end;
  end;
  //Update the status bar with the BASIC version detected
  StatusBar1.Panels[0].Text:='BBC BASIC '+IntToStr(basicver);
 end
 else
 begin
  //Straight forward text file
  StatusBar1.Panels[0].Text:='Text';
  fs.WriteString('<body style="background-color:#ECECEC;color:#000000";font-weight:Bold>');
  linetxt:='';
  while ptr<Length(buffer) do
  begin
   c:=buffer[ptr];
   inc(ptr);
   //Can't deal with control characters on macOS
   if(c>31)and(c<127)then linetxt:=linetxt+chr(c);
   //New line
   if c=$0A then
   begin
    StringReplace(linetxt,'&','&amp;',[rfReplaceAll]);
    StringReplace(linetxt,' ','&nbsp;',[rfReplaceAll]);
    StringReplace(linetxt,'<','&lt;',[rfReplaceAll]);
    StringReplace(linetxt,'>','&gt;',[rfReplaceAll]);
    fs.WriteString(linetxt+'<br>');
    //Memo1.Lines.Add(linetxt);
    linetxt:='';
   end;
  end;
  //At the end, anything left then push to the output container
  if linetxt<>'' then
  begin
   StringReplace(linetxt,'&','&amp;',[rfReplaceAll]);
   StringReplace(linetxt,' ','&nbsp;',[rfReplaceAll]);
   StringReplace(linetxt,'<','&lt;',[rfReplaceAll]);
   StringReplace(linetxt,'>','&gt;',[rfReplaceAll]);
   fs.WriteString(linetxt+'<br>');//Memo1.Lines.Add(linetxt);
  end;
 end;
 fs.WriteString('</body></html>');
 pHTML:=TIpHtml.Create;
 fs.Position:=0;
 pHTML.LoadFromStream(fs);
 fs.Free;
 Memo1.SetHtml(pHTML);
end;

end.

