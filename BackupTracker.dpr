program BackupTracker;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {BackupTrackerForm},
  BackupTasks in 'BackupTasks.pas';

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Backup Task Tracker';
  Application.CreateForm(TBackupTrackerForm, BackupTrackerForm);
  Application.Run;
end.
