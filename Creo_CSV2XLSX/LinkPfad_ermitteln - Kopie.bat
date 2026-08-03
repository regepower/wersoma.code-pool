@Echo Off
Set "InvokedFrom=%__CD__:~,-1%"
CD /D "%~dp0"
Echo Diese Datei liegt in %__CD__:~,-1%
Echo=
Echo Die Verknuepfung liegt in %InvokedFrom%
Echo=
Pause
