FROM golang:latest as builder
WORKDIR /app

RUN go mod init config-updater
RUN go mod tidy
RUN go mod download

# Copy the rest of the files
COPY . .

# Copy the remaining of required files
RUN go get k8s.io/apimachinery/pkg/apis/meta/v1
RUN go get k8s.io/client-go/kubernetes
RUN go get k8s.io/client-go/tools/clientcmd

# Build the Go app
RUN CGO_ENABLED=0 GOOS=linux go build -o /go/bin/config-updater

FROM alpine:latest
RUN apk --no-cache add ca-certificates
COPY --from=builder /go/bin/config-updater /usr/local/bin/config-updater
CMD ["config-updater"]
