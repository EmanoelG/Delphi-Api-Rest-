unit controllers.mc_login;

interface

uses
  Horse, System.Generics.Collections, JOSE.Core.jwt, jose.core.Builder,
  System.DateUtils, System.JSON, MyClaims;

procedure registry;

function getToken(const aExpiration: TDateTime; const Claims: TMyClaims): string;

procedure login(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

uses
  System.SysUtils, services.produto, Horse.Commons, Horse.JWT, services.auth,
  Horse.RateLimit, System.Classes, Vcl.ExtCtrls, Horse.GBSwagger, UConstApp,
  Data.SqlTimSt;

type
  TLogin = class
  private
    ftoken: string;
  public
    property token: string read ftoken write ftoken;

  end;

  TAPIError = class
  private
    Ferror: string;

  public
    property error: string read Ferror write Ferror;
  end;

  TTooMany = class
  private
    Ferror: string;

  public
    property mensagem: string read Ferror write Ferror;
  end;

var
  LConfServer: TJSONArray;


procedure registry;
var
  Config: TRateLimitConfig;
begin
  Config.Id := 'movimentacao';
  Config.Limit := 3;
  Config.Timeout := 30;
  Config.Message := 'Muitas requisições ! aguarde 30 segundos ! ';
  Config.Headers := True;
  Config.SkipFailedRequest := False;
  Config.SkipSuccessRequest := False;
  Swagger.Path('login ').Tag('login').post('login', 'Login estacao ').AddParamBody('Usuario e senha', '{"user":"Emanoel", "password":"0210jfan"}').&End.AddResponse(200, 'successful operation').Schema(TLogin).IsArray(True).&end.AddResponse(400, 'Bad Request').Schema(TAPIError).IsArray(true).&end.AddResponse(429, 'Too Many Requests').Description('Muitas requisições ! aguarde 30 segundos !').&end.AddResponse(401, 'Pdv não autorizado').Schema(TAPIError).IsArray(true).&end.AddResponse(500, 'Internal Server Error').Schema(TAPIError).IsArray(true).&end.&end.&end;
  THorse.AddCallbacks([THorseRateLimit.New(Config)]).post('/login', login);
end;

procedure login(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  autoriza_acess: boolean;
  tTimeLocal: TSQLTimeStamp;
  LConteudo: TJSONObject;
  ip_header, password_header, user_header: string;
  daoLogin: daoAuth;
  TClaims: TMyClaims;
begin
  try
    daoLogin := daoAuth.create;
    Res.AddHeader('X-server', versao_app);
    LConteudo := Req.Body<TJsonObject>;
    LConteudo.TryGetValue<string>('user', user_header);
    LConteudo.TryGetValue<string>('password', password_header);

    if (trim(user_header) = '') or (trim(password_header) = '') then
    begin
      Res.Send(TJSONArray.Create(TJSONObject.Create(TJSONPair.Create('ERROR', 'requisição mal formulada')))).Status(THTTPStatus.BadRequest);
    end
    else
    begin
      autoriza_acess := daoLogin.permitirAcesso(user_header, password_header);
      if autoriza_acess = true then
      begin
        TClaims := daoLogin.TClaims;
        Res.Send(TJSONArray.Create(TJSONObject.Create(TJSONPair.Create('token', getToken(incHour(now), TClaims)))))
      end
      else
        Res.Send(TJSONArray.Create(TJSONObject.Create(TJSONPair.Create('ERROR', 'acesso negado !')))).Status(THTTPStatus.BadRequest);
    end
  finally
    daoLogin.Free;
  end;
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

end.

