#!/bin/bash
echo "Shutting down WildFly..."
/opt/wildfly/bin/jboss-cli.sh --connect command=:shutdown

echo "Removing deployments..."
rm -rf /opt/wildfly/standalone/deployments/*.war