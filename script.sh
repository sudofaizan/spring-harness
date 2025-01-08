


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
return 0
else
return 1
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
     return 1
     else
     echo "sufficient space to deploy"
     return 0
     fi
}
function deploy(){
touch lock
    docker build -t springboot:v1 .
    docker rm -f app
    docker run -itd --name app -p 80:8080 springboot:v1
rm lock
}

function SanityCheck()
{
    curl localhost:80
}
$1
clean