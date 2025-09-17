REM define Jconsole full path
set JCP="C:\TAI\JDK17\bin\jconsole.exe"

%JCP% -l service:jmx:rmi:///jndi/rmi://localhost:50500/alfresco/jmxrmi -u controlRole -p change_asap -n
