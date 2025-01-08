FROM amazoncorretto:21.0.5-alpine3.18
COPY . /app
WORKDIR /app
EXPOSE 8080
RUN apk add maven
RUN mvn clean package
CMD java -jar /app/target/demo-0.0.1-SNAPSHOT.jar