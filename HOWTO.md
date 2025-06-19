1. Open in VS Code
2. Install plugins for development in DevContainers.
3. Open repository in DevContainer.

## Create superuser

/opt/wildfly/bin/add-user.sh -u "admin" -p "password123!" -g "SuperUser" -r "ManagementRealm"

## Start Wildfly server

/opt/wildfly/bin/standalone.sh -c standalone-full.xml

## Start the CLI

/opt/wildfly/bin/jboss-cli.sh --connect

### Add the JDBC driver

module add --name=org.postgresql --resources=/opt/wildfly/modules/system/layers/base/org/postgresql/main/postgresql.jar --dependencies=javax.api,javax.transaction.api

### Configure the data source

**Add the driver to the data-source subsystem**
/subsystem=datasources/jdbc-driver=postgresql:add(driver-name=postgresql,driver-module-name=org.postgresql,driver-class-name=org.postgresql.Driver)

**Create the datasource that uses the driver**

```
data-source add --name=SymphonyDS --jndi-name=java:/SymphonyDS --driver-name=postgresql --connection-url=jdbc:postgresql://db:5432/symphony  --user-name=symphony --password=symphony
```

5. Run the tests

./add-user.sh -m -u administrator1 -p password1!

4. Get the testdata

```
git submodule init
git submodule update
```
