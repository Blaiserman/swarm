Docker Swarm Mode Monitoring
===

Docker Stack compose file to deploy dynamic monitoring for Docker Swarm Mode.
This Project based on the falowwing projects:

* https://github.com/botleg/swarm-monitoring
* https://github.com/robinong79/docker-swarm-monitoring
* https://github.com/stefanprodan/dockprom

Run Instructions
---
Setup a Docker Swarm with the Docker Swarm Mode.
Create the used directorys and copy config files to it:
```
mkdir -p /var/dockerdata/alertmanager/data

cp swarm-monitoring/alertmanager/alertmanagerconfig.yml /var/dockerdata/alertmanager/alertmanagerconfig.yml
nano /var/dockerdata/alertmanager/alertmanagerconfig.yml
```

From the swarm manager, deploy the stack with the command,
```
docker stack deploy -c monitoring-stack.yml monitor
```

Test the stack:
```
docker stack services monitor
```

A database named `cadvisor` is needed in influxDB.
```
docker exec `docker ps | grep -i influx | awk '{print $1}'` influx -execute 'CREATE DATABASE cadvisor'
```
Go to Grafana's Url `http://<master node IP>:3000`
Default user and password `admin / admin`
In Grafana, create a new `InfluxDB` data source cald `influx` , with Url `http://influx:8086` and database `cadvisor` and import new dashboard for it with `dashboard.json` file.
Create a `Prometheus` data source cald `Prometheus`, with Url `http://docker-flow-monitor:9090`
Go to cAdvisor's Url `http://<master node IP>:8081`


Todo:
* prometheus.yml service config
* prometheus data to influxdb?
* influxdb cluster
* alertmanagger config?
