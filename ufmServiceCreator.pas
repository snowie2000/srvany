unit ufmServiceCreator;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, ShellAPI, ExtCtrls;

type
  TfrmSvcCreator = class(TForm)
    grp1: TGroupBox;
    lblID: TLabel;
    edtName: TEdit;
    lbl1: TLabel;
    edtDisp: TEdit;
    lbl2: TLabel;
    edtDesp: TEdit;
    grp2: TGroupBox;
    lblApp: TLabel;
    btn1: TButton;
    lbl3: TLabel;
    edtParam: TEdit;
    lblExe: TLabel;
    grp3: TGroupBox;
    rb1: TRadioButton;
    rb2: TRadioButton;
    edtEndCmd: TEdit;
    btn2: TButton;
    rg1: TRadioGroup;
    lbl4: TLabel;
    edtDir: TEdit;
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure rb1Click(Sender: TObject);
    procedure rb2Click(Sender: TObject);
  private
    FFileName: string;
    { Private declarations }
    procedure SaveSettings();
  public
    { Public declarations }
  end;

var
  frmSvcCreator: TfrmSvcCreator;

implementation

uses
  uSimpleXml, uSrvMain;

{$R *.dfm}

procedure TfrmSvcCreator.btn1Click(Sender: TObject);
begin
  with TOpenDialog.Create(nil) do
  begin
    Options := [ofFileMustExist, ofNoNetworkButton, ofForceShowHidden];
    Filter := 'Executables|*.exe;*.com;*.scr|All files|*.*';
    DefaultExt := '.exe';
    if Execute(Handle) then
    begin
      lblExe.Caption := FileName;
      lblExe.Hint := FileName;
      FFileName := FileName;
      edtDir.Text := ExtractFileDir(FileName);
    end;
  end;
end;

procedure TfrmSvcCreator.btn2Click(Sender: TObject);
var
  si: TShellExecuteInfo;
  s: string;
  I: Integer;
begin
  s := Trim(edtName.Text);
  edtName.Text := s;
  if edtName.Text = '' then
  begin
    Application.MessageBox('Input service name.', 'srvany', MB_OK or MB_ICONWARNING);
    Exit;
  end;
  if not ((s[1] in ['a'..'z']) or (s[1] in ['A'..'Z'])) then
  begin
    Application.MessageBox('Service name must start with alphabet.', 'srvany', MB_OK or MB_ICONWARNING);
    Exit;
  end;
  for I := 1 to Length(s) do
    if not (Ord(s[I]) in [33..127]) then
    begin
      Application.MessageBox('Service name contains invalid characters.', 'srvany', MB_OK or MB_ICONWARNING);
      Exit;
    end;

  if FFileName = '' then
  begin
    Application.MessageBox('Select a file to serve.', 'srvany', MB_OK or MB_ICONWARNING);
    Exit;
  end;
  if rb2.Checked and (edtEndCmd.Text = '') then
    rb1.Checked := True;
  SaveSettings();
  FillChar(si, SizeOf(si), 0);
  si.cbSize := SizeOf(si);
  si.lpParameters := '/install';
  si.lpFile := PChar(ParamStr(0));
  si.nShow := SW_SHOW;
  if ShellExecuteEx(@si) then
    WaitForSingleObject(si.hProcess, INFINITE);
  CloseHandle(si.hProcess);
  Close;
end;

procedure TfrmSvcCreator.rb1Click(Sender: TObject);
begin
  with edtEndCmd do
  begin
    Enabled := False;
    Color := clBtnFace;
  end;
end;

procedure TfrmSvcCreator.rb2Click(Sender: TObject);
begin
  with edtEndCmd do
  begin
    Enabled := True;
    Color := clWindow;
    SetFocus;
  end;
end;

procedure TfrmSvcCreator.SaveSettings;
var
  node: TXmlNode;
begin
  with TSimpleXml.Create do
  try
    ReadFromString('<service></service>');
    Utf8Encoded := True;
    node := Root.NewNode('id');
    node.ValueAsString := edtName.Text;
    node := Root.NewNode('name');
    node.ValueAsString := edtDisp.Text;
    node := Root.NewNode('description');
    node.ValueAsString := edtDesp.Text;
    node := Root.NewNode('directory');
    node.ValueAsString := edtDir.Text;
    node := Root.NewNode('executable');
    node.ValueAsString := FFileName;
    node := Root.NewNode('startargument');
    node.ValueAsString := edtParam.Text;
    node := Root.NewNode('stopargument');
    if rb2.Checked then
      node.ValueAsString := edtEndCmd.Text;
    node := Root.NewNode('behavior');
    node.ValueAsInteger := rg1.ItemIndex;
    SaveToFile(ReplaceFileExt(ParamStr(0), '.xml'));
  finally
    Free;
  end;
end;

end.

