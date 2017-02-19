#!/bin/sh
sudo docker rmi ${image} --force
sudo docker rm ${ServiceName} --force
sudo docker service create --name ${ServiceName} ${image}