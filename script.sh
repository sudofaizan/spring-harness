

function result(){
curl -X GET "$1" \
-H "Authorization: Bearer $SONAR_TOKEN"|jq -r '.task.status'

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
