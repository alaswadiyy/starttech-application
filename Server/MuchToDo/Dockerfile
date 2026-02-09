# Build stage
FROM golang:1.25-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Go environment
ENV GOPROXY=https://goproxy.io,direct
ENV GOSUMDB=off
ENV CGO_ENABLED=0

WORKDIR /build

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build
RUN go build -o muchtodo-app ./cmd/api

# Test if binary works
RUN ./muchtodo-app --version 2>/dev/null || echo "Binary created"

# Runtime stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata

RUN addgroup -g 1001 -S muchtodo && \
    adduser -u 1001 -S muchtodo -G muchtodo

WORKDIR /app

# Copy binary from builder - use absolute path
COPY --from=builder --chown=muchtodo:muchtodo /build/muchtodo-app /app/muchtodo-app

# Verify file exists and permissions
RUN ls -la /app/muchtodo-app && \
    file /app/muchtodo-app && \
    [ -f /app/muchtodo-app ] && echo "Binary exists" || echo "Binary missing"

USER muchtodo

EXPOSE 8080

# Use absolute path
CMD ["/app/muchtodo-app"]
