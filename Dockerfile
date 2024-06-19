FROM golang:1.22-bookworm as builder

# Create and change to the app directory.
WORKDIR /app
ARG ARCH="amd64"
ARG OS="linux"
# Retrieve application dependencies.
# This allows the container build to reuse cached dependencies.
# Expecting to copy go.mod and if present go.sum.
COPY go.mod go.sum ./
RUN go mod download
COPY ./ ./  /app/

ENV PORT=7979

RUN CGO_ENABLED=1 go build -v -o librdkafka-prometheus-exporter

# Use the official Debian slim image for a lean production container.
# https://hub.docker.com/_/debian
# https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds
FROM debian:bookworm-slim
ARG ARCH="amd64"
ARG OS="linux"
RUN set -x && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy the binary to the production image from the builder stage. 
COPY --from=builder /app/librdkafka-prometheus-exporter /bin/librdkafka-prometheus-exporter
 
ENV PORT=7979
 
EXPOSE      7979
USER        nobody
ENTRYPOINT  [ "/bin/librdkafka-prometheus-exporter"]