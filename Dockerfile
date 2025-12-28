# Dockerfile
FROM golang:1.20-buster AS builder
WORKDIR /src
ADD . .

RUN go env -w GO111MODULE=auto
RUN go build -o main .

FROM gcr.io/distroless/base-debian10
WORKDIR /
COPY --from=builder /src/main /main
COPY --from=builder /src/index.html /index.html
EXPOSE 3000
ENTRYPOINT ["/main"]