# Build a static binary, ship it on distroless (no shell, runs as non-root).
FROM golang:1.25-alpine AS build
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/ai-service ./cmd/ai-service

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/ai-service /ai-service
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/ai-service"]
