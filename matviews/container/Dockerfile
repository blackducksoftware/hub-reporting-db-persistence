FROM ubuntu:latest
RUN apt-get update
RUN apt-get update && apt-get -y install cron postgresql-client curl jq vim bsdmainutils openjdk-8-jre

RUN chmod gu+rw /var/run
RUN chmod gu+s /usr/sbin/cron
# Optional
# chmod g+s, u-s /usr/bin/crontab
#crontab -u my_user /home/my_user/cron.txt
ADD usr /usr
ADD opt /opt
RUN chmod -R g+x /usr/local/bin/*
RUN chmod -R g+xw /opt/blackduck/hub/auditor
RUN useradd auditor
#RUN echo export JAVA_HOME=$( readlink -f /etc/alternatives/java | sed 's&/bin/java&&') >>/etc/profile

# Run the command on container startup
ENTRYPOINT docker-entrypoint.sh
#CMD cron -f -L 8
