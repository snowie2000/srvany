unit uSrvMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs, uGoLang, Registry, WinSvc;

type
  TService1 = class(TService)
    procedure ServiceAfterInstall(Sender: TService);
    procedure ServiceExecute(Sender: TService);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceShutdown(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
  private
    { Private declarations }
  public
    FExe: string;
    FCmd: string;
    FFolder: string;
    FSvcStopCmd: string;
    FDesp: string;
    FMainThreadId: Cardinal;
    FProcessHandle: THandle;
    FnBehavior: Integer;
    FbRelaunch: Boolean;
    FhStdErrRead, FhStdErrWrite, FhStdOutRead, FhStdOutWrite: THandle;
    function GetServiceController: TServiceController; override;
    procedure ReadFromErrorPipe();
    procedure ReadFromOutputPipe();
    { Public declarations }
  end;

function ReplaceFileExt(AsFileName, AsNewExt: string): string;

procedure Touch(AsFileName: string);

var
  Service1: TService1;

implementation

{$R *.DFM}

function ReplaceFileExt(AsFileName, AsNewExt: string): string;
var
  sExt: string;
begin
  sExt := ExtractFileExt(AsFileName);
  Result := AsFileName;
  Delete(Result, Length(AsFileName) - Length(sExt) + 1, Length(sExt));
  Result := Result + AsNewExt;
end;

procedure Touch(AsFileName: string);
begin
  CloseHandle(CreateFile(PChar(AsFileName), GENERIC_ALL, 0, nil, CREATE_NEW, 0, 0));
end;

procedure ServiceController(CtrlCode: DWORD); stdcall;
begin
  Service1.Controller(CtrlCode);
end;

function TService1.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TService1.ReadFromErrorPipe;
var
  buf: array[0..4095] of Byte;
  bSuccess: Boolean;
  n: Cardinal;
  f: TFileStream;
  sErrLog: string;
begin
  sErrLog := ReplaceFileExt(ParamStr(0), '.err.log');
  if not FileExists(sErrLog) then
    Touch(sErrLog);
  f := TFileStream.Create(sErrLog, fmOpenReadWrite or fmShareDenyNone);
  f.Seek(0, soEnd);
  try
    repeat
      bSuccess := ReadFile(FhStdErrRead, buf[0], 4096, n, nil);
      if (not bSuccess) or (n = 0) then
        Break;
      try
        f.Seek(0, soEnd);
        f.Write(buf[0], n);
      except
      end;
    until not bSuccess;
  finally
    f.Free;
  end;
end;

procedure TService1.ReadFromOutputPipe;
var
  buf: array[0..4095] of Byte;
  bSuccess: Boolean;
  n: Cardinal;
  f: TFileStream;
  sErrLog: string;
begin
  sErrLog := ReplaceFileExt(ParamStr(0), '.out.log');
  if not FileExists(sErrLog) then
    Touch(sErrLog);
  f := TFileStream.Create(sErrLog, fmOpenReadWrite or fmShareDenyNone);
  f.Seek(0, soEnd);
  try
    repeat
      bSuccess := ReadFile(FhStdErrRead, buf[0], 4096, n, nil);
      if (not bSuccess) or (n = 0) then
        Break;
      try
        f.Seek(0, soEnd);
        f.Write(buf[0], n);
      except
      end;
    until not bSuccess;
  finally
    f.Free;
  end;
end;

procedure TService1.ServiceAfterInstall(Sender: TService);
begin
  with TRegistry.Create do
  try
    RootKey := HKEY_LOCAL_MACHINE;
    OpenKey('\SYSTEM\CurrentControlSet\services\' + Self.Name, True);
    WriteString('Description', FDesp);
  finally
    Free;
  end;
end;

procedure TService1.ServiceExecute(Sender: TService);
begin
  //
end;

procedure TService1.ServicePause(Sender: TService; var Paused: Boolean);
begin
  FbRelaunch := False;
end;

procedure TService1.ServiceShutdown(Sender: TService);
begin
  FbRelaunch := False;
end;

procedure TService1.ServiceStart(Sender: TService; var Started: Boolean);
var
  si: TStartupInfo;
  hThread: THandle;
  Pi: TProcessInformation;
  sa: SECURITY_ATTRIBUTES;
begin
  if not FileExists(FExe) then
  begin
    Started := False;
    Exit;
  end;
  FbRelaunch := True;
  FillChar(si, SizeOf(si), 0);
  FillChar(Pi, SizeOf(Pi), 0);
  si.cb := SizeOf(si);
  si.wShowWindow := SW_HIDE;
  si.dwFlags := si.dwFlags or STARTF_USESTDHANDLES;

  FillChar(sa, SizeOf(sa), 0);
  sa.nLength := SizeOf(sa);
  sa.lpSecurityDescriptor := nil;
  sa.bInheritHandle := True;
  si.cb := SizeOf(si);
//create pipes
  if FnBehavior <> 2 then  //3=exit after launching, no need to create pipes.
  begin
    if CreatePipe(FhStdErrRead, FhStdErrWrite, @sa, 0) then
      si.hStdError := FhStdErrWrite;
    SetHandleInformation(FhStdErrRead, HANDLE_FLAG_INHERIT, 0);
    if CreatePipe(FhStdOutRead, FhStdOutWrite, @sa, 0) then
      si.hStdOutput := FhStdOutWrite;
    SetHandleInformation(FhStdOutRead, HANDLE_FLAG_INHERIT, 0);
  end;

  hThread := mgo(
    procedure()
    var
      bLaunched: Boolean;
    begin
      repeat
        bLaunched := False;
        if CreateProcess(nil, PChar(FExe + ' ' + FCmd), nil, nil, True, 0, nil, nil, si, Pi) then
        begin
          bLaunched := True;
          FProcessHandle := Pi.hProcess;
          FMainThreadId := Pi.dwThreadId;
          CloseHandle(Pi.hThread);
          if Self.FnBehavior <> 2 then
            WaitForSingleObject(Pi.hProcess, INFINITE);
          CloseHandle(Pi.hProcess);
        end;
        case Self.FnBehavior of
          1:
            Continue;
        else
          begin
            if Assigned(Self.ServiceThread) then
              PostThreadMessage(Self.ServiceThread.ThreadID, CM_SERVICE_CONTROL_CODE, SERVICE_CONTROL_STOP, 1);
            Break;
          end;
        end;
      until not FbRelaunch;
      CloseHandle(FhStdErrWrite);
      CloseHandle(FhStdOutWrite);
    end);

  if FnBehavior <> 2 then
  begin
    go(ReadFromErrorPipe);
    go(ReadFromOutputPipe);
  end;

  if FnBehavior = 2 then
  begin
//    Self.OnExecute := Self.ServiceExecute;
    WaitForSingleObject(hThread, INFINITE);
    Started := False;
  end;
  CloseHandle(hThread);
end;

procedure TService1.ServiceStop(Sender: TService; var Stopped: Boolean);
var
  si: TStartupInfo;
  Pi: TProcessInformation;
begin
  FbRelaunch := False;
  FillChar(si, SizeOf(si), 0);
  FillChar(Pi, SizeOf(Pi), 0);
  si.wShowWindow := SW_HIDE;
  if FSvcStopCmd <> '' then
  begin
    if CreateProcess(nil, PChar(FSvcStopCmd), nil, nil, False, 0, nil, nil, si, Pi) then
      if WaitForSingleObject(Pi.hProcess, 60000) = WAIT_TIMEOUT then
        TerminateProcess(Pi.hProcess, 1);
  end;
//  PostThreadMessage(FMainThreadId, WM_QUIT, 0, 0);
//  if WaitForSingleObject(FProcessHandle, 2000) = WAIT_TIMEOUT then
  TerminateProcess(FProcessHandle, 1);
  //CloseHandle(FProcessHandle);
  Stopped := True;
end;

end.


