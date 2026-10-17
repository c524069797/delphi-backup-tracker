unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.Grids,
  BackupTasks;

type
  TBackupTrackerForm = class(TForm)
    TitleLabel: TLabel;
    IntroLabel: TLabel;
    NameLabel: TLabel;
    ResourceLabel: TLabel;
    TaskNameEdit: TEdit;
    ResourceCombo: TComboBox;
    AddButton: TButton;
    SummaryLabel: TLabel;
    TaskGrid: TStringGrid;
    StartButton: TButton;
    CompleteButton: TButton;
    RemoveButton: TButton;
    StatusLabel: TLabel;
    SessionLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure AddButtonClick(Sender: TObject);
    procedure StartButtonClick(Sender: TObject);
    procedure CompleteButtonClick(Sender: TObject);
    procedure RemoveButtonClick(Sender: TObject);
    procedure TaskGridSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure ResourceComboDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure ResourceComboChange(Sender: TObject);
  private
    FStore: TBackupTaskStore;
    function SelectedIndex: Integer;
    procedure RefreshGrid(SelectIndex: Integer);
    procedure UpdateButtons(Index: Integer);
    procedure ShowStatus(const Text: string; IsError: Boolean = False);
  end;

var
  BackupTrackerForm: TBackupTrackerForm;

implementation

{$R *.dfm}

procedure TBackupTrackerForm.FormCreate(Sender: TObject);
var
  Inset: Integer;
begin
  FStore := TBackupTaskStore.Create;
  Inset := MulDiv(18, CurrentPPI, 96);
  SendMessage(TaskNameEdit.Handle, EM_SETMARGINS,
    EC_LEFTMARGIN or EC_RIGHTMARGIN, MakeLParam(Inset, Inset));
  TaskGrid.Cells[0, 0] := '任务名称';
  TaskGrid.Cells[1, 0] := '资源类型';
  TaskGrid.Cells[2, 0] := '状态';
  TaskGrid.Cells[3, 0] := '创建时间';
  TaskGrid.ColWidths[0] := MulDiv(340, CurrentPPI, 96);
  TaskGrid.ColWidths[1] := MulDiv(140, CurrentPPI, 96);
  TaskGrid.ColWidths[2] := MulDiv(140, CurrentPPI, 96);
  TaskGrid.ColWidths[3] := MulDiv(240, CurrentPPI, 96);
  RefreshGrid(-1);
end;

procedure TBackupTrackerForm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FStore);
end;

function TBackupTrackerForm.SelectedIndex: Integer;
begin
  Result := TaskGrid.Row - 1;
  if (Result < 0) or (Result >= FStore.Count) then
    Result := -1;
end;

procedure TBackupTrackerForm.UpdateButtons(Index: Integer);
var
  Valid: Boolean;
  State: TBackupState;
begin
  Valid := (Index >= 0) and (Index < FStore.Count);
  StartButton.Enabled := False;
  CompleteButton.Enabled := False;
  RemoveButton.Enabled := False;
  if not Valid then
    Exit;
  State := FStore.Tasks[Index].State;
  StartButton.Enabled := State = bsPending;
  CompleteButton.Enabled := State = bsRunning;
  RemoveButton.Enabled := State <> bsRunning;
end;

procedure TBackupTrackerForm.RefreshGrid(SelectIndex: Integer);
var
  I, Col: Integer;
  Task: TBackupTask;
