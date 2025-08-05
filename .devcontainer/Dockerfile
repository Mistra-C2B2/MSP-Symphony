FROM mcr.microsoft.com/devcontainers/java:0-17

# Build arguments for database configuration
ARG DB_URL
ARG DB_USER
ARG DB_PASSWORD

# Set environment variables
ENV MAVEN_VERSION=3.9.9 \
    WILDFLY_VERSION=36.0.1.Final \
    POSTGRES_DRIVER_VERSION=42.5.1 \
    MAVEN_HOME=/opt/maven \
    DB_USR=${DB_USER} \
    DB_PWD=${DB_PASSWORD} \
    DB_URL=${DB_URL} 

RUN apt-get update \
    && apt-get install -y curl wget unzip gnupg iputils-ping ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install required libraries for WildFly
RUN apt-get update && sudo apt-get install -y \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6

# Install Maven 3.9.9
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    | tar -xz -C /opt \
    && ln -s /opt/apache-maven-${MAVEN_VERSION} ${MAVEN_HOME} \
    && ln -s ${MAVEN_HOME}/bin/mvn /usr/local/bin/mvn 

# Install WildFly
RUN curl -fsSL https://github.com/wildfly/wildfly/releases/download/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.tar.gz \
    | tar -xz -C /opt \
    && ln -s /opt/wildfly-${WILDFLY_VERSION} /opt/wildfly

# Download PostgreSQL JDBC driver
RUN mkdir -p /opt/wildfly/modules/system/layers/base/org/postgresql/main 
RUN wget https://jdbc.postgresql.org/download/postgresql-${POSTGRES_DRIVER_VERSION}.jar -O /opt/wildfly/modules/system/layers/base/org/postgresql/main/postgresql.jar

# Generate configuration script for WildFly
RUN printf '%s\n' \
    'batch' \
    '# --- PostgreSQL JDBC driver registration' \
    "module add --name=org.postgresql --resources=/opt/wildfly/modules/system/layers/base/org/postgresql/main/postgresql.jar --dependencies=javax.api,javax.transaction.api" \
    '/subsystem=datasources/jdbc-driver=postgresql:add(driver-name=postgresql,driver-module-name=org.postgresql,driver-class-name=org.postgresql.Driver)' \
    '# --- SymphonyDS datasource configuration' \
    "data-source add \
    --name=SymphonyDS \
    --jndi-name=java:/SymphonyDS \
    --driver-name=postgresql \
    --connection-url=jdbc:postgresql:${DB_URL} \
    --user-name=${DB_USER} \
    --password=${DB_PASSWORD}" \
    'run-batch' \
    > /opt/config-wildfly.cli



# RUN /opt/wildfly/bin/jboss-cli.sh --file=/opt/postgresql-driver-registration.cli

# RUN printf '%s\n' \
#     'batch' \
#     '# --- PostgreSQL driver registration' \
#     'module add --name=org.postgresql --resources=/opt/wildfly/modules/system/layers/base/org/postgresql/main/postgresql.jar --dependencies=javax.api,javax.transaction.api' \
#     '/subsystem=datasources/jdbc-driver=postgresql:add(driver-name=postgresql,driver-module-name=org.postgresql,driver-class-name=org.postgresql.Driver)' \
#     '# --- SymphonyDS datasource configuration' \
#     'data-source add \
#     --name=SymphonyDS \
#     --jndi-name=java:/SymphonyDS \
#     --driver-name=postgresql \
#     --connection-url=DB_UR} \
#     --user-name=${env.DB_USER} \
#     --password=${env.DB_PASS} \
#     --use-ccm=false \
#     --background-validation=true\n'\
#     '# --- Simple file-based LDAPAuth domain' \
#     '/subsystem=elytron/simple-role-decoder=groups-to-roles:add(attribute=groups)' \
#     '/subsystem=elytron/properties-realm=local-users:add(users-file=users.properties,groups-file=groups.properties,relative-to=jboss.server.config.dir,plain-text=true)' \
#     '/subsystem=elytron/security-domain=LDAPAuth:add(default-realm=local-users,permission-mapper=default-permission-mapper,realms=[{realm=local-users,role-decoder=groups-to-roles}])' \
#     'run-batch' \
#     > /opt/add-datasource.cli

# Install Node.js and Angular CLI
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs \
    && npm install -g @angular/cli \
    && rm -rf /var/lib/apt/lists/*

# Expose ports
EXPOSE 8080 9990

# Copy and make the startup script executable
COPY start-wildfly.sh /opt/start-wildfly.sh
RUN chmod a+x /opt/start-wildfly.sh

CMD ["/opt/start-wildfly.sh"] 
#CMD ["/bin/bash", "-c"]

