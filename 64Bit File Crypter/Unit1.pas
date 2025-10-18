unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, XPMan;

type
  TForm1 = class(TForm)
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    StatusBar1: TStatusBar;
    GroupBox1: TGroupBox;
    Edit1: TEdit;
    Label2: TLabel;
    Button3: TButton;
    Label1: TLabel;
    Label5: TLabel;
    GroupBox2: TGroupBox;
    Label3: TLabel;
    Edit2: TEdit;
    Label4: TLabel;
    Edit3: TEdit;
    Button1: TButton;
    Button4: TButton;
    OpenDialog2: TOpenDialog;
    Button2: TButton;
    Label6: TLabel;
    Label7: TLabel;
    ProgressBar1: TProgressBar;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses Crypt64bit;

{$R *.DFM}
function Get_File_Size4(const S: string): Int64;
var
  FD: TWin32FindData;
  FH: THandle;
begin
  FH := FindFirstFile(PChar(S), FD);
  if FH = INVALID_HANDLE_VALUE then Result := 0
  else
    try
      Result := FD.nFileSizeHigh;
      Result := Result shl 32;
      Result := Result + FD.nFileSizeLow;
    finally
      //CloseHandle(FH);
    end;
end;

function IsExecutable32Bit(const lpExeFilename: String): Boolean;
const
  kb32 = 1024 * 32;
var
  Buffer : Array[0..kb32-1] of Byte; // warning: assuming both headers are in there!
  hFile : DWord;
  bRead : DWord;
  bToRead : DWord;
  pDos : PImageDosHeader;
  pNt : PImageNtHeaders;
begin
  Result := False;
  hFile := CreateFile(pChar(lpExeFilename), GENERIC_READ, FILE_SHARE_READ, NIL,
    OPEN_EXISTING, 0, 0);
  if hFile <> INVALID_HANDLE_VALUE then
    try
      bToRead := GetFileSize(hFile, NIL);
      if bToRead > kb32 then bToRead := kb32;
      if not ReadFile(hFile, Buffer, bToRead, bRead, NIL) then Exit;
      if bRead = bToRead then
      begin
        pDos := @Buffer[0];
        if pDos.e_magic = IMAGE_DOS_SIGNATURE then
        begin
          pNt := PImageNtHeaders(LongInt(pDos) + pDos._lfanew);
          if pNt.Signature = IMAGE_NT_SIGNATURE then
            Result := pNt.FileHeader.Machine and IMAGE_FILE_32BIT_MACHINE > 0;
        end
        else
          raise Exception.Create('File is not a valid executable.');

      end
        else
          raise Exception.Create('File is not an executable.');

    finally
      CloseHandle(hFile);
    end;
end;


function IsExecutable64Bit(const lpExeFilename: String): Boolean;
// since as of now, there only exist 32 and 64 bit executables,
// if its not the one, its assumably the other
begin
  Result := not IsExecutable32Bit(lpExeFilename);
end;

procedure TForm1.Button1Click(Sender: TObject);
const
 Base64MaxLength = 72;
var
 hFile: integer;
 base64String: string;
 base64File: textfile;
 Base64: TBase64;
 Buf: array[0..2] of Byte;
begin
  if not FileExists(Edit1.Text) then begin
    Beep;
    MessageDlg('Cant find Exexcutable!',mtInformation, [mbOK], 0);
    Exit;
  end;

