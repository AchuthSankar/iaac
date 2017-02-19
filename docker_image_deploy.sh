#!/bin/sh
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