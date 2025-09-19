JMX console access is a good idea : we can see and modify a lot of parameters.
Watch out : we have no syntax nor GUI based filters here... a bad value can directly written and you'll notice it probably only at the next restart of ACS...

In any case, let's see what has to be done to connect through a SSH tunnel (having it working without a tunnel is very unlikely).




REM define Jconsole full path
set JCP="C:\TAI\JDK17\bin\jconsole.exe"

%JCP% "service:jmx:rmi://127.0.0.1:50508/jndi/rmi://127.0.0.1:50500/alfresco/jmxrmi" 
