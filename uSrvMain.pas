unit uSrvMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs, uGoLang, Registry;

type
  TService1 = class(TService)
    procedure ServiceAfterInstall(Sender: TService);
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
      f.Write(buf[0], n);
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
      f.Write(buf[0], n);
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

procedure TService1.ServiceStart(Sender: TService; var Started: Boolean);
var
  si: TStartupInfo;
  Pi: TProcessInformation;
  sa: SECURITY_ATTRIBUTES;
begin
  if not FileExists(FExe) then
  begin
    Started := False;
    Exit;
  end;
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
  if CreatePipe(FhStdErrRead, FhStdErrWrite, @sa, 0) then
    si.hStdError := FhStdErrWrite;
  SetHandleInformation(FhStdErrRead, HANDLE_FLAG_INHERIT, 0);
  if CreatePipe(FhStdOutRead, FhStdOutWrite, @sa, 0) then
    si.hStdOutput := FhStdOutWrite;
  SetHandleInformation(FhStdOutRead, HANDLE_FLAG_INHERIT, 0);

  go(
    procedure()
    begin
      if CreateProcess(nil, PChar(FExe + ' ' + FCmd), nil, nil, True, 0, nil, nil, si, Pi) then
      begin
        FProcessHandle := Pi.hProcess;
        FMainThreadId := Pi.dwThreadId;
        CloseHandle(Pi.hThread);
        WaitForSingleObject(Pi.hProcess, INFINITE);
        CloseHandle(Pi.hProcess);
        CloseHandle(FhStdErrWrite);
        CloseHandle(FhStdOutWrite);
      end;
    end);
  go(ReadFromErrorPipe);
  go(ReadFromOutputPipe);
end;

procedure TService1.ServiceStop(Sender: TService; var Stopped: Boolean);
var
  si: TStartupInfo;
  Pi: TProcessInformation;
begin
  FillChar(si, SizeOf(si), 0);
  FillChar(Pi, SizeOf(Pi), 0);
  si.wShowWindow := SW_HIDE;
  if FSvcStopCmd <> '' then
  begin
    if CreateProcess(nil, PChar(FSvcStopCmd), nil, nil, False, 0, nil, nil, si, Pi) then
      if WaitForSingleObject(Pi.hProcess, 60000) = WAIT_TIMEOUT then
        TerminateProcess(Pi.hProcess, 1);
  end;
  PostThreadMessage(FMainThreadId, WM_QUIT, 0, 0);
  if WaitForSingleObject(FProcessHandle, 2000) = WAIT_TIMEOUT then
    TerminateProcess(FProcessHandle, 1);
  CloseHandle(FProcessHandle);
  Stopped := True;
end;

end.


