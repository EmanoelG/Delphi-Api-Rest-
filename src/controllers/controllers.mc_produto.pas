unit controllers.mc_produto;

interface

uses
  Horse, Horse.OctetStream, Horse.RateLimit, System.JSON, System.StrUtils,
  Horse.Exception.Logger, Horse.Logger, Horse.Etag, Horse.Paginate,
  Horse.BasicAuthentication, Horse.Compression, Horse.Jhonson,
  Horse.HandleException, Horse.Logger.Provider.LogFile, System.JSON.Readers,
  Horse.JWT, services.produto, Vcl.ExtCtrls, System.Classes;

procedure registry();

function calculaPaginacao(iLimit, iPageOffSet, QTD: Integer): Integer;

procedure listProduto(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

uses
  Horse.GBSwagger, System.SysUtils, Data.SqlTimSt, MyClaims, UConstApp;

type
  TItem = class
  private
    fname: string;
  public
    property name: string read fname write fname;
  end;

type
  TBookObjArray = array of TItem;

  TProduto = class
  private
    flimit: integer;
    frecords: integer;
    fpages: integer;
    fsucess: boolean;
    fpage: integer;
    fdata: TBookObjArray;

  public
    property sucess: boolean read fsucess write fsucess;
    property records: integer read frecords write frecords;
    property data: TBookObjArray read fdata write fdata;
    property limit: integer read flimit write flimit;
    property page: integer read fpage write fpage;
    property pages: integer read fpages write fpages;
  end;

  TAPIError = class
  private
    Ferror: string;
  public
    property error: string read Ferror write Ferror;
  end;

var
  LConfServer: TJSONArray;


procedure registry();
var
  Config: TRateLimitConfig;
  ACallbacks: TArray<THorseCallback>;
begin
  try
    THorse.Use(HorseSwagger);
    Swagger.Path('produto').Tag('produto').GET('produto', 'Lista limit 50').AddParamHeader('Authorization', 'Bearer + token').&end.AddResponse(200, 'successful operation').Schema(TProduto).IsArray(True).&end.AddResponse(400, 'Bad Request').Schema(TAPIError).IsArray(true).&end.AddResponse(429, 'Too Many Requests').Description('Muitas requisições ! aguarde 30 segundos !').&end.AddResponse(401, 'Pdv não autorizado').Schema(TAPIError).IsArray(true).&end.AddResponse(500, 'Internal Server Error').Schema(TAPIError).IsArray(true).&end.&end.&end;
    Config.Id := 'produto';
    Config.Limit := 3;
    Config.Timeout := 15;
    Config.Message := 'Muitas requisições ! aguarde 15 segundos ! ';
    Config.Headers := True;
  finally

  end;
  THorse.AddCallbacks([HorseJWT(key_app, THorseJWTConfig.New.SessionClass(TMyClaims)), THorseRateLimit.New(Config)]).Get('/produto', listProduto);
end;

procedure listProduto(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  IPage, iLimit, iQtdPAGINA: Integer;
  LSend: TJSONObject;
  JsonDATA: string;
  LDao: dao;
begin
  try
    LDao := Dao.Create;
    Res.AddHeader('X-server', versao_app);

    if Req.Query.ContainsKey('limit') then
    begin
      iLimit := StrToIntDef(Req.Query.Field('limit').AsString, 50);
    end
    else
      iLimit := 50;
    if Req.Query.ContainsKey('page') then
    begin
      IPage := StrToIntDef(Req.Query.Field('page').AsString, 0);
    end
    else
      IPage := 0;

    JsonDATA := LDao.listarProdutoByCodInt('001');
    LSend := TJSONObject.Create;
    LSend.AddPair('sucess', TJSONBool.Create(True));
    LSend.AddPair('data', JsonDATA);
    LSend.AddPair('page', TJSONNumber.Create(0));
    LSend.AddPair('pages', TJSONNumber.Create(0));
    LSend.AddPair('records', TJSONNumber.Create(1));
    Res.Send<TJSONArray>(TJSONArray.Create(LSend)).Status(THTTPStatus.OK);

  finally
    if Assigned(LDao) then
      LDao.Destroy;
  end;

end;

function calculaPaginacao(iLimit, iPageOffSet, QTD: Integer): Integer;
var
  dDIV: Real;
begin
  dDIV := QTD / iLimit;
  Result := Trunc(dDIV);
end;

end.

