program Crypter64Bit;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Crypt64bit in 'Crypt64bit.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
