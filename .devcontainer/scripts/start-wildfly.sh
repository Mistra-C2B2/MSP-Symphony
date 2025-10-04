#!/bin/bash
set -e

# Check if the user already exists
if ! grep -q "^admin=" /opt/wildfly/standalone/configuration/mgmt-users.properties; then
    echo "Creating a WildFly user..."
    /opt/wildfly/bin/add-user.sh -u "admin" -p "password123!" -g "SuperUser" -r "ManagementRealm"
else
    echo "WildFly user 'admin' already exists."
fi

echo "Starting WildFly..."

# Check if WildFly is already running
if ! /opt/wildfly/bin/jboss-cli.sh --connect --commands=":read-attribute(name=server-state)" >/dev/null 2>&1; then
    # Start WildFly in background
    /opt/wildfly/bin/standalone.sh -c standalone-full.xml -b 0.0.0.0 -bmanagement 0.0.0.0 &

    # Wait for WildFly to be ready
    until /opt/wildfly/bin/jboss-cli.sh --connect --commands=":read-attribute(name=server-state)" >/dev/null 2>&1
    do
        echo "Waiting for WildFly..."
        sleep 5
    done
else
    echo "WildFly is already running."
fi

# Add PostgreSQL module if it doesn't exist
if [ ! -f "/opt/wildfly/modules/org/postgresql/main/module.xml" ]; then
    echo "Adding PostgreSQL JDBC driver module..."
    /opt/wildfly/bin/jboss-cli.sh --connect --command="module add --name=org.postgresql --resources=/opt/wildfly/modules/system/layers/base/org/postgresql/main/postgresql.jar --dependencies=javax.api,javax.transaction.api"
    /opt/wildfly/bin/jboss-cli.sh --connect --command=":reload"
    echo "PostgreSQL module added and server reloaded."
else
    echo "PostgreSQL module already exists."
fi

# Apply configuration
echo "Applying WildFly configuration..."
/opt/wildfly/bin/jboss-cli.sh --connect --file=/workspace/.devcontainer/scripts/config-wildfly.cli

echo ""
echo "========================================="
echo "✓ WildFly is up and running!"
echo "========================================="
echo ""
echo "📋 Quick Reference:"
echo "  • Management Console: http://localhost:9990"
echo "    └─ Credentials: admin / password123!"
echo "  • Application URL:    http://localhost:8080"
echo "  • Server logs:        /opt/wildfly/standalone/log/server.log"
echo ""
echo "🚀 Next Step:"
echo "  Deploy the backend with: deploy-backend.sh"
echo ""
echo "========================================="

