# Use Alpine Linux as the base image
FROM alpine:latest

# Install bash (if needed for debugging) and any other tools
RUN apk update && apk add --no-cache bash

# Set the working directory to /app
WORKDIR /app

# Copy the entire app folder (the current directory) into /app inside the container
COPY . /app

# Copy the prebuilt server executable to /usr/bin/ and make it executable
RUN cp /app/Server-Side-Pong/zig-out/bin/server /usr/bin/ && \
    chmod +x /usr/bin/server

# Expose the port your server uses (adjust if needed)
EXPOSE 8081

# Launch the server executable
CMD ["/usr/bin/server"]
