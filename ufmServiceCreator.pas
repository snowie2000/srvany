unit ufmServiceCreator;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, ShellAPI;

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
    end;
  end;
end;

procedure TfrmSvcCreator.btn2Click(Sender: TObject);
begin
  if edtName.Text = '' then
  begin
    Application.MessageBox('Input service name.', 'srvany', MB_OK or MB_ICONWARNING);
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
  ShellExecute(Handle, nil, PChar(ParamStr(0)), '/install', nil, SW_SHOW);
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
    node := Root.NewNode('executable');
    node.ValueAsString := FFileName;
    node := Root.NewNode('startargument');
    node.ValueAsString := edtParam.Text;
    node := Root.NewNode('stopargument');
    if rb2.Checked then
      node.ValueAsString := edtEndCmd.Text;
    SaveToFile(ReplaceFileExt(ParamStr(0), '.xml'));
  finally
    Free;
  end;
end;

end.


