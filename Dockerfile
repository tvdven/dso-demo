# stage 0 - build artifact from source
FROM maven:3.9.6-eclipse-temurin-11-alpine as BUILD
WORKDIR /app
COPY .  .
RUN mvn package -DskipTests

# stage 1 - package app to run
FROM eclipse-temurin:11-alpine as RUN
WORKDIR /run
COPY --from=BUILD /app/target/demo-0.0.1-SNAPSHOT.jar demo.ja
EXPOSE 8080
CMD java  -jar /run/demo.jar