begin
  if FStore.Count = 0 then
    TaskGrid.RowCount := 2
  else
    TaskGrid.RowCount := FStore.Count + 1;
  for I := 1 to TaskGrid.RowCount - 1 do
    for Col := 0 to TaskGrid.ColCount - 1 do
      TaskGrid.Cells[Col, I] := '';
  if FStore.Count = 0 then
    TaskGrid.Cells[0, 1] := '暂无任务，请先添加'
  else
    for I := 0 to FStore.Count - 1 do
    begin
      Task := FStore.Tasks[I];
      TaskGrid.Cells[0, I + 1] := Task.Name;
      TaskGrid.Cells[1, I + 1] := ResourceCaption(Task.Resource);
      TaskGrid.Cells[2, I + 1] := StateCaption(Task.State);
      TaskGrid.Cells[3, I + 1] := FormatDateTime('mm-dd hh:nn', Task.CreatedAt);
    end;
  if FStore.Count > 0 then
  begin
    if SelectIndex < 0 then SelectIndex := 0;
    if SelectIndex >= FStore.Count then SelectIndex := FStore.Count - 1;
    TaskGrid.Row := SelectIndex + 1;
  end;
  SummaryLabel.Caption := Format('共 %d 项   待处理 %d   进行中 %d   已完成 %d',
    [FStore.Count, FStore.CountByState(bsPending),
    FStore.CountByState(bsRunning), FStore.CountByState(bsCompleted)]);
  UpdateButtons(SelectedIndex);
end;

procedure TBackupTrackerForm.ShowStatus(const Text: string; IsError: Boolean);
begin
  StatusLabel.Caption := Text;
  if IsError then
    StatusLabel.Font.Color := clMaroon
  else
    StatusLabel.Font.Color := clNavy;
end;

procedure TBackupTrackerForm.AddButtonClick(Sender: TObject);
var
  Index: Integer;
begin
  try
    Index := FStore.Add(TaskNameEdit.Text, TBackupResource(ResourceCombo.ItemIndex));
    RefreshGrid(Index);
    TaskNameEdit.Clear;
    ShowStatus('任务已登记，请按实际工作进度更新状态。');
    TaskNameEdit.SetFocus;
  except
    on E: EArgumentException do ShowStatus(E.Message, True);
  end;
end;

procedure TBackupTrackerForm.StartButtonClick(Sender: TObject);
begin
  try
    FStore.Start(SelectedIndex);
    RefreshGrid(SelectedIndex);
    ShowStatus('已标记为进行中；完成实际备份后，再标记完成。');
  except
    on E: EArgumentException do ShowStatus(E.Message, True);
    on E: EInvalidOpException do ShowStatus(E.Message, True);
  end;
end;

procedure TBackupTrackerForm.CompleteButtonClick(Sender: TObject);
begin
  try
    FStore.Complete(SelectedIndex);
    RefreshGrid(SelectedIndex);
    ShowStatus('任务已标记完成。');
  except
    on E: EArgumentException do ShowStatus(E.Message, True);
    on E: EInvalidOpException do ShowStatus(E.Message, True);
  end;
end;

procedure TBackupTrackerForm.RemoveButtonClick(Sender: TObject);
var
  Index: Integer;
begin
  try
    Index := SelectedIndex;
    FStore.Remove(Index);
    RefreshGrid(Index);
    ShowStatus('任务记录已移除。');
  except
    on E: EArgumentException do ShowStatus(E.Message, True);
    on E: EInvalidOpException do ShowStatus(E.Message, True);
  end;
end;

procedure TBackupTrackerForm.TaskGridSelectCell(Sender: TObject;
  ACol, ARow: Integer; var CanSelect: Boolean);
begin
  if FStore <> nil then
    UpdateButtons(ARow - 1);
end;

procedure TBackupTrackerForm.ResourceComboChange(Sender: TObject);
begin

end;

procedure TBackupTrackerForm.ResourceComboDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  Text: string;
  Inset: Integer;
begin
  if (Index < 0) or (Index >= ResourceCombo.Items.Count) then Exit;
  Text := ResourceCombo.Items[Index];
  ResourceCombo.Canvas.Font.Assign(ResourceCombo.Font);
  if odSelected in State then
  begin
    ResourceCombo.Canvas.Brush.Color := clHighlight;
    ResourceCombo.Canvas.Font.Color := clHighlightText;
  end
  else
    ResourceCombo.Canvas.Brush.Color := clWindow;
  ResourceCombo.Canvas.FillRect(Rect);
  Inset := MulDiv(18, CurrentPPI, 96);
  Inc(Rect.Left, Inset);
  Dec(Rect.Right, Inset);
  DrawText(ResourceCombo.Canvas.Handle, PChar(Text), Length(Text), Rect,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
end;

end.
