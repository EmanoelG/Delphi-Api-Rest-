unit providers.connection.dao;

interface

uses
  Horse, System.JSON, System.StrUtils, System.SysUtils, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.ConsoleUI.Wait, Data.DB, FireDAC.Comp.Client, FireDAC.Phys.PG,
  FireDAC.Phys.PGDef, System.Classes;

type
  TFRDConnection = class
  private
    FConnection: TFDConnection;
    driveLinkPg: TFDPhysPgDriverLink;
    FConnectar: Boolean;
    function connectarBD: Boolean;

    const
      cNameConnDef = 'pg_pooledteste';
  public

    property connection: TFDConnection read FConnection write FConnection;
    property connectar: Boolean read FConnectar write FConnectar;
    constructor Create(AOwner: TComponent);
    destructor destroy;
    procedure createDefName;
    procedure verificarBase;

  end;

var
  GLOBAL_CONNECTION: TFRDConnection;

implementation

uses
  System.IniFiles;

{ TFRDConnection }

function TFRDConnection.connectarBD: Boolean;
begin

  try
    FConnection.ConnectionDefName := cNameConnDef;
    FConnection.Connected := true;
    connectar := FConnection.Connected;
    Result := FConnection.Connected;
  except
    on E: Exception do
      Writeln('error 50' + e.Message);
  end;

end;

constructor TFRDConnection.Create(AOwner: TComponent);
begin
  FConnection := TFDConnection.Create(nil);
  driveLinkPg := TFDPhysPgDriverLink.Create(nil);
  connectar := connectarBD;
end;

procedure TFRDConnection.createDefName;
var
  oDef: IFDStanConnectionDef;
  oParams: TFDPhysPGConnectionDefParams;
  caminho: string;
  ArqIni: TIniFile;
  sNameBase, sAddress, sUser, sPassword, sDriverId: string;
  bPooled: Boolean;
  iPort, iPoolMaxConnection, iPoolexpireTimeout, iPoolCleanTimeOut: Integer;
begin
  caminho := ExtractFileDir(ParamStr(0));
  ArqIni := TIniFile.Create(caminho + '\base_app.ini');
  try
    sNameBase := ArqIni.ReadString('namebase', 'namebase', 'null');
    sAddress := ArqIni.ReadString('address', 'address', 'localhost');
    sUser := ArqIni.ReadString('user_name', 'username', 'user');
    sPassword := ArqIni.ReadString('password', 'password', '123456');
    sDriverId := ArqIni.ReadString('driver_id', 'driverid', 'PG');
    bPooled := ArqIni.ReadBool('pool', 'pooled', true);
    iPort := ArqIni.ReadInteger('porta', 'port', 5432);
    iPoolMaxConnection := ArqIni.ReadInteger('poolmaxitems', 'poolmaxitems', 1000);
    iPoolCleanTimeOut := ArqIni.ReadInteger('poolcleanuptimeout', 'poolcleantime', 15000);
    iPoolexpireTimeout := ArqIni.ReadInteger('poolexpiretimeout', 'poolexpire', 4500);
  finally
    ArqIni.Free;
  end;
  FDManager.ConnectionDefs.AddConnectionDef;
  oDef := FDManager.ConnectionDefs.AddConnectionDef;
  oDef.Name := cNameConnDef;
  oParams := TFDPhysPGConnectionDefParams(oDef.Params);
  oParams.Pooled := bPooled;
  oParams.Database := sNameBase;
  oParams.UserName := sUser;
  oParams.Password := sPassword;
  oParams.Server := sAddress;
  oParams.port := iPort;
  oParams.PoolCleanupTimeout := iPoolCleanTimeOut;
  oParams.PoolExpireTimeout := iPoolexpireTimeout;
  oParams.PoolMaximumItems := iPoolMaxConnection;
  oParams.DriverID := sDriverId;
  oDef.MarkPersistent;
  oDef.Apply;
  connectarBD;
end;

destructor TFRDConnection.destroy;
begin
  FreeAndNil(FConnection);
  FreeAndNil(driveLinkPg);
end;

procedure TFRDConnection.verificarBase;
var
  iCoubt: Integer;
  I: Integer;
  bVerifica: Boolean;
  sName: string;
begin
  bVerifica := false;
  for I := 0 to FDManager.ConnectionDefs.Count - 1 do
  begin
    sName := FDManager.ConnectionDefs.Items[I].Name;
    if sName = cNameConnDef then
    begin
      bVerifica := true
    end;
  end;
  if bVerifica = false then
    createDefName;
end;

end.

