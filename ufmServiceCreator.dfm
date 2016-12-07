object frmSvcCreator: TfrmSvcCreator
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Service creator'
  ClientHeight = 438
  ClientWidth = 356
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  DesignSize = (
    356
    438)
  PixelsPerInch = 96
  TextHeight = 13
  object grp1: TGroupBox
    Left = 8
    Top = 8
    Width = 340
    Height = 110
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Service infomation'
    TabOrder = 0
    object lblID: TLabel
      Left = 9
      Top = 24
      Width = 27
      Height = 13
      Caption = 'Name'
    end
    object lbl1: TLabel
      Left = 9
      Top = 51
      Width = 61
      Height = 13
      Caption = 'DisplayName'
    end
    object lbl2: TLabel
      Left = 9
      Top = 78
      Width = 53
      Height = 13
      Caption = 'Description'
    end
    object edtName: TEdit
      Left = 83
      Top = 21
      Width = 242
      Height = 21
      TabOrder = 0
    end
    object edtDisp: TEdit
      Left = 83
      Top = 48
      Width = 242
      Height = 21
      TabOrder = 1
    end
    object edtDesp: TEdit
      Left = 83
      Top = 75
      Width = 242
      Height = 21
      TabOrder = 2
    end
  end
  object grp2: TGroupBox
    Left = 8
    Top = 126
    Width = 340
    Height = 81
    Caption = 'CommandLine'
    TabOrder = 1
    object lblApp: TLabel
      Left = 9
      Top = 22
      Width = 52
      Height = 13
      Caption = 'Application'
    end
    object lbl3: TLabel
      Left = 9
      Top = 47
      Width = 55
      Height = 13
      Caption = 'Parameters'
    end
    object lblExe: TLabel
      Left = 149
      Top = 22
      Width = 164
      Height = 13
      AutoSize = False
      Caption = 'Select file'
      EllipsisPosition = epPathEllipsis
      ParentShowHint = False
      ShowHint = True
    end
    object btn1: TButton
      Left = 83
      Top = 18
      Width = 60
      Height = 23
      Caption = 'browse'
      TabOrder = 0
      OnClick = btn1Click
    end
    object edtParam: TEdit
      Left = 83
      Top = 46
      Width = 242
      Height = 21
      TabOrder = 1
    end
  end
  object grp3: TGroupBox
    Left = 8
    Top = 215
    Width = 340
    Height = 81
    Caption = 'Termination'
    TabOrder = 2
    object rb1: TRadioButton
      Left = 9
      Top = 24
      Width = 113
      Height = 17
      Caption = 'Kill application'
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = rb1Click
    end
    object rb2: TRadioButton
      Left = 9
      Top = 47
      Width = 97
      Height = 17
      Caption = 'Run command'
      TabOrder = 1
      OnClick = rb2Click
    end
    object edtEndCmd: TEdit
      Left = 113
      Top = 45
      Width = 212
      Height = 21
      Color = clBtnFace
      Enabled = False
      TabOrder = 2
    end
  end
  object btn2: TButton
    Left = 144
    Top = 405
    Width = 75
    Height = 25
    Anchors = [akBottom]
    Caption = 'Install'
    TabOrder = 3
    OnClick = btn2Click
  end
  object rg1: TRadioGroup
    Left = 8
    Top = 302
    Width = 340
    Height = 91
    Caption = 'Behavior'
    ItemIndex = 0
    Items.Strings = (
      'Exit with guest app'
      'Relaunch guest if crashed'
      'Exit after launching guest app')
    TabOrder = 4
  end
end
