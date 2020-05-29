\c bds_hub_report
create schema bds_hub_aux;
CREATE USER MAPPING FOR CURRENT_USER SERVER bds_hub;
import foreign schema st from server bds_hub into bds_hub_aux;

create materialized view project_aux as select central_project.id AS project_id, central_project.created_at FROM bds_hub_aux.central_project;


CREATE MATERIALIZED VIEW project_version_aux as SELECT central_release.project_id, central_release.id AS version_id, 
     central_release.released_on,
     central_release.created_on
    FROM bds_hub_aux.central_release;

create table pdata.project_aux ( like project_aux including defaults including constraints including indexes );
create table pdata.project_version_aux ( like project_version_aux including defaults including constraints including indexes );

alter table pdata.project_aux add primary key (project_id);
alter table pdata.project_version_aux add primary key (project_id, version_id);



refresh materialized view project_aux;
refresh materialized view project_version_aux;
insert into pdata.project_aux select * from project_aux where project_id is not null on conflict on constraint project_aux_pkey do nothing;
insert into pdata.project_version_aux select * from project_version_aux where project_id is not null on conflict on constraint project_version_aux_pkey do nothing;



