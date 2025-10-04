#!/usr/bin/env bash
set -euo pipefail

# Build the WAR file
echo ""
echo "📦 Building WAR file..."
mvn -f /workspace/symphony-ws/pom.xml clean install -DskipTests

# Copy the WAR into the deployments folder
DEPLOY_DIR="/opt/wildfly/standalone/deployments"
cp /workspace/symphony-ws/target/symphony-ws*.war "${DEPLOY_DIR}/"
WAR=$(basename /workspace/symphony-ws/target/symphony-ws*.war)

# Wait for either .deployed or .failed
echo ""
echo "🚀 Deploying ${WAR}..."
echo -n "   Waiting for deployment to complete... "
for ((i=1; i<=60; i++)); do
  if [ -f "${DEPLOY_DIR}/${WAR}.deployed" ]; then
    echo ""
    echo ""
    echo "========================================="
    echo "✅ Deployment Successful!"
    echo "========================================="
    exit 0
  fi
  if [ -f "${DEPLOY_DIR}/${WAR}.failed" ]; then
    echo ""
    echo ""
    echo "========================================="
    echo "❌ Deployment Failed!"
    echo "========================================="
    echo ""
    echo "📋 Error Details:"
    cat "${DEPLOY_DIR}/${WAR}.failed"
    echo ""
    echo "========================================="
    exit 1
  fi
  sleep 1
done

echo ""
echo ""
echo "========================================="
echo "⚠️  Deployment Timeout"
echo "========================================="
echo ""
echo "❗ No deployment status found after 60 seconds"
echo "   Check WildFly logs for details:"
echo "   /opt/wildfly/standalone/log/server.log"
echo ""
echo "========================================="
exit 1