unit UUtils;

interface

uses
  System.Classes, Horse;

type
  TArrayOfString = array of string;

//  TStringListOtmFind = class(TStringList);

  TUtils = class
    function RemoveNumbers(const aString: string): string;
    function SoLetra(Texto: string): Boolean;
    function percorreString(str: string): TStringList;
    procedure percorreStringByParam(str: string; Delimiter: string; ListaRes: TStringList);
    function SplitString(const aSeparator, aString: string; aMax: Integer): TArrayOfString;
    function pegaNumero(str: string): string;
    procedure Split(Delimiter: Char; Str: string; ListOfStrings: TStrings);
    function ListarArquivos(Diretorio: string; Sub: Boolean): tsTRINGlIST;
    function ClientIP(const Req: THorseRequest): string;
    procedure StrToLista(var Lista: TStringList; const Str: string; const Separador: string; const Integral: Boolean);
  public
    function validaPdvAcess(pdv: string; listPdvValidos: TStringList): Boolean;
  end;

implementation

uses
  System.AnsiStrings, System.SysUtils, Winapi.Windows, Vcl.Forms;

procedure TUtils.Split(Delimiter: Char; Str: string; ListOfStrings: TStrings);
begin
  ListOfStrings.Clear;
  ListOfStrings.Delimiter := Delimiter;
  ListOfStrings.StrictDelimiter := True;
  ListOfStrings.DelimitedText := Str;
end;

function TUtils.percorreString(str: string): TStringList;
var
  frase, nome, delimitador: string;
  Lngth, X: Integer;
  lista: TStringList;
begin
  nome := str;
  frase := '';
  delimitador := '|';
  lista := TStringList.Create;
  for X := 1 to Length(nome) do
  begin
    if nome[X] <> delimitador then
    begin
      frase := frase + nome[X];
    end
    else
    begin
      lista.Add(frase);
      frase := '';
    end;
  end;
  Result := lista;
end;

procedure TUtils.percorreStringByParam(str: string; Delimiter: string; ListaRes: TStringList);
var
  frase, nome: string;
  Lngth, X: Integer;
begin
  nome := str;
  frase := '';
  for X := 1 to Length(nome) do
  begin
    if nome[X] <> Delimiter then
    begin
      frase := frase + nome[X];
    end
    else
    begin
      if frase <> '' then
      begin
        ListaRes.Add(frase);
        frase := '';
      end;
    end;

    if X = Length(nome) then
    begin
      if frase <> '' then
      begin
        ListaRes.Add(frase);
        frase := '';
      end

    end;

  end;

end;

function TUtils.RemoveNumbers(const aString: string): string;
var
  C: char;
begin
  Result := '';
  for C in aString do
  begin
    if not CharInSet(C, ['0'..'9']) then
    begin
      Result := Result + C;
    end;
  end;
end;

function TUtils.SoLetra(Texto: string): Boolean;
var
  Resultado: Boolean;
  nContador: Integer;
begin
  Resultado := true;
  for nContador := 1 to Length(Texto) do
  begin
    if Texto[nContador] in ['a'..'z', 'A'..'Z'] then

    else
      Resultado := false;
  end;
  Result := Resultado;
end;

function TUtils.SplitString(const aSeparator, aString: string; aMax: Integer): TArrayOfString;
var
  i, strt, cnt: Integer;
  sepLen: Integer;

  procedure AddString(aEnd: Integer = -1);
  var
    endPos: Integer;
  begin
    if (aEnd = -1) then
      endPos := i
    else
      endPos := aEnd + 1;
    if (strt < endPos) then
      Result[cnt] := Copy(aString, strt, endPos - strt)
    else
      Result[cnt] := '';
    Inc(cnt);
  end;

begin
  if (aString = '') or (aMax < 0) then
  begin
    SetLength(Result, 0);
    EXIT;
  end;
  if (aSeparator = '') then
  begin
    SetLength(Result, 1);
    Result[0] := aString;
    EXIT;
  end;
  sepLen := Length(aSeparator);
  SetLength(Result, (Length(aString) div sepLen) + 1);
  i := 1;
  strt := i;
  cnt := 0;
  while (i <= (Length(aString) - sepLen + 1)) do
  begin
    if (aString[i] = aSeparator[1]) then
      if (Copy(aString, i, sepLen) = aSeparator) then
      begin
        AddString;
        if (cnt = aMax) then
        begin
          SetLength(Result, cnt);
          EXIT;
        end;
        Inc(i, sepLen - 1);
        strt := i + 1;
      end;
    Inc(i);
  end;
  AddString(Length(aString));
  SetLength(Result, cnt);
end;

procedure TUtils.StrToLista(var Lista: TStringList; const Str, Separador: string; const Integral: Boolean);
var
  c: integer;
  s: string;
