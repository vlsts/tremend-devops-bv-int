# Use the Alpine image of the bun CLI. Why? See README.md
FROM oven/bun:alpine

# Set the working directory to /app
WORKDIR /app

# Copy the files in the ./app directory to the /app directory in the container
COPY ./app .

# Install Node.js in the container
RUN apk --no-cache add nodejs

# Install the dependencies in the package.json file and according to bun.lock
RUN bun i

# Run the start script from package.json when the container starts
CMD ["bun", "run", "start"]

# Make the container listen on port 8080 as requested
EXPOSE 8080