1) Size of Alfresco logical stores
SELECT CONCAT(stores.protocol, CONCAT('://', stores.identifier)), count(*)
from alf_node nodes, alf_store stores
where stores.id=nodes.store_id
group by nodes.store_id, stores.protocol, stores.identifier;


2) Content type distribution    
select ns.uri as uri, names.local_name as nodeType, count(*) as occurrencies
from alf_node nodes, alf_qname names, alf_namespace ns
where nodes.type_qname_id=names.id and names.ns_id = ns.id
and nodes.store_id = (select id from alf_store where protocol = 'workspace' and identifier = 'SpacesStore')
group by ns.uri, names.local_name, nodes.type_qname_id
order by occurrencies desc;


3) Count of nodes in workspace://SpacesStore
select count( * ) as nodes from alf_node where store_id = (select id from alf_store where protocol = 'workspace' and identifier = 'SpacesStore');


4) Count of nodes in archive://SpacesStore
select count( * ) as nodes_archive from alf_node where store_id = (select id from alf_store where protocol = 'archive' and identifier = 'SpacesStore');