begin
  try

    if Lista = nil then
      Lista := TStringList.Create;

    if not Integral then
    begin
      s := '';
      Lista.Clear;
      for c := 1 to Length(Str) do
      begin
        if Pos(Str[c], Separador) = 0 then
        begin
          if not (Str[c] in [#10, #13, #26]) then
            s := s + Str[c];
        end
        else
        begin
          if Length(s) > 0 then
            Lista.Add(s);
          s := '';
        end;
      end;
      if Trim(s) <> '' then
        Lista.Add(s);
    end
    else
    begin
      s := '';
      Lista.Clear;
      if Length(Str) > 0 then
      begin
        for c := 1 to Length(Str) do
        begin
          if Pos(Str[c], Separador) = 0 then
            s := s + Str[c]
          else
          begin
            Lista.Add(s);
            s := '';
          end;
        end;
        Lista.Add(s);
      end;
    end;
  except
    on E: Exception do
      Writeln('Error 240: ' + e.Message);
  end;

//  try
//    {$IFDEF VER150}
//    //assertList(Lista, Str, Separador, Integral);
//    {$ENDIF}
//  except
//  end;
end;

function TUtils.validaPdvAcess(pdv: string; listPdvValidos: TStringList): boolean;
var
  i: Integer;
begin
  for i := 0 to listPdvValidos.Count - 1 do
  begin
    if listPdvValidos[i] = pdv then
    begin
      Result := true;
      Break
    end
    else
    begin
      Result := false;
    end;
  end;
end;

function TUtils.ClientIP(const Req: THorseRequest): string;
var
  LIP: string;
begin
  Result := EmptyStr;

  if not Trim(Req.Headers['HTTP_CLIENT_IP']).IsEmpty then
    Exit(Trim(Req.Headers['HTTP_CLIENT_IP']));

  for LIP in Trim(Req.Headers['HTTP_X_FORWARDED_FOR']).Split([',']) do
    if not Trim(LIP).IsEmpty then
      Exit(Trim(LIP));

  for LIP in Trim(Req.Headers['x-forwarded-for']).Split([',']) do
    if not Trim(LIP).IsEmpty then
      Exit(Trim(LIP));

  if not Trim(Req.Headers['HTTP_X_FORWARDED']).IsEmpty then
    Exit(Trim(Req.Headers['HTTP_X_FORWARDED']));

  if not Trim(Req.Headers['HTTP_X_CLUSTER_CLIENT_IP']).IsEmpty then
    Exit(Trim(Req.Headers['HTTP_X_CLUSTER_CLIENT_IP']));

  if not Trim(Req.Headers['HTTP_FORWARDED_FOR']).IsEmpty then
    Exit(Trim(Req.Headers['HTTP_FORWARDED_FOR']));

  if not Trim(Req.Headers['HTTP_FORWARDED']).IsEmpty then
    Exit(Trim(Req.Headers['HTTP_FORWARDED']));

  if not Trim(Req.Headers['REMOTE_ADDR']).IsEmpty then
    Exit(Trim(Req.Headers['REMOTE_ADDR']));

{$IF DEFINED(FPC)}
  if not Trim(Req.RawWebRequest.RemoteAddress).IsEmpty then
    Exit(Trim(Req.RawWebRequest.RemoteAddress));
{$ELSE}
  if not Trim(Req.RawWebRequest.RemoteIP).IsEmpty then
    Exit(Trim(Req.RawWebRequest.RemoteIP));
{$ENDIF}
  if not Trim(Req.RawWebRequest.RemoteAddr).IsEmpty then
    Exit(Trim(Req.RawWebRequest.RemoteAddr));

  if not Trim(Req.RawWebRequest.RemoteHost).IsEmpty then
    Exit(Trim(Req.RawWebRequest.RemoteHost));

end;

function TUtils.ListarArquivos(Diretorio: string; Sub: Boolean): tsTRINGlIST;
var
  F: TSearchRec;
  Ret: Integer;
  TempNome: string;
  LResult: tsTRINGlIST;

  function TemAtributo(Attr, Val: Integer): Boolean;
  begin
    Result := Attr and Val = Val;
  end;

begin

  Ret := FindFirst(Diretorio + '\*.*', faAnyFile, F);

  try
    LResult := tsTRINGlIST.Create;
    while Ret = 0 do
    begin

      if TemAtributo(F.Attr, faDirectory) then
      begin

        if (F.Name <> '.') and (F.Name <> '..') then
          if Sub = True then
          begin
            TempNome := Diretorio + '\' + F.Name;
            ListarArquivos(TempNome, True);

          end;

      end
      else
      begin
        LResult.Add(Diretorio + '\' + F.Name);

      end;

      Ret := FindNext(F);

    end;
    Result := LResult;
  finally
    LResult.Free;
    begin
    //  FindClose(F);
    end;

  end;
end;

function TUtils.pegaNumero(str: string): string;
var
  i: Integer;
  Scupom: string;
begin
  for i := 1 to Length(str) do
    if str[i] in ['0'..'9'] then
    begin
      Scupom := Scupom + str[i];
    end;
  Result := Scupom;
end;

end.

