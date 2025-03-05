FROM oven/bun:alpine

WORKDIR /app

COPY ./app .

RUN apk --no-cache add nodejs

RUN bun i

CMD ["bun", "run", "start"]

EXPOSE 8080