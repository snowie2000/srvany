// JCL_DEBUG_EXPERT_INSERTJDBG OFF
program srvany;

uses
  Forms,
  SvcMgr,
  uSimpleXml,
  SysUtils,
  uSrvMain in 'uSrvMain.pas' {Service1: TService},
  ufmServiceCreator in 'ufmServiceCreator.pas' {frmSvcCreator};

{$R *.RES}

function InitServiceInfo(): Boolean;
var
  sXmlFile: string;
  sXmlExt: string;
begin
  Result := True;
  with uSimpleXml.TSimpleXml.Create do
  try
    sXmlFile := ReplaceFileExt(ParamStr(0), '.xml');
    if not FileExists(sXmlFile) then
      Exit(False);
    LoadFromFile(sXmlFile);
    with Service1 do
    begin
      Name := Root.FindNode('id').ValueAsString;
      DisplayName := Root.FindNode('name').ValueAsString;
      FExe := Root.FindNode('executable').ValueAsString;
      FCmd := Root.FindNode('startargument').ValueAsString;
      FSvcStopCmd := Root.FindNode('stopargument').ValueAsString;
      FDesp := Root.FindNode('description').ValueAsString;
    end;
  finally
    Free;
  end;
end;

var
  a: Boolean;

begin
  // Windows 2003 Server requires StartServiceCtrlDispatcher to be
  // called before CoRegisterClassObject, which can be called indirectly
  // by Application.Initialize. TServiceApplication.DelayInitialize allows
  // Application.Initialize to be called from TService.Main (after
  // StartServiceCtrlDispatcher has been called).
  //
  // Delayed initialization of the Application object may affect
  // events which then occur prior to initialization, such as
  // TService.OnCreate. It is only recommended if the ServiceApplication
  // registers a class object with OLE and is intended for use with
  // Windows 2003 Server.
  //
  // Application.DelayInitialize := True;
  //
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TService1, Service1);
//  Application.CreateForm(TfrmSvcCreator, frmSvcCreator);
  if InitServiceInfo() then
//    Service1.OnStart(nil, a);
//  forms.Application.Run;
    Application.Run
  else
  begin
    Forms.Application.ShowMainForm := True;
    Forms.Application.CreateForm(TfrmSvcCreator, frmSvcCreator);
    Forms.Application.Run;
  end;
end.


