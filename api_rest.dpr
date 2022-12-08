program api_rest;
{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  System.IniFiles,
  Horse,
  Horse.OctetStream,
  Horse.Compression,
  Horse.Jhonson,
  Horse.GBSwagger,
  Horse.HandleException,
  Horse.JWT,
  Horse.RateLimit,
  System.JSON,
  Horse.Etag,
  Horse.Logger.Provider.LogFile,
  Horse.Exception.Logger,
  Horse.Logger.Manager,
  providers.connection.dao in 'src\providers\connection\providers.connection.dao.pas',
  controllers.mc_produto in 'src\controllers\controllers.mc_produto.pas',
  services.auth in 'src\services\services.auth.pas',
  services.produto in 'src\services\services.produto.pas',
  UConstApp in 'src\utils\UConstApp.pas',
  MyClaims in 'src\controllers\auth\MyClaims.pas',
  controllers.mc_login in 'src\controllers\auth\controllers.mc_login.pas';

var
  ArqIni: TIniFile;
  port, identit: Integer;
  caminho: string;
  provider_connection: TFRDConnection;
  LLogFileConfig: THorseLoggerLogFileConfig;
  HorseLoggerConfig: THorseExceptionLoggerConfig;
  bController_time, bcontroller_insert: Boolean;

begin
  caminho := ExtractFileDir(ParamStr(0));
  THorse.MaxConnections := 15000;
  port := 9600;
//  try
//    ArqIni := TIniFile.Create(caminho + '/serverconfig.ini');
//    try
//      identit := ArqIni.ReadInteger('identity', 'id', 0);
//      provider_connection := TFRDConnection.Create(nil);
//      if provider_connection.connectar = false then
//      begin
//        provider_connection.verificarBase;
//      end;
//
//      if provider_connection.connectar = false then
//      begin
//        Writeln('Sem conexao com o banco !!!!');
//      end
//    except
//      on E: Exception do
//        Writeln('Error 309: ' + E.Message);
//    end;
//  finally
//    provider_connection.destroy;
//    ArqIni.Free;
//  end;
  controllers.mc_produto.registry;
  controllers.mc_login.registry;
  ReportMemoryLeaksOnShutdown := true;
  CAMINHO := ExtractFileDir(GetCurrentDir);
  HorseLoggerConfig := THorseExceptionLoggerConfig.Create('ERROR  ${exception} ;Param: ${request_query}, ${request_clientip} [${time}] ${request_user_agent} "${request_method} ${request_path_info} ${request_version}" ${response_status} ${response_content_length}', CAMINHO);
  LLogFileConfig := THorseLoggerLogFileConfig.New.SetLogFormat('Time ${execution_time} , Param: ${request_query} ,${request_internal_path_info}, Client ${request_clientip}, [${time}], ${request_user_agent}, "${request_method} ${request_path_info} " ${response_status} ');
  THorseLoggerManager.RegisterProvider(THorseLoggerProviderLogFile.New(LLogFileConfig));
  THorse.Use(THorseExceptionLogger.New(HorseLoggerConfig));
  THorse.Use(THorseLoggerManager.HorseCallback);
  THorse.Use(Compression());
  THorse.Use(Jhonson());
  THorse.Use(Etag);
  THorse.Use(HandleException);
  THorse.Use(OctetStream);
  THorse.Listen(port,
    procedure(Horse: THorse)
    begin
      Writeln(Format('Server is runing on %d', [Horse.Port]));
      Readln;
    end);

end.

