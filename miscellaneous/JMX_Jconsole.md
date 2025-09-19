Reference:  
https://support.hyland.com/r/Alfresco/Alfresco-Content-Services/25.2/Alfresco-Content-Services/Configure/Overview/Using-JMX-Client-to-Change-Settings-Dynamically

My considerations below.

JMX console access for reading is a good idea : we can have a look at lot of parameters and their values.

About writing stuff... DANGER!

We have almost no syntax nor GUI based checks here... a bad value can be directly written in the DB and you'll notice it probably only at the next restart of ACS... (meaning: ACS won't start)

In any case, let's see what has to be done to connect through a SSH tunnel (having it working without a tunnel is very unlikely).

setenv.sh :
```
[...]
-Dcom.sun.management.jmxremote
-Dcom.sun.management.jmxremote.ssl=false
-Djava.rmi.server.hostname=127.0.0.1
#The last one is what makes SSH tunnel working
[...]
```
<br />

alfresco-global.properties
```
[...]
alfresco.jmx.connector.enabled=true
alfresco.rmi.services.host=127.0.0.1
alfresco.rmi.services.port=50500
monitor.rmi.service.enabled=true
monitor.rmi.service.port=50508
[...]
```
<br />

Remember that if you don't override them,  these two apply:
```
/opt/alfresco/tomcat/webapps/alfresco/WEB-INF/classes/alfresco/alfresco-jmxrmi.password
/opt/alfresco/tomcat/webapps/alfresco/WEB-INF/classes/alfresco/alfresco-jmxrmi.access
```

Set up a SSH tunnel the way you want: PuTTY, KiTTY, command line, etc. etc. so that:
The listening sockets on your PC are : 127.0.0.1:50500 and 127.0.0.1:50508
The listening sockets on your VM are : 127.0.0.1:50500 and 127.0.0.1:50508
Then make the SSH connection.


Open JConsole:
```
C:\JDK17\bin\jconsole.exe
```

Remote Process:
```
service:jmx:rmi://127.0.0.1:50508/jndi/rmi://127.0.0.1:50500/alfresco/jmxrmi
```

fill also Username and Password
