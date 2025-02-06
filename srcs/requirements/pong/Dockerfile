# Use Alpine Linux as the base image
FROM alpine:latest

# Install bash (if needed for debugging) and any other tools
RUN apk update && apk add --no-cache bash

# Set the working directory to /app
WORKDIR /

# Copy the executable.
COPY ./app/Server-Side-Pong/zig-out/bin/server /bin

RUN chmod +x /bin/server

# Expose the port your server uses (adjust if needed)
EXPOSE 8081

# Launch the server executable
CMD ["/usr/bin/server"]
