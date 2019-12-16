
time /usr/bin/docker exec -i $(/usr/bin/docker ps | /bin/grep postgres | /usr/bin/awk '{print $1}') psql bds_hub -c "refresh materialized view reporting.component;"
time /usr/bin/docker exec -i $(/usr/bin/docker ps | /bin/grep postgres | /usr/bin/awk '{print $1}') psql bds_hub -c "refresh materialized view reporting.component_license;"
time /usr/bin/docker exec -i $(/usr/bin/docker ps | /bin/grep postgres | /usr/bin/awk '{print $1}') psql bds_hub -c "refresh materialized view reporting.component_match_types;"
time /usr/bin/docker exec -i $(/usr/bin/docker ps | /bin/grep postgres | /usr/bin/awk '{print $1}') psql bds_hub -c "refresh materialized view reporting.component_matches;"
time /usr/bin/docker exec -i $(/usr/bin/docker ps | /bin/grep postgres | /usr/bin/awk '{print $1}') psql bds_hub -c "refresh materialized view reporting.component_policies;"
time /usr/bin/docker exec -i $(/usr/bin/docker ps | /bin/grep postgres | /usr/bin/awk '{print $1}') psql bds_hub -c "refresh materialized view reporting.component_usages;"
time /usr/bin/docker exec -i $(/usr/bin/docker ps | /bin/grep postgres | /usr/bin/awk '{print $1}') psql bds_hub -c "refresh materialized view reporting.component_vulnerability;"
time /usr/bin/docker exec -i $(/usr/bin/docker ps | /bin/grep postgres | /usr/bin/awk '{print $1}') psql bds_hub -c "refresh materialized view reporting.project;"
time /usr/bin/docker exec -i $(/usr/bin/docker ps | /bin/grep postgres | /usr/bin/awk '{print $1}') psql bds_hub -c "refresh materialized view reporting.project_mapping;"
time /usr/bin/docker exec -i $(/usr/bin/docker ps | /bin/grep postgres | /usr/bin/awk '{print $1}') psql bds_hub -c "refresh materialized view reporting.project_version;"
time /usr/bin/docker exec -i $(/usr/bin/docker ps | /bin/grep postgres | /usr/bin/awk '{print $1}') psql bds_hub -c "refresh materialized view reporting.project_version_code_location;"


