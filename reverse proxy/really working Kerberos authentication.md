What is this guide ?

Something very basic covering only this scenario : httpd performing Kerberos authentication and then passing a parsed X-Alfresco-Remote-User header to ACS

Why ?
Because it is the only scenario that works for /alfresco /adw (Alfresco Digital Workspace) **and**/share

But ACS supports Kerberos natively.... 
True but the problem is /share (not /alfresco nor /adw) : after the Kerberos ticket has expired there's no way to have /share to renew it unless we restart the webapp.


So, the diagram is?
```mermaid
---
config:
  layout: elk
  elk:
    mergeEdges: true
    nodePlacementStrategy: LINEAR_SEGMENTS
---
flowchart LR
    n1["User"] -- 1 --- n2["httpd"]
    n2 -- 2 --- n3["KDC"]
    n2 -- 3 --- n4["ACS"]

    n1@{ shape: text}
    n2@{ shape: text}
    n3@{ shape: text}
    n4@{ shape: text}
```


Not bad but something more detailed ?
```mermaid
sequenceDiagram
    participant User
    participant httpd
    participant KDC
    participant ACS
    User->>KDC: I need a ticket for https://FQDN
    KDC->>User: Here you are
    User->>httpd: GET with Kerberos ticket
    httpd->>KDC: Kerberos ticket ok ?
    KDC->>httpd: Yup, he's a valid user
    httpd->>httpd: parse "user1@REALM" and leave only "user"
    httpd->>ACS: X-Alfresco-Remote-User : user1
    ACS->>httpd: Auth ok, answer request
    httpd->>User: the data for your GET
```
