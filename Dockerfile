# stage 0 - build artifact from source
FROM maven:3.9.6-eclipse-temurin-11-alpine as BUILD
WORKDIR /app
COPY .  .
RUN mvn package -DskipTests

# stage 1 - package app to run
FROM eclipse-temurin:11-alpine as RUN
WORKDIR /run
COPY --from=BUILD /app/target/demo-0.0.1-SNAPSHOT.jar demo.jar

# it's important to switch the user at the end of Dockerfile otherwise package cannot be installed 
ARG USER=devops
ENV HOME /home/$USER
RUN  adduser -D $USER && chown $USER:$USER /run/demo.jar

RUN apk add --no-cache curl
HEALTHCHECK --interval=30s --timeout=10s --retries=2 \
    --start-period=20s CMD curl -f http://localhost:8080/ || exit 1

USER $USER

EXPOSE 8080
CMD java  -jar /run/demo.jar
