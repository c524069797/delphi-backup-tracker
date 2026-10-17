program BackupTrackerTests;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils,
  Vcl.Forms, Vcl.StdCtrls,
  BackupTasks in 'BackupTasks.pas',
  MainForm in 'MainForm.pas';

var
  CheckCount: Integer;

procedure Check(Condition: Boolean; const Description: string);
begin
  Inc(CheckCount);
  if not Condition then raise Exception.Create(Description);
end;

procedure ExpectError(const Action: TProc; ExpectedClass: ExceptClass;
  const Description: string);
var
  Raised: Boolean;
begin
  Raised := False;
  try
    Action();
  except
    on E: Exception do
    begin
      Raised := True;
      Check(E.ClassType.InheritsFrom(ExpectedClass), Description + ': exception type');
    end;
  end;
  Check(Raised, Description);
end;

procedure TestStore;
var
  Store: TBackupTaskStore;
  Index, InvalidOrdinal: Integer;
begin
  Store := TBackupTaskStore.Create;
  try
    Check(Store.Count = 0, 'New store is empty');
    Check(Store.CountByState(bsPending) = 0, 'Empty pending count');
    Check(ResourceCaption(brFiles) = '文件', 'Files caption');
    Check(ResourceCaption(brDatabase) = '数据库', 'Database caption');
    Check(ResourceCaption(brVirtualMachine) = '虚拟机', 'VM caption');
    Check(StateCaption(bsPending) = '待处理', 'Pending caption');
    Check(StateCaption(bsRunning) = '进行中', 'Running caption');
    Check(StateCaption(bsCompleted) = '已完成', 'Completed caption');
    ExpectError(procedure begin Store.Add('', brFiles); end,
      EArgumentException, 'Reject empty name');
    ExpectError(procedure begin Store.Add('   ', brFiles); end,
      EArgumentException, 'Reject whitespace');
    ExpectError(procedure begin Store.Add(StringOfChar('x', 81), brFiles); end,
      EArgumentException, 'Reject overlong name');
    InvalidOrdinal := 99;
    ExpectError(procedure begin Store.Add('任务', TBackupResource(InvalidOrdinal)); end,
      EArgumentException, 'Reject unknown resource');
    ExpectError(procedure begin StateCaption(TBackupState(InvalidOrdinal)); end,
      EArgumentException, 'Reject unknown state caption');
    ExpectError(procedure begin Store.CountByState(TBackupState(InvalidOrdinal)); end,
      EArgumentException, 'Reject unknown count state');
    ExpectError(procedure begin Store.Start(-1); end,
      EArgumentOutOfRangeException, 'Reject negative index');
    ExpectError(procedure begin Store.Complete(0); end,
      EArgumentOutOfRangeException, 'Reject missing task');
    ExpectError(procedure begin Store.Remove(0); end,
      EArgumentOutOfRangeException, 'Reject missing removal');
    Check(Store.Count = 0, 'Invalid operations preserve store');
    Index := Store.Add('  业务数据库每日备份  ', brDatabase);
    Check(Index = 0, 'First task index');
    Check(Store.Tasks[0].Name = '业务数据库每日备份', 'Trim and preserve Unicode');
    Check(Store.Tasks[0].Resource = brDatabase, 'Preserve selected resource');
    Check(Store.Tasks[0].State = bsPending, 'New task is pending');
    Check(Store.Tasks[0].CreatedAt > 0, 'Task has creation time');
    ExpectError(procedure begin Store.Complete(0); end,
      EInvalidOpException, 'Cannot skip running state');
    Store.Start(0);
    Check(Store.CountByState(bsRunning) = 1, 'Start changes state and count');
    ExpectError(procedure begin Store.Start(0); end,
      EInvalidOpException, 'Cannot start twice');
    ExpectError(procedure begin Store.Remove(0); end,
      EInvalidOpException, 'Cannot remove running task');
    Check(Store.Count = 1, 'Rejected removal preserves record');
    Store.Complete(0);
    Check(Store.CountByState(bsCompleted) = 1, 'Complete changes state and count');
    ExpectError(procedure begin Store.Complete(0); end,
      EInvalidOpException, 'Cannot complete twice');
    Store.Add(StringOfChar('x', 80), brFiles);
    Check(Store.Count = 2, 'Maximum-length name is accepted');
    Store.Remove(0);
    Check(Store.Count = 1, 'Remove completed record');
    Check(Store.Tasks[0].Resource = brFiles, 'Removal preserves other task');
    Store.Remove(0);
    Check(Store.Count = 0, 'Remove pending record');
  finally
    Store.Free;
  end;
end;

procedure TestForm;
var
  Margins: LRESULT;
  InitialStatus: string;
