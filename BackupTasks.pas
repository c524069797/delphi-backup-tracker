unit BackupTasks;

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  TBackupResource = (brFiles, brDatabase, brVirtualMachine);
  TBackupState = (bsPending, bsRunning, bsCompleted);

  TBackupTask = record
    Name: string;
    Resource: TBackupResource;
    State: TBackupState;
    CreatedAt: TDateTime;
  end;

  TBackupTaskStore = class
  private
    FTasks: TList<TBackupTask>;
    function GetCount: Integer;
    function GetTask(Index: Integer): TBackupTask;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(const Name: string; Resource: TBackupResource): Integer;
    procedure Start(Index: Integer);
    procedure Complete(Index: Integer);
    procedure Remove(Index: Integer);
    function CountByState(State: TBackupState): Integer;
    property Count: Integer read GetCount;
    property Tasks[Index: Integer]: TBackupTask read GetTask;
  end;

function ResourceCaption(Resource: TBackupResource): string;
function StateCaption(State: TBackupState): string;

implementation

function ResourceCaption(Resource: TBackupResource): string;
begin
  case Resource of
    brFiles: Result := '文件';
    brDatabase: Result := '数据库';
    brVirtualMachine: Result := '虚拟机';
  else
    raise EArgumentException.Create('请选择有效的资源类型。');
  end;
end;

function StateCaption(State: TBackupState): string;
begin
  case State of
    bsPending: Result := '待处理';
    bsRunning: Result := '进行中';
    bsCompleted: Result := '已完成';
  else
    raise EArgumentException.Create('任务状态无效。');
  end;
end;

constructor TBackupTaskStore.Create;
begin
  inherited;
  FTasks := TList<TBackupTask>.Create;
end;

destructor TBackupTaskStore.Destroy;
begin
  FTasks.Free;
  inherited;
end;

function TBackupTaskStore.GetCount: Integer;
begin
  Result := FTasks.Count;
end;

function TBackupTaskStore.GetTask(Index: Integer): TBackupTask;
begin
  if (Index < 0) or (Index >= Count) then
    raise EArgumentOutOfRangeException.Create('请先选择一项任务。');
  Result := FTasks[Index];
end;

function TBackupTaskStore.Add(const Name: string;
  Resource: TBackupResource): Integer;
var
  Task: TBackupTask;
begin
  Task.Name := Trim(Name);
  if Task.Name = '' then
    raise EArgumentException.Create('请输入任务名称。');
  if Length(Task.Name) > 80 then
    raise EArgumentException.Create('任务名称不能超过 80 个字符。');
  ResourceCaption(Resource);
  Task.Resource := Resource;
  Task.State := bsPending;
  Task.CreatedAt := Now;
  Result := FTasks.Add(Task);
end;

procedure TBackupTaskStore.Start(Index: Integer);
var
  Task: TBackupTask;
begin
  Task := GetTask(Index);
  if Task.State <> bsPending then
    raise EInvalidOpException.Create('只有待处理任务可以标记为进行中。');
  Task.State := bsRunning;
  FTasks[Index] := Task;
end;

procedure TBackupTaskStore.Complete(Index: Integer);
var
  Task: TBackupTask;
begin
  Task := GetTask(Index);
  if Task.State <> bsRunning then
    raise EInvalidOpException.Create('请先将任务标记为进行中。');
  Task.State := bsCompleted;
  FTasks[Index] := Task;
end;

procedure TBackupTaskStore.Remove(Index: Integer);
begin
  if GetTask(Index).State = bsRunning then
    raise EInvalidOpException.Create('请先结束进行中的任务，再移除记录。');
  FTasks.Delete(Index);
end;

function TBackupTaskStore.CountByState(State: TBackupState): Integer;
var
  Task: TBackupTask;
begin
  StateCaption(State);
  Result := 0;
  for Task in FTasks do
    if Task.State = State then
      Inc(Result);
end;

end.
