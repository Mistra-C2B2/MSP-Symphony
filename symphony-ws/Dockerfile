# Builder image
FROM maven:3.9.7-eclipse-temurin-17 AS build
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn -B package -DskipTests

# Runtime image
FROM quay.io/wildfly/wildfly:36.0.1.Final
COPY --from=build /build/target/*.war /opt/jboss/wildfly/standalone/deployments/symphony.war
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-c", "standalone-full.xml"]
