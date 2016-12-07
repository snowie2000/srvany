object Service1: TService1
  OldCreateOrder = False
  DisplayName = 'Service1'
  ErrorSeverity = esIgnore
  AfterInstall = ServiceAfterInstall
  OnPause = ServicePause
  OnShutdown = ServiceShutdown
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 150
  Width = 215
end
