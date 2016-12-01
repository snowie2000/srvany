object Service1: TService1
  OldCreateOrder = False
  AllowPause = False
  DisplayName = 'Service1'
  ErrorSeverity = esIgnore
  AfterInstall = ServiceAfterInstall
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 150
  Width = 215
end
