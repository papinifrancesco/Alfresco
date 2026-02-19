#!/bin/bash

# define the method to make a JMX connection first
alf_jmx_connect ()
{
/opt/alfresco/java/bin/java -jar /opt/alfresco/scripts/jmxterm-1.0.4-uber.jar -l service:jmx:rmi:///jndi/rmi://localhost:50500/alfresco/jmxrmi -u controlRole -p change_asap -n
}

echo -n $(date +"%Y-%m-%d_%H-%M-%S")
echo -n " ; "
# pipe the commands for JMX to the method above
echo -n 'get -b "Alfresco:Name=RepoServerMgmt" UserCountNonExpired' | alf_jmx_connect 2>&1 | grep UserCountNonExpired | tr '\n' ' '
echo -n 'get -b "Alfresco:Name=ConnectionPool" NumActive' | alf_jmx_connect 2>&1 | grep NumActive | tr '\n' ' '
echo -n 'get -b "Alfresco:Name=ConnectionPool" NumIdle'   | alf_jmx_connect 2>&1 | grep NumIdle

# define a job in crontab
# crontab -e
# */5 * * * * /opt/alfresco-one/my_scripts/logged_sessions.sh >> /root/logged_sessions.out 2>&1
#
# and you have a basic way to log what you what with local JMX, lean and easy
