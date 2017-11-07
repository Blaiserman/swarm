#!/bin/bash

test(){
   if [ -z "$1" ]; then
        echo "Host number not present"
	exit 1
   else
        N=$1
   fi
}

FOR1(){
   test $1

   for (( i=1; i<=$N; i++ ))
   do
      echo "$2""$i" "$3" "$4" | bash
   done
}

FOR2(){
   test $1

   for (( i=2; i<=$N; i++ ))
   do
      echo "$2""$i" "$3" | bash
   done
}

minfs(){
	FOR1 $1 "docker-machine ssh node" "docker plugin install --grant-all-permissions minio/minfs"
}

etc3(){
ETCD_VER=v3.2.9

# choose either URL
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/coreos/etcd/releases/download
DOWNLOAD_URL=${GITHUB_URL}

rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1

## felmásolni a megosztásra
## onnan minde host /bin/ mappájába
## végül törölni
#sudo cp /tmp/etcd-download-test/etcd /tmp/etcd-download-test/etcdctl /bin/

# https://github.com/coreos/etcd/releases/
# file:///E:/Dropbox/Public/docker-k8s-lab.pdf 37o
# https://github.com/henszey/etcd-browser
}

weave-scope(){
FOR1 $1 "docker-machine ssh node" "\"sudo curl -o /usr/local/bin/scope -L git.io/scope > /dev/null 2>&1\""
FOR1 $1 "docker-machine ssh node" "\"sudo chmod a+x /usr/local/bin/scope\""

N=$1
e=""

for (( I=1; I<=N; I++ ))
do
        c=$(docker-machine ip node$I)
        e="$e $c"
done

FOR1 $1 "docker-machine ssh node" "docker rm -f weavescope > /dev/null 2>&1"

test $1
for (( i=1; i<=$N; i++ ))
do
      docker-machine ssh node$i scope launch $e
done
}

config(){
 user=`whoami`
 rm -rf /c/Users/$user/Documents/Docker/*
 mkdir -p /c/Users/$user/Documents/Docker/{certs,registry,compose,minio,volumes}

 FOR1 $1 "docker-machine ssh node" "ln -s /c/Users/$user/Documents/Docker /home/docker/Docker"
 FOR1 $1 "docker-machine ssh node" "\"sudo ln -s /home/docker/Docker/volumes /mnt/sda1/var/lib/docker/volumes\""
 # cp compos and config
 cp -r ./compose/*  /c/Users/$user/Documents/Docker/compose/
}

certgen(){
user=`whoami`
rm -rf /c/Users/$user/Documents/Docker/certs/*
export PASSPHRASE=$(head -c 500 /dev/urandom | tr -dc a-z0-9A-Z | head -c 128; echo)
export DOMAIN=$1

subj="
C=HU
ST=Pest
O=My Company
localityName=Budapest
commonName=$DOMAIN
organizationalUnitName=OU
emailAddress=root@$DOMAIN
"

openssl genrsa -des3 -out /c/Users/$user/Documents/Docker/certs/$DOMAIN.key -passout env:PASSPHRASE 2048

openssl req \
    -new \
    -batch \
    -subj "$(echo -n "$subj" | tr "\n" "/")" \
    -key /c/Users/$user/Documents/Docker/certs/$DOMAIN.key \
    -out /c/Users/$user/Documents/Docker/certs/$DOMAIN.csr \
-passin env:PASSPHRASE

cp /c/Users/$user/Documents/Docker/certs/$DOMAIN.key /c/Users/$user/Documents/Docker/certs/$DOMAIN.key.org

openssl rsa -in /c/Users/$user/Documents/Docker/certs/$DOMAIN.key.org -out /c/Users/$user/Documents/Docker/certs/$DOMAIN.key -passin env:PASSPHRASE

openssl x509 -req -days 3650 -in /c/Users/$user/Documents/Docker/certs/$DOMAIN.csr -signkey /c/Users/$user/Documents/Docker/certs/$DOMAIN.key -out /c/Users/$user/Documents/Docker/certs/$DOMAIN.crt
}

insecure-registr(){
	# on all host
	IP=
	sudo /etc/init.d/docker stop
	sudo cp /var/lib/boot2docker/profile /var/lib/boot2docker/profile.bak3
	sudo sed -i 's|--label provider=virtualbox|--label provider=virtualbox --insecure-registry $IP:5000|' /var/lib/boot2docker/profile
	sudo /etc/init.d/docker start
}

#-------------------------------------
case "$1" in
create)
   FOR1 $2 "docker-machine create --driver virtualbox --engine-storage-driver overlay2 --engine-opt log-driver=gelf --engine-opt log-opt=gelf-address=udp://172.16.0.38:12201 node"
   # --virtualbox-disk-size "20000"  --virtualbox-cpu-count "1" --virtualbox-memory "1024" node$i
   # docker-machine create -d virtualbox --virtualbox-boot2docker-url \
   #https://releases.rancher.com/os/latest/rancheros.iso node$i
   # ip and host to /etc/hosts
   ;;
config)
   FOR1 $2 "docker-machine ssh node" "sudo sysctl -w vm.max_map_count=262144"
   config $2      # OK
   #minfs $2       # OK
   # etc3 $2
   #weave-scope $2 # OK
   ;;
start)
   FOR1 $2 "docker-machine start node"
   ;;
init)
   MANAGGER_IP=$(docker-machine ip node1)
   docker-machine ssh node1 docker swarm init --listen-addr ${MANAGGER_IP} --advertise-addr ${MANAGGER_IP}
#  MANAGER_TOKEN=$(docker-machine ssh node1 docker swarm join-token -q manager)
   WORKER_TOKEN=$(docker-machine ssh node1 docker swarm join-token -q worker)
   sleep 5
   FOR2 $2 "docker-machine ssh node" "docker swarm join --token '${WORKER_TOKEN}' '${MANAGGER_IP}':2377"
   docker-machine ssh node1 "docker network create --subnet=172.16.0.0/24 --driver overlay --attachable admin-net"
   ;;
promote)
   FOR1 $2 "docker-machine ssh node1 docker node promote node"
   ;;
weave-net)
   FOR1 $2 "docker-machine ssh node" "docker plugin install --grant-all-permissions store/weaveworks/net-plugin:2.0.1"
   docker-machine ssh node1 docker network create --driver=store/weaveworks/net-plugin:2.0.1 weavenet
   ;;
ELK)
   docker-machine ssh node1 "docker stack deploy -c Docker/compose/ELK/elk.yml elk"
   ;;
monitoring)
   docker-machine ssh node1 "docker stack deploy -c Docker/compose/monitoring/monitoring-stack.yml monitor"
   # test?
   sleep 10
   docker-machine ssh node1 "docker exec `docker ps | grep -i influx | awk '{print $1}'` influx -execute 'CREATE DATABASE cadvisor'"
   ;;
stop)
   FOR1 $2 "docker-machine stop node"
   ;;
destroy-swarm)
   FOR1 $2  "docker-machine ssh node" "docker swarm leave --force"
   ;;
destroy)
  user=`whoami`
  FOR1 $2  "docker-machine rm -f node"
  rm -rf /c/Users/$user/Documents/Docker/
   ;;
info)
   echo "node1-3:4040 - weave scope"
   ;;
*) echo "Usage:  ./init-swarm.sh <command> <node number>
   ./init-swarm.sh create 3
   ./init-swarm.sh init 3
   ./init-swarm.sh promote 3
   ./init-swarm.sh config 3
   "
   ;;
esac
