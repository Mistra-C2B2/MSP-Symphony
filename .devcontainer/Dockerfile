FROM mcr.microsoft.com/devcontainers/java:0-17

# Set environment variables
ENV MAVEN_VERSION=3.9.9 \
    WILDFLY_VERSION=36.0.0.Final \
    POSTGRES_DRIVER_VERSION=42.5.1 

RUN apt-get update \
    && apt-get install -y curl wget unzip gnupg iputils-ping ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install required libraries for WildFly
RUN apt-get update && sudo apt-get install -y \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    postgresql-client

# Install Maven 3.9.9
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    | tar -xz -C /opt \
    && ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven \
    && ln -s /opt/maven/bin/mvn /usr/local/bin/mvn 

# Install WildFly
RUN curl -fsSL https://github.com/wildfly/wildfly/releases/download/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.tar.gz \
    | tar -xz -C /opt \
    && ln -s /opt/wildfly-${WILDFLY_VERSION} /opt/wildfly

# Download PostgreSQL JDBC driver
RUN mkdir -p /opt/wildfly/modules/system/layers/base/org/postgresql/main 
RUN wget https://jdbc.postgresql.org/download/postgresql-${POSTGRES_DRIVER_VERSION}.jar -O /opt/wildfly/modules/system/layers/base/org/postgresql/main/postgresql.jar

# Install Node.js and Angular CLI
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs \
    && npm install -g @angular/cli \
    && rm -rf /var/lib/apt/lists/*

# Expose ports
EXPOSE 8080 9990 4200 5432

# # Copy the WildFly configuration script
# COPY ../config-wildfly.cli /opt/config-wildfly.cli

# # Copy and make the startup script executable
# COPY ../../start-wildfly.sh /opt/start-wildfly.sh
# RUN chmod +x /opt/start-wildfly.sh

#CMD ["../../start-wildfly.sh"] 
CMD ["/bin/bash","-c","sleep infinity"]