# Build a static binary, ship it on distroless (no shell, runs as non-root).
FROM golang:1.27-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/ ./cmd/ai-service ./cmd/rag-eval \
 && mkdir -p /out/data

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/ai-service /out/rag-eval /
# Settings saved from /admin live here; mount a volume to keep them.
COPY --from=build --chown=65532:65532 --chmod=700 /out/data /data
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/ai-service"]
