@Echo Off
Set "InvokedFrom=%__CD__:~,-1%"
CD /D "%~dp0"
::Echo Diese Datei liegt in %__CD__:~,-1%
::Echo Die Verknuepfung liegt in %InvokedFrom%

:: Python-Pfade temporaer zum PATH hinzufuegen
Set "PATH=N:\Download\PortableApps\Python\;N:\Download\PortableApps\Python\scripts;%PATH%"

:: Python-Skript aufrufen und die Variable uebergeben
python -O "N:\Download\PortableApps\Creo_CSV2XLSX.py" "%InvokedFrom%"

Pause