{$R-}
 Screen.Cursor := crHourGlass;
 ProgressBar1.Position := 0;
 StatusBar1.Panels[2].Text := 'Crypting, please wait...';

 Edit1.Text := OpenDialog1.FileName;
 base64String:='';
 hFile := FileOpen(OpenDialog1.FileName,fmOpenReadWrite);

 if Label5.Caption = '64 Bit Executable' then
 begin
  AssignFile(base64File, OpenDialog1.FileName+'.b64');
 end else begin
  AssignFile(base64File, OpenDialog1.FileName+'.b32');
 end;

 Rewrite(base64File);
 FillChar(Buf,SizeOf(Buf),#0);
 ProgressBar1.Max := Get_File_Size4(OpenDialog1.FileName) div 100;
 try

   repeat
    Base64.ByteCount := FileRead(hFile, Buf, SizeOf(Buf));
    Move(Buf,Base64.ByteArr,SizeOf(Buf));
    base64String := base64String+CodeBase64(Base64);
    if Length(base64String) = Base64MaxLength
    then
     begin
      Writeln(base64File,base64String);
      base64String := '';
      ProgressBar1.Position := ProgressBar1.Position + 1;
      Label10.Caption := IntToStr(ProgressBar1.Position);
      Application.ProcessMessages;
     end;
   until Base64.ByteCount < 3;

  Writeln(base64File,base64String);
 finally
 CloseFile(base64File);
 FileClose(hFile);
 StatusBar1.Panels[2].Text := 'Progress finish.';
 Screen.Cursor := crDefault;
 Label10.Caption := '0';
 ProgressBar1.Position := 0;
 MessageDlg('Crypting done.',mtInformation, [mbOK], 0);
 end;

 StatusBar1.SetFocus;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
 base64File: textfile;
 BufStr: string;
 base64String: string;
 Base64: TBase64;
 hFile: integer;
begin
 if not FileExists(Edit1.Text) then begin
    Beep;
    MessageDlg('Cant find Crypted File!',mtInformation, [mbOK], 0);
    Exit;
  end;

   Screen.Cursor := crHourGlass;
   ProgressBar1.Position := 0;
   StatusBar1.Panels[2].Text := 'Decrypting, please wait...';
   AssignFile(base64File,OpenDialog2.FileName);
   Reset(base64File);
   hFile:=FileCreate(Edit3.Text);
   ProgressBar1.Max := Get_File_Size4(OpenDialog2.FileName) div 100;
   try
   while not EOF(base64File) do
   begin
     Readln(base64File,BufStr);
     while Length(BufStr) > 0 do
      begin
       base64String := Copy(BufStr,1,4);
       Delete(BufStr,1,4);
       Base64 := DecodeBase64(base64String);
       FileWrite(hFile, Base64.ByteArr, Base64.ByteCount);
      end;
     ProgressBar1.Position := ProgressBar1.Position + 1;
     Label10.Caption := IntToStr(ProgressBar1.Position);
     Application.ProcessMessages;
   end;
 finally
 FileClose(hFile);
 CloseFile(base64File);
 StatusBar1.Panels[2].Text := 'Progress finish.';
 Screen.Cursor := crDefault;
 Label10.Caption := '0';
 ProgressBar1.Position := 0;
 MessageDlg('Decrypting done.',mtInformation, [mbOK], 0);
 end;
 StatusBar1.SetFocus;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    Edit1.Text := OpenDialog1.FileName;

    if IsExecutable64Bit(OpenDialog1.FileName) = true then
    begin
    Label5.Caption := '64 Bit Executable';
    end else begin
    Label5.Caption := '32 Bit Executable';
    end;

    StatusBar1.Panels[1].Text := IntToStr(Get_File_Size4(OpenDialog1.FileName) div 1000) + ' Kb';
  end;
  StatusBar1.SetFocus;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  if OpenDialog2.Execute then begin
  Edit2.Text := OpenDialog2.FileName;
  Edit3.Text := ChangeFileExt(OpenDialog2.FileName, '.exe');


    if IsExecutable64Bit(ChangeFileExt(OpenDialog2.FileName, '.exe')) = true then
    begin
      Label7.Caption := '64 Bit Executable';
    end else begin
      Label7.Caption := '32 Bit Executable';
    end;
  StatusBar1.Panels[1].Text := IntToStr(Get_File_Size4(OpenDialog2.FileName) div 1000) + ' Kb';
  end;
  StatusBar1.SetFocus;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  DoubleBuffered := true;
end;

end.
