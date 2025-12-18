The license is correctly stored into tomcat/shared/classes/alfresco/extension/ but:

1) After a while that ACS is running it says that the license is invalid
2) Renaming the license from .lic.installed to .lic and restarting ACS (or Apply license from the GUI)fixes the problem temporarely
3) go to 1)

It seems that bad license file can cause that behaviour (mh....) and the quick fix is to save the license into: tomcat/webapps/alfresco/WEB-INF/alfresco/license/your-license-here.lic
