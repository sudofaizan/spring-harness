


function result(){
curl -X GET "$1" \
-H "Authorization: Bearer $SQ_TOKEN"|jq -r '.task.status'

}
function clean(){
    rm -rf  rm -rf /home/ec2-user/*
}
function scan(){
if mvn clean verify sonar:sonar -Dsonar.projectKey=scanner  \
 -Dsonar.projectName='scanner' -Dsonar.host.url=http://$SONAR_HOST \
 -Dsonar.token=$SQ_TOKEN 
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
function Lbase_update(){
    
    export PREV_TAG=$(git rev-parse HEAD|cut -b 1-9)

    if liquibase tag --tag=$PREV_TAG --username=$LBASE_UNAME --url="$LBASE_JDBC"  --password=$LBASE_PWORD 
    then
    echo "Current DB is tagged with $PREV_TAG"
    return 0
    else
    echo "error tagging DB $PREV_TAG"
    return 1
    fi


    if liquibase update --username=$LBASE_UNAME --url="$LBASE_JDBC"  --password=$LBASE_PWORD --outputFile=$LBASE_LOGFILE --changeLogFile=$LBASE_CHANGELOGFILE
    then
    echo "Successfully updated DB"
    return 0
    else
    echo "error Updating DB"
    return 1
    fi
    
    

}
function Lbase_rollback(){
    # liquibase rollback --tag=$LBASE_TAG --username=$LBASE_UNAME --url="jdbc:mysql://localhost:3306/my_database"  --password=mysql --outputFile=liquibase.log
    if liquibase rollback --tag=$PREV_TAG --username=$LBASE_UNAME --url="$LBASE_JDBC"  --password=$LBASE_PWORD --changeLogFile=$LBASE_CHANGELOGFILE
    then
    echo "Successfully rollback to $PREV_TAG"
    return 0
    else
    echo "error Rollback to $PREV_TAG"
    return 1
    fi
    
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
    export OLD_TAG=$(docker ps -a |grep app|awk '{print $2}')
    old_tag=$(docker ps -a |grep app|awk '{print $2}')
    echo "old tag is $OLD_TAG"
    docker rm -f app
    echo "docker cmd"
    docker run -itd --name app -p 80:8080 springboot:$TAG
    export HOST=$(curl ifconfig.me)
    host=$(curl ifconfig.me)
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
function GetChanges(){
   export CHANGES="https://github.com/sudofaizan/spring-harness/commit/$(git rev-parse HEAD)"
   echo $CHANGES >/tmp/CHANGES
}
function CreateCR(){
    if [ -z "$JIRA_TOKEN" ]; then
        echo "Error: No token found."
        return 1
    fi
    if [ -z "$JIRA_HOST" ]; then
        echo "Error: No Host jira found."
        return 1
    fi
    curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $JIRA_TOKEN" \
    -d '{
        "fields": {
            "project": {
                "key": "HAR"
            },
            "summary": "Change Request for new feature ",
            "description": "This is a change request ticket for implementing a new feature in the system '"$(cat /tmp/CHANGES)"'.",
            "issuetype": {
                "name": "Task"
            }
        }
    }' \
    "$JIRA_HOST/rest/api/2/issue" |jq -r ".key"
}
function GetCR(){
    local issueKey=$1
    if [ -z "$issueKey" ]; then
        echo "Error: Issue key is required as an argument."
        return 1
    fi
    if [ -z "$JIRA_TOKEN" ]; then
        echo "Error: No token found."
        return 1
    fi
    if [ -z "$JIRA_HOST" ]; then
        echo "Error: No Host jira found."
        return 1
    fi

    curl -s -X GET \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $JIRA_TOKEN" \
    "$JIRA_HOST/rest/api/2/issue/$issueKey" |jq -r '.fields.status.name'
}
function CloseCR() {
    local issueKey=$1
    if [ -z "$issueKey" ]; then
        echo "Error: Issue key is required as an argument."
        return 1
    fi
    if [ -z "$JIRA_TOKEN" ]; then
        echo "Error: No token found."
        return 1
    fi
    if [ -z "$JIRA_HOST" ]; then
        echo "Error: No Host jira found."
        return 1
    fi

    curl  -s -X POST \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $JIRA_TOKEN" \
      -d '{
        "transition": {
          "id": "21"
        },
        "update": {
            "comment": [
                {
                    "add": {
                        "body": "Closing the issue as the request has been completed."
                    }
                }
            ]
        }
      }' \
      "$JIRA_HOST/rest/api/2/issue/$issueKey/transitions"
}
function DeleteCR(){
    local issueKey=$1
    if [ -z "$issueKey" ]; then
        echo "Error: Issue key is required as an argument."
        return 1
    fi
    if [ -z "$JIRA_TOKEN" ]; then
        echo "Error: No token found."
        return 1
    fi
    if [ -z "$JIRA_HOST" ]; then
        echo "Error: No Host jira found."
        return 1
    fi
        curl -s -X DELETE \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        "$JIRA_HOST/rest/api/2/issue/$issueKey"
}
$1 $2
