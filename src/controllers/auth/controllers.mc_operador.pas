unit controllers.mc_operador;

interface

uses
  Horse, System.Generics.Collections, JOSE.Core.jwt, jose.core.Builder,
  System.DateUtils, System.Classes, System.JSON;

procedure registry(identit: Integer);

procedure efetuarLogin(Req: THorseRequest; Res: THorseResponse; Next: TProc);

procedure refreshToken(Req: THorseRequest; Res: THorseResponse; Next: TProc);

function autorizaAcess(req: THorseRequest; Res: THorseResponse; next: TProc): boolean;

procedure logout(req: THorseRequest; Res: THorseResponse; next: TProc);

implementation

uses
  System.SysUtils, services.produto, Horse.Commons, Horse.JWT, MyClaims, UUtils,
  services.auth, services.config_server, UCONFIGSERVER, Horse.RateLimit,
  Horse.GBSwagger, UConstApp, Data.SqlTimSt, uunidadespdv, REST.Json,
  valida.headers.requisicao;

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


function autorizaAcess(req: THorseRequest; Res: THorseResponse; next: TProc): boolean;
var
  LObSub: TJSONValue;
  acess_validation: boolean;
  LDao: dao;
  tTimeLocal: TSQLTimeStamp;
  LUtils: TUtils;
  AutorizaClient: CValidaHeaders;
begin
  try
    AutorizaClient := CValidaHeaders.create;
    LDao := dao.Create;
    LUtils := TUtils.Create;
    tTimeLocal := VarToSQLTimeStamp(VarSQLTimeStampCreate(now));
    LDao.insertClientReq(LUtils.ClientIP(req), req.Body, 'refreshToken', tTimeLocal);
    try
      acess_validation := false;
      acess_validation := AutorizaClient.autorizaClient(req, Res, next, LConfServer, false);
      if acess_validation = true then
      begin
        Result := true;
      end
      else
        Result := False;
    except
      on E: Exception do
        Res.Send(TJSONObject.Create(TJSONPair.Create('ERROR', E.Message))).Status(THTTPStatus.InternalServerError);
    end;

  finally
    if Assigned(LDao) then
      LDao.destroy;
    if Assigned(LUtils) then
      LUtils.destroy;
  end

end;

procedure registry(identit: Integer);
var
  pdvsValido: string;
  confDAO: daoConfig;
  Config: TRateLimitConfig;
begin
  try
    confDAO := daoConfig.Create;
    LConfServer := confDAO.configuracaoServer(identit);
  finally
    confDAO.destroy;
  end;
  Config.Id := 'login';
  Config.Limit := 300;
  Config.Timeout := 30;
  Config.Message := 'Muitas requisições ! aguarde 30 segundos ! ';
  Config.Headers := True;
  //Config.Store := nil;
  Config.SkipFailedRequest := false;
  Config.SkipSuccessRequest := false;
  Swagger.Path('login').Tag('login').post('login', 'retornar token de acesso').AddParamHeader('X-Pdv', 'N° Pdv').&end.AddParamHeader('X-Credential', 'credencial do pdv').&End.AddParamBody('{ "username":"name", "password":"pass" }', 'usuario e senha no formato Json').&End.AddResponse(200, 'successful operation').Schema(TAuth).IsArray(True).&end.AddResponse(400, 'Bad Request').&end.AddResponse(401, 'Pdv não autorizado').Schema(TAPIError).&end.AddResponse(429, 'Too Many Requests').Description('Muitas requisições ! aguarde 30 segundos !').&end.AddResponse(500, 'Internal Server Error').Schema(TAPIError).&end.&end.&end;
  THorse.AddCallback(THorseRateLimit.New(Config)).Post('/login/mcoperador', efetuarLogin);
  THorse.AddCallback(HorseJWT(key_app, THorseJWTConfig.New.SessionClass(TMyClaims))).Get('/refreshtkn/mcoperador', refreshToken);
  THorse.AddCallback(HorseJWT(key_app, THorseJWTConfig.New.SessionClass(TMyClaims))).Post('/logout/mcoperador', logout);
end;

procedure logout(req: THorseRequest; Res: THorseResponse; next: TProc);
var
  AutorizaClient: CValidaHeaders;
  Lusuario, LSenha, unidade_header, estacao_header, pdv_header, credential_header: string;
  LDao: dao;
  LUtils: TUtils;
  tTimeLocal: TSQLTimeStamp;
  LConteudo: TJsonObject;
  LService: daoAuth;
  TClaims: TMyClaims;
