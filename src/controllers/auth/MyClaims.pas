unit MyClaims;

interface

uses
  JOSE.Core.JWT, JOSE.Types.JSON;

type
  TMyClaims = class(TJWTClaims)
  strict private
    function GetId: string;
    procedure SetId(const Value: string);
    function GetName: string;
    procedure SetName(const Value: string);
    function getOutro: string;
    procedure setoutro(const Value: string);
    function GetCpf: string;
    procedure setCpf(const Value: string);
  private

  public
    property Id: string read GetId write SetId;
    property name: string read GetName write SetName;
    property cpf: string read GetCpf write setCpf;
    property outro: string read getOutro write setoutro;
  end;

implementation

{ TMyClaims }

function TMyClaims.GetCpf: string;
begin
  Result := TJSONUtils.GetJSONValue('cpf', FJSON).AsString;
end;

function TMyClaims.GetId: string;
begin
  Result := TJSONUtils.GetJSONValue('id', FJSON).AsString;
end;

procedure TMyClaims.SetId(const Value: string);
begin
  TJSONUtils.SetJSONValueFrom<string>('id', Value, FJSON);
end;

function TMyClaims.GetName: string;
begin
  Result := TJSONUtils.GetJSONValue('name', FJSON).AsString;
end;

function TMyClaims.getOutro: string;
begin
  Result := TJSONUtils.GetJSONValue('outro', FJSON).AsString;
end;

procedure TMyClaims.setCpf(const Value: string);
begin
  TJSONUtils.SetJSONValueFrom<string>('cpf', Value, FJSON);
end;

procedure TMyClaims.SetName(const Value: string);
begin
  TJSONUtils.SetJSONValueFrom<string>('name', Value, FJSON);
end;

procedure TMyClaims.setoutro(const Value: string);
begin
  TJSONUtils.SetJSONValueFrom<string>('outro', Value, FJSON);
end;

end.

