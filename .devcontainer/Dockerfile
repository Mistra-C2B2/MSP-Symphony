FROM mcr.microsoft.com/devcontainers/java:0-17

# Set environment variables
ENV MAVEN_VERSION=3.9.9 \
    WILDFLY_VERSION=36.0.1.Final \
    POSTGRES_DRIVER_VERSION=42.5.1 \
    WILDFLY_HOME=/opt/wildfly \
    MAVEN_HOME=/opt/maven \
    JDBC_URL=jdbc:postgresql://db:5432/symphony \
    DB_USER=symphony_user \
    DB_PASS=password

RUN apt-get update \
    && apt-get install -y curl wget unzip gnupg iputils-ping ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Maven 3.9.9
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    | tar -xz -C /opt \
    && ln -s /opt/apache-maven-${MAVEN_VERSION} ${MAVEN_HOME} \
    && ln -s ${MAVEN_HOME}/bin/mvn /usr/local/bin/mvn 

# Install WildFly
RUN curl -fsSL https://github.com/wildfly/wildfly/releases/download/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.tar.gz \
    | tar -xz -C /opt \
    && ln -s /opt/wildfly-${WILDFLY_VERSION} ${WILDFLY_HOME}

# Add PostgreSQL JDBC driver to Wildfly
RUN mkdir -p ${WILDFLY_HOME}/modules/system/layers/base/org/postgresql/main \
    && wget https://jdbc.postgresql.org/download/postgresql-${POSTGRES_DRIVER_VERSION}.jar -O ${WILDFLY_HOME}/modules/system/layers/base/org/postgresql/main/postgresql.jar \
    && printf \
    '<module xmlns="urn:jboss:module:1.5" name="org.postgresql">\n' \
    '  <resources>\n' \
    '    <resource-root path="postgresql.jar"/>\n' \
    '  </resources>\n' \
    '  <dependencies>\n' \
    '    <module name="javax.api"/>\n' \
    '    <module name="javax.transaction.api"/>\n' \
    '  </dependencies>\n' \
    '</module>\n' \
    > ${WILDFLY_HOME}/modules/system/layers/base/org/postgresql/main/module.xml

# Configure WildFly management user
RUN printf 'admin=password\n'  > ${WILDFLY_HOME}/standalone/configuration/users.properties \
 && printf 'admin=admin\n'     > ${WILDFLY_HOME}/standalone/configuration/groups.properties


RUN printf '%s\n' \
    'batch' \
    '# --- PostgreSQL driver registration' \
    'module add --name=org.postgresql --resources=${WILDFLY_HOME}/modules/system/layers/base/org/postgresql/main/postgresql.jar --dependencies=javax.api,javax.transaction.api' \
    '/subsystem=datasources/jdbc-driver=postgresql:add(driver-name=postgresql,driver-module-name=org.postgresql,driver-class-name=org.postgresql.Driver)' \
    '# --- SymphonyDS datasource configuration' \
    'data-source add \
    --name=SymphonyDS \
    --jndi-name=java:/SymphonyDS \
    --driver-name=postgresql \
    --connection-url=${env.JDBC_URL} \
    --user-name=${env.DB_USER} \
    --password=${env.DB_PASS} \
    --use-ccm=false \
    --background-validation=true\n'\
    '# --- Simple file-based LDAPAuth domain' \
    '/subsystem=elytron/simple-role-decoder=groups-to-roles:add(attribute=groups)' \
    '/subsystem=elytron/properties-realm=local-users:add(users-file=users.properties,groups-file=groups.properties,relative-to=jboss.server.config.dir,plain-text=true)' \
    '/subsystem=elytron/security-domain=LDAPAuth:add(default-realm=local-users,permission-mapper=default-permission-mapper,realms=[{realm=local-users,role-decoder=groups-to-roles}])' \
    'run-batch' \
    > /opt/add-datasource.cli

# Install Node.js and Angular CLI
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs \
    && npm install -g @angular/cli \
    && rm -rf /var/lib/apt/lists/*

# Expose ports
EXPOSE 8080 9990

# --- Start WildFly, then apply CLI, then keep server in foreground ------------
CMD ["/bin/bash", "-c", "\
  ${WILDFLY_HOME}/bin/standalone.sh -c standalone-full.xml & \
  until ${WILDFLY_HOME}/bin/jboss-cli.sh --connect --commands=\":read-attribute(name=server-state)\" >/dev/null 2>&1; do sleep 1; done; \
  ${WILDFLY_HOME}/bin/jboss-cli.sh --connect --file=/opt/add-datasource.cli; \
  tail -f ${WILDFLY_HOME}/standalone/log/server.log"]