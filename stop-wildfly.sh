#!/bin/bash
echo "Shutting down WildFly..."
/opt/wildfly/bin/jboss-cli.sh --connect command=:shutdown
