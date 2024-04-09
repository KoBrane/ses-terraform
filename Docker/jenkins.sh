#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker could not be found. Please install Docker and try again."
    exit 1
fi

# Pull the latest Jenkins Docker image
echo "Pulling the latest Jenkins Docker image..."
docker pull jenkins/jenkins:lts

# Create a directory to store Jenkins data
JENKINS_HOME_DIR="$HOME/jenkins_home"
mkdir -p "$JENKINS_HOME_DIR"

# Run the Jenkins container
echo "Starting the Jenkins container..."
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v "$JENKINS_HOME_DIR":/var/jenkins_home \
  jenkins/jenkins:lts

# Wait for Jenkins to start
echo "Waiting for Jenkins to start..."
until docker logs jenkins 2>&1 | grep -q "Jenkins is fully up and running"
do
  sleep 5
done

# Display the Jenkins administrator password
echo "Jenkins is up and running!"
echo "The Jenkins administrator password is:"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Open the Jenkins web interface in the default web browser
echo "Opening the Jenkins web interface in the default web browser..."
open "http://localhost:8080"