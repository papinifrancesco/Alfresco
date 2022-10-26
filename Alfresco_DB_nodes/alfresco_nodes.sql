use alfresco;

select count(*) as cm_content_nodes,
       qn.local_name as type_name from alf_node nd,
       alf_qname qn,
       alf_namespace ns where qn.ns_id = ns.id and nd.type_qname_id = qn.id and nd.store_id=6
       group by qn.local_name;