begin
  Application.CreateForm(TBackupTrackerForm, BackupTrackerForm);
  try
    BackupTrackerForm.Show;
    Application.ProcessMessages;
    Check(BackupTrackerForm.TaskGrid.FixedRows = 1, 'Grid keeps fixed header');
    Check(BackupTrackerForm.TaskGrid.RowCount = 2, 'Empty grid has one data row');
    Check(not BackupTrackerForm.StartButton.Enabled, 'Empty start disabled');
    Check(not BackupTrackerForm.CompleteButton.Enabled, 'Empty complete disabled');
    Check(not BackupTrackerForm.RemoveButton.Enabled, 'Empty remove disabled');
    Check(BackupTrackerForm.ResourceCombo.Style = csOwnerDrawFixed, 'Resource selector reserves text inset');
    Margins := SendMessage(BackupTrackerForm.TaskNameEdit.Handle, EM_GETMARGINS, 0, 0);
    Check(LoWord(Margins) >= 18, 'Name input left inset');
    Check(HiWord(Margins) >= 18, 'Name input right inset');
    InitialStatus := BackupTrackerForm.StatusLabel.Caption;
    BackupTrackerForm.AddButton.Click;
    Check(BackupTrackerForm.StatusLabel.Caption <> InitialStatus, 'Empty input has visible feedback');
    BackupTrackerForm.TaskNameEdit.Text := '业务配置每日备份';
    BackupTrackerForm.ResourceCombo.ItemIndex := 1;
    BackupTrackerForm.AddButton.Click;
    Check(BackupTrackerForm.TaskGrid.Cells[0, 1] = '业务配置每日备份', 'Add renders task name');
    Check(BackupTrackerForm.TaskGrid.Cells[1, 1] = '数据库', 'Add renders resource');
    Check(BackupTrackerForm.TaskGrid.Cells[2, 1] = '待处理', 'Add renders pending state');
    Check(BackupTrackerForm.TaskNameEdit.Text = '', 'Add clears name');
    Check(BackupTrackerForm.StartButton.Enabled, 'Pending task enables start');
    Check(not BackupTrackerForm.CompleteButton.Enabled, 'Pending task cannot complete');
    BackupTrackerForm.CompleteButtonClick(BackupTrackerForm.CompleteButton);
    Check(BackupTrackerForm.TaskGrid.Cells[2, 1] = '待处理', 'Invalid completion preserves state');
    BackupTrackerForm.StartButton.Click;
    Check(BackupTrackerForm.TaskGrid.Cells[2, 1] = '进行中', 'Start renders state');
    Check(BackupTrackerForm.CompleteButton.Enabled, 'Running task enables completion');
    Check(not BackupTrackerForm.RemoveButton.Enabled, 'Running task cannot be removed');
    BackupTrackerForm.RemoveButtonClick(BackupTrackerForm.RemoveButton);
    Check(BackupTrackerForm.TaskGrid.Cells[0, 1] = '业务配置每日备份', 'Guarded removal preserves task');
    BackupTrackerForm.CompleteButton.Click;
    Check(BackupTrackerForm.TaskGrid.Cells[2, 1] = '已完成', 'Complete renders state');
    Check(Pos('已完成 1', BackupTrackerForm.SummaryLabel.Caption) > 0, 'Summary follows completion');
    BackupTrackerForm.TaskNameEdit.Text := '文件归档';
    BackupTrackerForm.ResourceCombo.ItemIndex := 0;
    BackupTrackerForm.AddButton.Click;
    Check(BackupTrackerForm.TaskGrid.RowCount = 3, 'Second task adds a row');
    BackupTrackerForm.TaskGrid.Row := 1;
    Check(not BackupTrackerForm.StartButton.Enabled, 'Selecting completed task refreshes buttons');
    BackupTrackerForm.RemoveButton.Click;
    Check(BackupTrackerForm.TaskGrid.Cells[0, 1] = '文件归档', 'Remove preserves remaining task');
    Check(BackupTrackerForm.StartButton.Enabled, 'Remaining pending task enables start');
    BackupTrackerForm.RemoveButton.Click;
    Check(BackupTrackerForm.TaskGrid.FixedRows = 1, 'Last removal keeps header');
    Check(BackupTrackerForm.TaskGrid.RowCount = 2, 'Last removal restores empty row');
    Check(BackupTrackerForm.TaskGrid.Cells[0, 1] = '暂无任务，请先添加', 'Empty state is visible');
    Check(not BackupTrackerForm.RemoveButton.Enabled, 'Empty state disables removal');
  finally
    BackupTrackerForm.Free;
    BackupTrackerForm := nil;
  end;
end;

begin
  SetConsoleOutputCP(CP_UTF8);
  try
    TestStore;
    Application.Initialize;
    TestForm;
    Writeln(Format('%d checks passed', [CheckCount]));
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'FAILED: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
