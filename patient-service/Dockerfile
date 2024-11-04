# Use an official Node.js runtime as a base image
FROM node:14

# Create and set the working directory
WORKDIR /app

# Copy the single service file to the container
COPY patient-service.js .

# Expose the port the service listens on
EXPOSE 3000

# Define the command to run the service
CMD ["node", "patient-service.js"]

