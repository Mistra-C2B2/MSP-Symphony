#!/bin/bash
set -e

# echo "Creating a WildFly user..."
/opt/wildfly/bin/add-user.sh -u "admin" -p "password123!" -g "SuperUser" -r "ManagementRealm"

echo "Starting WildFly configuration..."

# Start WildFly in background
/opt/wildfly/bin/standalone.sh -c standalone-full.xml -b 0.0.0.0 -bmanagement 0.0.0.0 > /workspace/wildfly.log 2>&1 &

# Wait for WildFly to be ready
until /opt/wildfly/bin/jboss-cli.sh --connect --commands=":read-attribute(name=server-state)" >/dev/null 2>&1
do
    echo "Waiting for WildFly..."
    sleep 5
done

# Apply configuration
echo "Applying WildFly DataSource configuration..."
/opt/wildfly/bin/jboss-cli.sh --connect --file=config-wildfly.cli
echo "Applying WildFly Security configuration..."
/opt/wildfly/bin/jboss-cli.sh --connect --file=config-wildfly-ldap.cli

# Keep WildFly running in foreground
tail -f /workspace/wildfly.log