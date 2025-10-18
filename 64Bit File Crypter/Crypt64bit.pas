{$R-}

unit Crypt64bit;

interface

Const
  base64ABC='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

Type
  TBase64 = Record
  ByteArr  : Array [0..2] Of Byte;
  ByteCount:Byte;
End;

Function CodeBase64(Base64:TBase64):String;
Function DecodeBase64(StringValue:String):TBase64;

implementation

Function CodeBase64(Base64:TBase64):String;
Var
  N,M : Byte;
  Dest, Sour:Byte;
  NextNum:Byte;
  Temp:Byte;
Begin 
  Result:='';
  NextNum:=1;
  Dest:=0;
  For N:=0 To 2 Do
  Begin
  Sour:=Base64.ByteArr[N];
  For M:=0 To 7 Do
    Begin
    Temp:=Sour;
    Temp:=Temp SHL M;
    Dest:=Dest SHL 1;

      If (Temp And 128) = 128 Then
      Dest:=Dest Or 1;
      Inc(NextNum);

      If NextNum > 6 Then
        Begin
        Result:=Result+base64ABC[Dest+1];
        NextNum:=1;
        Dest:=0;
      End;
    End;
  End;

  If Base64.ByteCount < 3 Then

  For N:=0 To (2 - Base64.ByteCount) Do
    Result[4-N]:='=';
End;

Function DecodeBase64(StringValue:String):TBase64;
Var
  M,N:Integer;
  Dest, Sour:Byte;
  NextNum:Byte;
  CurPos:Byte;
Begin 
  CurPos:=0;
  Dest:=0;
  NextNum:=1;
  FillChar(Result,SizeOf(Result),#0);

  For N:=1 To 4 Do
  Begin
    For M:=0 To 5 Do
    Begin

      If StringValue[N]='=' Then
        Sour:=0
      else
        Sour:=Pos(StringValue[N],base64ABC)-1;
        Sour:=Sour SHL M;
        Dest:=Dest SHL 1;

      If (Sour And 32)=32 Then
        Dest:=Dest Or 1;
        Inc(NextNum);

      If NextNum > 8 Then
      Begin
        NextNum:=1;
        Result.ByteArr[CurPos]:=Dest;

      If StringValue[N]='=' Then
        Result.ByteArr[CurPos]:=0
      else
        Result.ByteCount:=CurPos+1;
        Inc(CurPos);
        Dest:=0;
      End;
    End;
  End;
End;

end.

