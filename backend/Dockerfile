# Build and run GoService API (Dart Shelf). Suitable for Cloud Run, Fly.io, Railway, etc.
FROM dart:stable AS build
WORKDIR /app
COPY pubspec.yaml ./
RUN dart pub get
COPY bin ./bin
RUN dart compile exe bin/server.dart -o /app/server

FROM debian:bookworm-slim
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/server /usr/local/bin/goservice-api
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/goservice-api"]
