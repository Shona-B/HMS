# ============================================================
# Stage 1: Build the application with Maven
# ============================================================
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

# Copy only the pom.xml first so Docker can cache the dependency
# download layer separately from source code changes.
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Now copy the source and build the jar.
COPY src ./src
RUN mvn clean package -DskipTests -B

# ============================================================
# Stage 2: Run the application on a slim JRE (no Maven/JDK bloat)
# ============================================================
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Run as a non-root user for better container security.
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy only the built jar from the build stage.
COPY --from=build /app/target/hospital-management-system.jar app.jar

EXPOSE 8080

# Allow JVM options (e.g. memory limits) to be overridden at runtime
# via `docker run -e JAVA_OPTS="-Xmx512m"`.
ENV JAVA_OPTS=""

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]