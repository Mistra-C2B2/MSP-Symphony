1. Open in VS Code
2. Install plugins for development in DevContainers.
3. Open repository in DevContainer.

# Build

```
cd symphony-ws
mvn package -DskipTests
```

# Deploy
cp target/symphony-ws-*.war /opt/wildfly/standalone/deployments

1. cp target/example.war $AS/standalone/deployments
2. (Manual mode only) touch $AS/standalone/deployments/example.war.dodeploy

5. Run the tests

./add-user.sh -m -u administrator1 -p password1!

4. Get the testdata

```
git submodule init
git submodule update
```
