unit services.produto;

interface

uses
  System.JSON, Horse, Data.DB, DataSet.Serialize, providers.connection.dao,
  Data.SqlTimSt, BCrypt, BCrypt.Types, MyClaims, System.Classes;

type
  dao = class
  private
    Fpagina: Integer;
    flimite: Integer;
    connectionBD: TFRDConnection;
    fIQuantidadeProduto: Integer;

  public

    function listarProdutoByCodInt(SCodInterno: string): string;
    constructor Create();

  end;

implementation

uses
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error,
  FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, System.SysUtils;
{ DAO }

constructor dao.Create();
begin
end;
//Mocado

function dao.listarProdutoByCodInt(SCodInterno: string): string;
begin
  if SCodInterno <> '' then
  begin
    //Mocado
    result := '{ "produto":"agua mineral", "quantidade":100 } ';
  end;
end;

end.

