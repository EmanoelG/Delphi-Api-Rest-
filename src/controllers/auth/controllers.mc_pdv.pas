unit controllers.mc_pdv;

interface

uses
  Horse, Horse.OctetStream, System.JSON, System.StrUtils, Horse.JWT,
  System.SysUtils, UConstApp, MyClaims;

procedure registry(identit: integer);

procedure loginMcPdv(Req: THorseRequest; Res: THorseResponse; Next: TProc);

function getToken(const aExpiration: TDateTime; const Claims: TMyClaims): string;

implementation

uses
  System.Classes, Horse.BasicAuthentication, Horse.Logger.Provider.LogFile,
  Horse.Exception.Logger, Horse.Logger, System.Generics.Collections,
  Horse.RateLimit, services.config_server, UCONFIGSERVER, UUtils,
  Horse.GBSwagger, Web.HTTPApp, GBSwagger.Model.Types, services.produto,
  Data.SqlTimSt, valida.headers.requisicao, services.auth, JOSE.Core.JWT,
  JOSE.Core.Builder, System.DateUtils, services.auth.mcpdv;

type
  TAuth = class
  private
    facess: string;
    frefresh: string;
  public
    property acess: string read facess write facess;
    property refresh: string read frefresh write frefresh;
  end;

  TAPIError = class
  private
    Ferror: string;
  public
    property error: string read Ferror write Ferror;
  end;

var
  LConfServer: TJSONArray;


procedure registry(identit: integer);
var
  Config: TRateLimitConfig;
  confDAO: daoConfig;
begin
  Config.Id := 'mcpdv';
  Config.Limit := 500;
  Config.Timeout := 30;
  Config.Message := 'Muitas requisições ! aguarde 30 segundos ! ';
  Config.Headers := True;
  Config.SkipFailedRequest := False;
  Config.SkipSuccessRequest := False;
  try
    confDAO := daoConfig.Create;
    LConfServer := confDAO.configuracaoServer(identit);
  finally
    confDAO.destroy;
  end;
  Swagger.Path('login/mcPdv').Tag('login/mcpdv').get('login/mcpdv', 'Login do pdv no server').AddParamHeader('X-Pdv', 'N° Pdv').&end.AddParamHeader('Authorization', 'Bearer +Token ').&end.AddParamHeader('X-Credential', 'credencial do pdv').&End.AddParamHeader('X-unidade', 'Unidade do pdv').&End.AddResponse(200, 'successful operation').Schema(TAuth).IsArray(True).&end.AddResponse(400, 'Bad Request').Schema(TAPIError).IsArray(true).&end.AddResponse(429, 'Too Many Requests').Description('Muitas requisições ! aguarde 30 segundos !').&end.AddResponse(401, 'Pdv não autorizado').Schema(TAPIError).IsArray(true).&end.AddResponse(500, 'Internal Server Error').Schema(TAPIError).IsArray(true).&end.&end.&end;
  THorse.AddCallbacks([THorseRateLimit.New(Config)]).get('login/mcpdv', loginMcPdv);
end;

function getToken(const aExpiration: TDateTime; const Claims: TMyClaims): string;
var
  LJwt: TJWT;
begin
  LJwt := TJWT.Create;
  try
    LJwt.Claims.IssuedAt := Now;
    LJwt.Claims.Expiration := aExpiration;
    LJwt.Claims.Subject := Claims.Id;
    LJwt.Claims.SetClaim('id', Claims.id);
    LJwt.Claims.SetClaim('name', Claims.name);
    LJwt.Claims.SetClaim('cpf', Claims.cpf);
    LJwt.Claims.SetClaim('outro', Claims.outro);
    Result := TJOSE.SHA256CompactToken(key_app, LJwt);
  finally
    if Assigned(LJwt) then
      LJwt.Free;
  end;
end;

procedure loginMcPdv(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  pdv_header, credential_header, unidade_header, estacao_header, configuracao: string;
  LHeader: TPair<string, string>;
  LStream: TMemoryStream;
  LUtils: TUtils;
  i: integer;
  valida_acess: boolean;
  tTimeLocal: TSQLTimeStamp;
  LDao: dao;
  AutorizaClient: CValidaHeaders;
  mcPdvService: daoMcPdv;
  LPdv: TJSONObject;
  TClaims: TMyClaims;
  LToken: TJsonObject;
  save: boolean;
begin
  Res.AddHeader('X-server', versao_app);
  Req.Headers.TryGetValue('X-Pdv', pdv_header);
  Req.Headers.TryGetValue('X-Credential', credential_header);
  Req.Headers.TryGetValue('X-unidade', unidade_header);
  Req.Headers.TryGetValue('X-estacao', estacao_header);
  try
    mcPdvService := daoMcPdv.Create;
    LDao := dao.Create;
    LUtils := TUtils.Create;
    tTimeLocal := VarToSQLTimeStamp(VarSQLTimeStampCreate(now));
    LDao.insertClientReq(LUtils.ClientIP(Req), 'nullo', 'login/mcpdv', tTimeLocal);
    LPdv := TJSONObject.Create;
    LPdv.AddPair('estacao', estacao_header);
    LPdv.AddPair('onof', 'true');
    LPdv.AddPair('credential', credential_header);
    LPdv.AddPair('unidade', unidade_header);
    AutorizaClient := CValidaHeaders.Create;
    if AutorizaClient.autorizaClient(Req, Res, Next, LConfServer, false) = true then
    begin

      if mcPdvService.verificaEstacaoOnOff(LPdv) = true then
      begin                                     // nao foi encontrado estacao online

        try
          TClaims := TMyClaims.Create;
          TClaims.Id := estacao_header;
          TClaims.name := unidade_header;
          TClaims.cpf := '000';
          TClaims.outro := estacao_header + unidade_header;
          LToken := TJsonObject.Create;
          LToken.AddPair('access', getToken(incHour(now), TClaims));
          LToken.AddPair('refresh', getToken(IncMonth(now), TClaims));

          if mcPdvService.verificaEstacaoSignal(LPdv) = false then
            save := mcPdvService.saveClientIn(LPdv)
          else
            save := mcPdvService.saveClientUp(LPdv);

          if save = true then
            Res.Send(TJSONArray.Create(LToken)).Status(THTTPStatus.OK)
          else
            Res.Send(TJSONArray.Create(TJSONObject.Create(TJSONPair.Create('ERROR', 'Nao foi possivel atualizar estacao !')))).Status(THTTPStatus.InternalServerError);

        finally
          TClaims.Free;
        end;

      end
      else
      begin
        Res.Send(TJSONArray.Create(TJSONObject.Create(TJSONPair.Create('ERROR', 'Estacao ja esta on-line !')))).Status(THTTPStatus.Unauthorized);
      end;
    end;
  finally
    LDao.destroy;
    mcPdvService.destroy;
    AutorizaClient.Free;
    LUtils.Free;
    LPdv.free;
  end;
end;

end.

