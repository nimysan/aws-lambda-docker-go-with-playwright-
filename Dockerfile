# Build stage
FROM golang:1.21-bullseye as builder

WORKDIR /app
COPY go.* ./
COPY main.go ./

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -tags lambda.norpc -o bootstrap main.go

# Runtime stage
FROM public.ecr.aws/lambda/provided:al2

# Install browser dependencies
RUN yum install -y \
    alsa-lib \
    atk \
    cups-libs \
    gtk3 \
    ipa-gothic-fonts \
    libXcomposite \
    libXcursor \
    libXdamage \
    libXext \
    libXi \
    libXrandr \
    libXScrnSaver \
    libXtst \
    pango \
    xorg-x11-fonts-100dpi \
    xorg-x11-fonts-75dpi \
    xorg-x11-fonts-cyrillic \
    xorg-x11-fonts-misc \
    xorg-x11-fonts-Type1 \
    xorg-x11-utils \
    && yum clean all

# Install Playwright browser
COPY --from=mcr.microsoft.com/playwright/go:v1.40.0-jammy /ms-playwright /ms-playwright

# Set browser path environment variable
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# Copy binary from builder
COPY --from=builder /app/bootstrap /var/runtime/bootstrap

# Set permissions
RUN chmod 755 /var/runtime/bootstrap

# Set the CMD to your handler
ENTRYPOINT [ "/var/runtime/bootstrap" ]
