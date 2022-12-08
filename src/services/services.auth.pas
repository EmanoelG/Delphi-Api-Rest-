unit services.auth;

interface

uses
  System.JSON, Horse, Data.DB, DataSet.Serialize,
  Data.SqlTimSt, BCrypt, BCrypt.Types, MyClaims, System.Classes;

type
  daoAuth = class
  private
    Fpagina: Integer;
    flimite: Integer;

    fIQuantidadeProduto: Integer;

  public
    TClaims: TMyClaims;
    function permitirAcesso(Lusuario, lpassword: string): Boolean;
    function Claims(const id, name, cpf, outro: string): TMyClaims;
    constructor Create();
    destructor destroy;

  end;

implementation

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, System.SysUtils;

{ DAO }

function daoAuth.Claims(const id, name, cpf, outro: string): TMyClaims;
var
  LClaims: TMyClaims;
begin
  LClaims := TMyClaims.Create;
  LClaims.id := id;
  LClaims.name := name;
  LClaims.cpf := cpf;
  LClaims.outro := outro;
  Result := LClaims;
end;

constructor daoAuth.Create();
begin
  inherited;

end;

destructor daoAuth.destroy;
begin

end;

function daoAuth.permitirAcesso(Lusuario, lpassword: string): Boolean;
begin

  if (Lusuario <> '') and (lpassword <> '') then
  begin
    Result := true;
    TClaims := Claims('001', 'Exemplo api rest', '123.456.789-25',
      'fasasfa#@!@$DA');
  end
  else
    Result := false;

end;

end.
