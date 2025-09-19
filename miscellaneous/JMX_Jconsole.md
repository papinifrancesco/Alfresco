REM define Jconsole full path
set JCP="C:\TAI\JDK17\bin\jconsole.exe"

%JCP% "service:jmx:rmi://127.0.0.1:50508/jndi/rmi://127.0.0.1:50500/alfresco/jmxrmi" 
