# 建置階段
FROM eclipse-temurin:17-jdk AS build

WORKDIR /app

COPY build.gradle .
COPY settings.gradle .
COPY src ./src

RUN apt update && apt install -y wget unzip
RUN wget https://services.gradle.org/distributions/gradle-8.4-bin.zip -O gradle.zip \
    && unzip gradle.zip -d /opt \
    && ln -s /opt/gradle-8.4/bin/gradle /usr/bin/gradle

RUN gradle clean build

# 執行階段
FROM eclipse-temurin:17-jre

WORKDIR /app

COPY --from=build /app/build/libs/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]

