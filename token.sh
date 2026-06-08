MY_TOKEN=$(vault kv get -field=token secret/jenkins/github) 
echo "$MY_TOKEN"
