


function result(){
curl -X GET "$1" \
-H "Authorization: Bearer $SONAR_TOKEN"|jq -r '.task.status'

}
function clean(){
    rm -rf  rm -rf /home/ec2-user/*
}
function scan(){
if mvn clean verify sonar:sonar -Dsonar.projectKey=springboot  \
 -Dsonar.projectName='springboot' -Dsonar.host.url=http://$SONAR_HOST \
 -Dsonar.token=$SONAR_TOKEN 
then
echo "SCAN SUCCESS"
exit 0
else
exit 1
fi
}
function clean(){
    mvn clean
}
function check_space(){
     AVALIABLE_SPACE=$(df -h|grep -w "/"|awk '{print $2}'|sed 's/Gi//g')
     if [ $AVALIABLE_SPACE -le $CHECK_SPACE ]
     then
     echo "no space to deploy"
     exit 1
     else
     echo "sufficient space to deploy"
     exit 0
     fi
}
function rollback(){
echo "rolling back"
docker rm -f app
docker run -itd --name app -p 80:8080 springboot:$(OLD_TAG)
}
function deploy(){
    if [ -f /home/ec2-user/lock ]
    then
    sleep 10
    echo "waiting for lock to release"
    deploy
    else
    touch /home/ec2-user/lock
    TAG=$(git rev-parse HEAD|cut -b 1-9)
    docker build -t springboot:$TAG .
    docker rm -f app
    export OLD_TAG=$(docker ps -a |grep app|awk '{print $2}')
    docker ps -a 
    echo "docker cmd"
    echo "old tag is $OLD_TAG"
    docker run -itd --name app -p 80:8080 springboot:$TAG
    export HOST=$(curl ifconfig.me)
    curl ifconfig.me
    fi
    rm /home/ec2-user/lock
}

function SanityCheck()
{
   if curl -X GET $(curl ifconfig.me) -v 2>&1|grep  "200"
   then
   exit 0
   else 
   exit 1
   fi

}
$1
