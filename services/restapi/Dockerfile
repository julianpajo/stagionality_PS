#####################################################################
# First layer, package the application with maven
#####################################################################
FROM maven:3.9.5-eclipse-temurin-21 AS build
WORKDIR /app
COPY . .
RUN mvn clean package -Dmaven.test.skip=true

#####################################################################
# Second layer, create layered application to improve Image efficiency
#####################################################################
FROM eclipse-temurin:21-jre-alpine AS builder
WORKDIR /application
COPY --from=build /app/target/*.jar application.jar
RUN java -Djarmode=layertools -jar application.jar extract

#####################################################################
# Third layer, copy the application and assign default non-root user
#####################################################################
FROM eclipse-temurin:21-jre-alpine
RUN apk -U upgrade
RUN apk --no-cache add curl
WORKDIR /application
COPY --from=builder application/dependencies/ ./
COPY --from=builder application/spring-boot-loader/ ./
COPY --from=builder application/snapshot-dependencies/ ./
COPY --from=builder application/application/ ./

USER root

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -IsS http://localhost:8081/health | head -n 1 | grep "200 OK" || exit 1

ENTRYPOINT ["java", "-Dreactor.netty.http.server.accessLogEnabled=true",  "-Dspring.profiles.active=prod", "org.springframework.boot.loader.JarLauncher"]
