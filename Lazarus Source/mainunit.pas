unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
 Buttons, StrUtils;

type

 { TMainForm }

 TMainForm = class(TForm)
  Memo1: TMemo;
  procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
 private
  const
   // $80 onwards, single token per keyword
   tokens: array[0..127] of String = ('AND','DIV','EOR','MOD','OR','ERROR','LINE','OFF','STEP','SPC','TAB(','ELSE',
                          'THEN','line','OPENIN','PTR','PAGE','TIME','LOMEM','HIMEM','ABS','ACS','ADVAL',
                          'ASC','ASN','ATN','BGET','COS','COUNT','DEG','ERL','ERR','EVAL','EXP','EXT',
                          'FALSE','FN','GET','INKEY','INSTR(','INT','LEN','LN','LOG','NOT','OPENUP',
                          'OPENOUT','PI','POINT(','POS','RAD','RND','SGN','SIN','SQR','TAN','TO','TRUE',
                          'USR','VAL','VPOS','CHR$','GET$','INKEY$','LEFT$(','MID$(','RIGHT$(','STR$',
                          'STRING$(','EOF','SUM','WHILE','CASE','WHEN','OF','ENDCASE','OTHERWISE','ENDIF',
                          'ENDWHILE','PTR','PAGE','TIME','LOMEM','HIMEM','SOUND','BPUT','CALL','CHAIN',
                          'CLEAR','CLOSE','CLG','CLS','DATA','DEF','DIM','DRAW','END','ENDPROC','ENVELOPE',
                          'FOR','GOSUB','GOTO','GCOL','IF','INPUT','LET','LOCAL','MODE','MOVE','NEXT','ON',
                          'VDU','PLOT','PRINT','PROC','READ','REM','REPEAT','REPORT','RESTORE','RETURN',
                          'RUN','STOP','COLOUR','TRACE','UNTIL','WIDTH','OSCLI');
   //Extended tokens, $C6 then $8E onwards
   exttokens1: array[0..1] of String = ('SUM', 'BEAT');
   //Extended tokens, $C7 then $8E onwards
   exttokens2: array[0..17] of String = ('APPEND', 'AUTO', 'CRUNCH', 'DELET', 'EDIT', 'HELP', 'LIST', 'LOAD',
    'LVAR', 'NEW', 'OLD', 'RENUMBER', 'SAVE', 'TEXTLOAD', 'TEXTSAVE', 'TWIN',
    'TWINO', 'INSTALL');
   //Extended tokens, $C8 then $8E onwards
   exttokens3: array[0..21] of String = ('CASE', 'CIRCLE', 'FILL', 'ORIGIN', 'PSET', 'RECT', 'SWAP', 'WHILE',
    'WAIT', 'MOUSE', 'QUIT', 'SYS', 'INSTALL', 'LIBRARY', 'TINT', 'ELLIPSE',
    'BEATS', 'TEMPO', 'VOICES', 'VOICE', 'STEREO', 'OVERLAY');
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
 c,t     : Byte;
 linetxt : String;
 detok,
 rem,
 isbasic : Boolean;
begin
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
  while(ptr+3<Length(buffer))and(isbasic)do
  begin
   if(buffer[ptr+1]=$FF)and(buffer[ptr+3]<5) then
    SetLength(buffer,ptr+1)
   else
   begin
    inc(ptr,buffer[ptr+3]);
    if buffer[ptr]<>$0D then isbasic:=False;
   end;
  end;
 end;
 ptr:=0;
 Memo1.Clear;
 Caption:=FileNames[0];
 if isbasic then
 begin
  while ptr+3<Length(buffer) do
  begin
   //Read in the line
   if buffer[ptr]=$0D then
   begin
    //Line number
    linenum:=buffer[ptr+2]+buffer[ptr+1]<<8;
    linetxt:=PadLeft(IntToStr(linenum),5)+' ';
    //Line length
    linelen:=buffer[ptr+3];
    lineptr:=4;
    detok:=True;
    rem:=False;
    while lineptr<linelen do
    begin
     c:=buffer[ptr+lineptr];
     inc(lineptr);
     if(c>$7F)and(detok)then
     begin
      //Is token a REM?
      if c=$F4 then
      begin
       detok:=False;
       rem:=True;
      end;
      //Normal token (BASIC I,II,III and IV)
      if(c<$C6)or(c>$C8)then linetxt:=linetxt+tokens[c-$80]
      else //Extended tokens (BASIC V)
      begin
       t:=buffer[ptr+lineptr];
       inc(lineptr);
       if c=$C6 then linetxt:=linetxt+exttokens1[t-$8E];
       if c=$C7 then linetxt:=linetxt+exttokens2[t-$8E];
       if c=$C8 then linetxt:=linetxt+exttokens3[t-$8E];
      end;
      c:=0;
     end;
     if c>31 then
     begin
      linetxt:=linetxt+Chr(c AND$7F);
      //Do not detokenise within quotes
      if(c=34)and(not rem)then detok:=not detok;
     end;
    end;
    Memo1.Lines.Add(linetxt);
    inc(ptr,linelen);
   end;
  end;
 end
 else
 begin
  linetxt:='';
  while ptr<Length(buffer) do
  begin
   c:=buffer[ptr];
   inc(ptr);
   if(c>31)and(c<127)then linetxt:=linetxt+chr(c);
   if c=$0A then
   begin
    Memo1.Lines.Add(linetxt);
    linetxt:='';
   end;
  end;
  if linetxt<>'' then Memo1.Lines.Add(linetxt);
 end;
end;

end.

