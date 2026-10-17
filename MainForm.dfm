object BackupTrackerForm: TBackupTrackerForm
  Left = 0
  Top = 0
  Caption = #22791#20221#20219#21153#36319#36394#22120
  ClientHeight = 620
  ClientWidth = 1000
  Color = clWhite
  Constraints.MinHeight = 540
  Constraints.MinWidth = 900
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    1000
    620)
  TextHeight = 20
  object TitleLabel: TLabel
    Left = 28
    Top = 24
    Width = 600
    Height = 40
    AutoSize = False
    Caption = #22791#20221#20219#21153#36319#36394#22120
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -28
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object IntroLabel: TLabel
    Left = 28
    Top = 72
    Width = 368
    Height = 20
    Caption = #30331#35760#22791#20221#24037#20316#65292#25163#21160#36319#36394#24453#22788#29702#12289#36827#34892#20013#21644#24050#23436#25104#12290
  end
  object NameLabel: TLabel
    Left = 28
    Top = 120
    Width = 64
    Height = 20
    Caption = #20219#21153#21517#31216
    FocusControl = TaskNameEdit
  end
  object ResourceLabel: TLabel
    Left = 584
    Top = 120
    Width = 64
    Height = 20
    Anchors = [akTop, akRight]
    Caption = #36164#28304#31867#22411
    FocusControl = ResourceCombo
  end
  object SummaryLabel: TLabel
    Left = 28
    Top = 220
    Width = 900
    Height = 24
    AutoSize = False
    Caption = #20849' 0 '#39033
  end
  object StatusLabel: TLabel
    Left = 28
    Top = 562
    Width = 944
    Height = 22
    Anchors = [akLeft, akBottom]
    AutoSize = False
    Caption = #20808#26032#22686#19968#39033#20219#21153#65292#20877#36873#25321#34892#26356#26032#36827#24230#12290
  end
  object SessionLabel: TLabel
    Left = 28
    Top = 594
    Width = 364
    Height = 15
    Anchors = [akLeft, akBottom]
    Caption = #20219#21153#35760#24405#20445#23384#22312#26412#27425#31383#21475#20013#65292#20851#38381#21518#28165#31354#65307#29366#24577#30001#20320#25163#21160#26356#26032#12290
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGrayText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object TaskNameEdit: TEdit
    Left = 28
    Top = 152
    Width = 532
    Height = 42
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    MaxLength = 80
    TabOrder = 0
    TextHint = #20363#22914#65306#19994#21153#37197#32622#27599#26085#22791#20221
  end
  object ResourceCombo: TComboBox
    Left = 584
    Top = 152
    Width = 200
    Height = 38
    Style = csOwnerDrawFixed
    Anchors = [akTop, akRight]
    ItemHeight = 32
    ItemIndex = 0
    TabOrder = 1
    Text = #25991#20214
    OnChange = ResourceComboChange
    OnDrawItem = ResourceComboDrawItem
    Items.Strings = (
      #25991#20214
      #25968#25454#24211
      #34394#25311#26426)
  end
  object AddButton: TButton
    Left = 808
    Top = 152
    Width = 164
    Height = 42
    Anchors = [akTop, akRight]
    Caption = #26032#22686#20219#21153
    Default = True
    TabOrder = 2
    OnClick = AddButtonClick
  end
  object TaskGrid: TStringGrid
    Left = 28
    Top = 256
    Width = 944
    Height = 230
    Anchors = [akLeft, akTop, akRight, akBottom]
    ColCount = 4
    DefaultRowHeight = 36
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRowSelect, goThumbTracking]
    TabOrder = 3
    OnSelectCell = TaskGridSelectCell
  end
  object StartButton: TButton
    Left = 28
    Top = 506
    Width = 180
    Height = 40
    Anchors = [akLeft, akBottom]
    Caption = #26631#35760#36827#34892#20013
    Enabled = False
    TabOrder = 4
    OnClick = StartButtonClick
  end
  object CompleteButton: TButton
    Left = 224
    Top = 506
    Width = 180
    Height = 40
    Anchors = [akLeft, akBottom]
    Caption = #26631#35760#23436#25104
    Enabled = False
    TabOrder = 5
    OnClick = CompleteButtonClick
  end
  object RemoveButton: TButton
    Left = 792
    Top = 506
    Width = 180
    Height = 40
    Anchors = [akRight, akBottom]
    Caption = #31227#38500#35760#24405
    Enabled = False
    TabOrder = 6
    OnClick = RemoveButtonClick
  end
end