begin
  try
    LDao := dao.Create;
    LService := daoAuth.Create;
    LUtils := TUtils.Create;
    tTimeLocal := VarToSQLTimeStamp(VarSQLTimeStampCreate(now));
    LDao.insertClientReq(LUtils.ClientIP(req), req.Body, 'logout', tTimeLocal);
    req.Headers.TryGetValue('X-Pdv', pdv_header);
    req.Headers.TryGetValue('X-Credential', credential_header);
    req.Headers.TryGetValue('X-unidade', unidade_header);
    req.Headers.TryGetValue('X-estacao', estacao_header);
    Res.AddHeader('X-server', versao_app);
    AutorizaClient := CValidaHeaders.create;
    if AutorizaClient.autorizaClient(req, Res, next, LConfServer, true) = true then
    begin
      LConteudo := req.Body<TJsonObject>;
      LConteudo.TryGetValue<string>('username', Lusuario);
      LConteudo.TryGetValue<string>('password', LSenha);
      if not LService.permitirAcesso(Lusuario, LSenha) then
      begin
        Res.Send(TJSONArray.Create(TJSONObject.Create(TJSONPair.Create('ERROR', 'Usuario nao Autorizado !')))).Status(THTTPStatus.Unauthorized);
      end
      else
      begin
        TClaims := LService.TClaims;
        if LService.logoutOp(TClaims.Id, pdv_header, estacao_header, unidade_header) = true then
        begin
          Res.Send(TJSONArray.Create(TJSONObject.Create(TJSONPair.Create('logout', TJSONBool.Create(true))))).Status(THTTPStatus.Unauthorized);
        end
        else
          Res.Send(TJSONArray.Create(TJSONObject.Create(TJSONPair.Create('logout', TJSONBool.Create(false))))).Status(THTTPStatus.Unauthorized);
      end;
    end;
  finally
    LDao.destroy;
    AutorizaClient.Free;
    LUtils.Free;
    LService.destroy;
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

procedure efetuarLogin(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LConteudo, LToken: TJsonObject;
  Lusuario, LSenha, unidade_header, estacao_header, pdv_header, credential_header, credential_conf: string;
  LService: daoAuth;
  TClaims: TMyClaims;
  bconectado, estacao_ocupada: boolean;
  LPdv: TJSONObject;
  LUtils: TUtils;
  tTimeLocal: TSQLTimeStamp;
  LDao: dao;
  acess_validation: boolean;
  AutorizaClient: CValidaHeaders;
begin
  try
    AutorizaClient := CValidaHeaders.create;
    LService := daoAuth.Create;
    LDao := dao.Create;
    LPdv := TJSONObject.Create;
    LUtils := TUtils.Create;
    Req.Headers.TryGetValue('X-Pdv', pdv_header);
    Req.Headers.TryGetValue('X-Credential', credential_header);
    Req.Headers.TryGetValue('X-unidade', unidade_header);
    Req.Headers.TryGetValue('X-estacao', estacao_header);
    tTimeLocal := VarToSQLTimeStamp(VarSQLTimeStampCreate(now));
    LDao.insertClientReq(LUtils.ClientIP(Req), Req.Body, 'login', tTimeLocal);
    acess_validation := false;
    acess_validation := AutorizaClient.autorizaClient(Req, Res, Next, LConfServer, true);
    Res.AddHeader('X-server', versao_app);
    if (acess_validation = true) then
    begin
      estacao_ocupada := false;
      LConteudo := Req.Body<TJsonObject>;
      bconectado := LService.verificaEstOnOf(estacao_header, unidade_header);
      estacao_ocupada := LService.verificaPdvEst(pdv_header, estacao_header, unidade_header);
      if (bconectado = true) and (estacao_ocupada = true) then
      begin
        LConteudo.TryGetValue<string>('username', Lusuario);
        LConteudo.TryGetValue<string>('password', LSenha);
        if not LService.permitirAcesso(Lusuario, LSenha) then
        begin
          Res.Send(TJSONArray.Create(TJSONObject.Create(TJSONPair.Create('ERROR', 'Usuario nao Autorizado !')))).Status(THTTPStatus.Unauthorized);
        end
        else
        begin
          try
            TClaims := LService.TClaims;
            if (TClaims <> nil) and (trim(TClaims.Id) <> '') then
            begin
              LToken := TJsonObject.Create;
              LToken.AddPair('access', getToken(incHour(now), TClaims));
              LToken.AddPair('refresh', getToken(IncMonth(now), TClaims));
              LPdv.AddPair('pdv', pdv_header);
              LPdv.AddPair('op', TClaims.id);
              LPdv.AddPair('unidade', unidade_header);
              LPdv.AddPair('estacao', estacao_header);
              LService.saveClientPdv(LPdv);
              Res.Send(TJSONArray.Create(LToken)).Status(THTTPStatus.OK);
            end
            else
            begin
              Res.Send(TJSONArray.Create(TJSONObject.Create(TJSONPair.Create('ERROR', 'Usuario invalido !')))).Status(THTTPStatus.Unauthorized);
            end;
          finally
            if Assigned(TClaims) then
              TClaims.Free;
          end;
        end;
      end
      else
        Res.Send(TJSONArray.Create(TJSONObject.Create(TJSONPair.Create('ERROR', 'Nao autorizado !')))).Status(THTTPStatus.Unauthorized);
    end

  finally
    if Assigned(LService) then
      LService.destroy;
    if Assigned(LDao) then
      LDao.destroy;
    if Assigned(LPdv) then
      LPdv.Free;
    if Assigned(LUtils) then
      LUtils.Free;
    AutorizaClient.Free;
  end;

end;

procedure refreshToken(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LClaims: TMyClaims;
  LId, LName, LoUTRO, LCpf, LToken: string;
begin
  if autorizaAcess(Req, Res, Next) = true then
  begin
    LClaims := Req.Session<TMyClaims>;
    LId := LClaims.Id;
    LName := LClaims.Name;
    LCpf := LClaims.cpf;
    LoUTRO := LClaims.outro;
    LToken := getToken(IncHour(now), LClaims);
    Res.Send(TJSONObject.Create(TJSONPair.Create('access', LToken))).Status(THTTPStatus.ok);
  end;
end;

end.

