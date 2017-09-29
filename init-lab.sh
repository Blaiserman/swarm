#!/bin/bash

case "$1" in
create)
   ./init-swarm.sh create $2
     # docker config logdriver?
   ./init-swarm.sh init $2
   ./init-swarm.sh minifs $2
   ./compose/minio/minio-folders.sh
   docker-machine ssh node1 "docker network create --attachable --driver overlay admin-net"
   docker-machine ssh node1 "docker stack deploy -c /home/docker/compose/minio/minio.yml minio"
      # traefik?
      # log config?
   # scaled up registri (caching registry?)
      # minio bucket volume
      # domain OR portforward?
   # (gray)log szerver (scaled up?)
     # traefik?
     # minio bucket volume?
   docker-machine ssh node1 "sh /home/docker/compose/traefik-ssl/gencert.sh mydomain.lan"
   docker-machine ssh node1 "docker stack deploy -c /home/docker/compose/traefik-ssl/traefik-ssl.yml traefik"
   # poratiner-ssl
      # mino bucket
   # gitlab? (memori for master)
      # minio bucket volume
      # proxy registrs?
      # minio cache bucket
   # gitlab "swarm" runner

   echo "TLS disabled"
   echo "boot2docker docker password: Password1"
   echo "minio pass: ?"
   # echo domains and master IP hor host file
   ;;
*)
   ;;
esac
