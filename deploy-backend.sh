mvn -f symphony-ws/pom.xml clean install -DskipTests
cp symphony-ws/target/symphony-ws*.war /opt/wildfly/standalone/deployments
ls /opt/wildfly/standalone/deployments
# if there is a file ending with .failed print the contents of the file
if ls /opt/wildfly/standalone/deployments/*.failed 1> /dev/null 2>&1; then
    echo "Deployment failed. Check the logs for details."
    cat /opt/wildfly/standalone/deployments/*.failed
fi