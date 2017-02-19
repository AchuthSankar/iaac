#!/bin/sh

running=`docker --tlsverify -H tcp://192.168.99.100:2376 ps -a | grep kong-database | grep -v -c -i Up`
if [ $running -ne 0 ]; then
	docker --tlsverify -H tcp://192.168.99.100:2376 rm kong-database
fi

docker --tlsverify -H tcp://192.168.99.100:2376 run -d \
--name kong-database \
-p 5432:5432 \
-e "POSTGRES_USER=kong" \
-e "POSTGRES_DB=kong" \
postgres:9.4

running=`docker --tlsverify -H tcp://192.168.99.100:2376 ps -a | grep kong | grep -v -c -i Up`
if [ $running -ne 0 ]; then
	docker --tlsverify -H tcp://192.168.99.100:2376 rm kong
fi

docker run -d --name kong \
--link kong-database:kong-database \
-e "KONG_DATABASE=postgres" \
-e "KONG_PG_HOST=kong-database" \
-p 80:80 \
-p 443:443 \
-p 8001:8001 \
-p 7946:7946 \
-p 7946:7946/udp \
kong

docker --tlsverify -H tcp://192.168.99.100:2376 build -t achuthman/$ServiceName .
status=$?
if [ $status -ne "0" ]; then
	echo "Docker build failed"
	exit -1
fi
docker --tlsverify -H tcp://192.168.99.100:2376 rm -f $ServiceName
docker --tlsverify -H tcp://192.168.99.100:2376 run -d --name $ServiceName achuthman/$ServiceName
status=$?
if [ $status -ne 0 ]; then
	echo "Docker run failed"
	exit -1
fi
loop=5
while [ $loop -ne 0 ]
do
	running=`docker --tlsverify -H tcp://192.168.99.100:2376 ps | grep ${ServiceName} | grep -c -i Up`
	if [ $running -eq 1 ];then
		loop=0
	fi
	loop=`expr $loop -1`
done
if [ $running -eq 0 ]; then
	error "failed"
fi