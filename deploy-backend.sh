#!/usr/bin/env bash
set -euo pipefail

# Build the WAR file
echo "→ Building WAR…"
mvn -f symphony-ws/pom.xml clean install -DskipTests

# Copy the WAR into the deployments folder
DEPLOY_DIR="/opt/wildfly/standalone/deployments"
cp symphony-ws/target/symphony-ws*.war "${DEPLOY_DIR}/"
WAR=$(basename symphony-ws/target/symphony-ws*.war)

# Wait for either .deployed or .failed
echo -n "→ Waiting for ${WAR} to finish… "
for ((i=1; i<=60; i++)); do
  if [ -f "${DEPLOY_DIR}/${WAR}.deployed" ]; then
    echo "✔ Deployment succeeded."
    exit 0
  fi
  if [ -f "${DEPLOY_DIR}/${WAR}.failed" ]; then
    echo "✖ Deployment failed:"
    echo "—— Details: ——"
    cat "${DEPLOY_DIR}/${WAR}.failed"
    echo "\n"
    exit 1
  fi
  sleep 1
done

echo "⚠ Timeout: no .deployed or .failed marker found after 60 seconds."
exit 1
