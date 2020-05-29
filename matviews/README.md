# Reporting database data persistence

## Overview

This Blackduck add-on enables reporting gatabase persistence on Blackduck versions with reporting database implemented as materialized views (2019.10.x and later)

## Details

Reporting database in the Blackduck is implemented as a set of materialized views within **reporting** schema in **bds_hub** database.

Reporting schema is refreshed regularily (8 hours interval default value) and as such will not have information on any data that have been removed from the system.

The purpose of this add-on is to enable datat persistence by replicating the content of the reporting database into another set of tables located in **bds_hub_reports** database schema **pdata**.

Data replication is performed by an add-on container that is deployed alongside Blackduck. This container runs a process on a predefined schedule where it refreshes materialized views and marshals the data form reporting schema to pdata schema.

## Deployment

This deployment process assumes you are running Blackduck instance in a docker swarm with Blackduck provided database container.

Configuration with external database will require modification of setup scripts to provide authentication for FDW setup.

### Initialization of the databse structures.

Execute **setup.sql** and **date_addons.sql** in the Blackduck database.

This step will create **pdata** schema in the **bds_hub_report** database and replicate table and index stuctures from the reporting database.

### Deploying container

Add the content of deployment/docker/docker-compose.local-overrides.yml to your deployment file and deploy Blackduck.

### Validating installation

Connect to the database and check that data from bds_hub.reporting is properly replicated to bds_hub_reports.pdata



