#!/bin/bash


docker-machine ssh node1 "sudo rm -rf /mnt/sda1/minio1"
docker-machine ssh node1 "sudo mkdir /mnt/sda1/minio1"
docker-machine ssh node1 "sudo chown -R docker:docker /mnt/sda1/minio1"

docker-machine ssh node2 "sudo rm -rf /mnt/sda1/minio2"
docker-machine ssh node2 "sudo mkdir /mnt/sda1/minio2"
docker-machine ssh node2 "sudo chown -R docker:docker /mnt/sda1/minio2"

docker-machine ssh node3 "sudo rm -rf /mnt/sda1/minio3"
docker-machine ssh node3 "sudo mkdir /mnt/sda1/minio3"
docker-machine ssh node3 "sudo chown -R docker:docker /mnt/sda1/minio3"

docker-machine ssh node3 "sudo rm -rf /mnt/sda1/minio4"
docker-machine ssh node3 "sudo mkdir /mnt/sda1/minio4"
docker-machine ssh node3 "sudo chown -R docker:docker /mnt/sda1/minio4"

docker-machine ssh node1 'echo "minio" | docker secret create access_key -'
docker-machine ssh node1 'echo "minio123" | docker secret create secret_key -'


docker-machine ssh node1 "docker node update node1 --label-add node=node1"
docker-machine ssh node1 "docker node update node2 --label-add node=node2"
docker-machine ssh node1 "docker node update node3 --label-add node=node3"
