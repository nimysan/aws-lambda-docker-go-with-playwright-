# Stage 1: Modules caching
FROM golang:1.22 as modules
COPY go.mod go.sum /modules/
WORKDIR /modules
RUN go mod download

# Stage 2: Build
FROM golang:1.22 as builder
COPY --from=modules /go/pkg /go/pkg
COPY . /workdir
WORKDIR /workdir
# Install playwright cli with right version for later use
RUN PWGO_VER=$(grep -oE "playwright-go v\S+" /workdir/go.mod | sed 's/playwright-go //g') \
    && go install github.com/playwright-community/playwright-go/cmd/playwright@${PWGO_VER}
# Build your app
RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o /bin/bootstrap

# Stage 3: Final Lambda Image
FROM public.ecr.aws/lambda/provided:al2
# Copy the bootstrap executable and playwright binary
COPY --from=builder /bin/bootstrap /var/runtime/bootstrap
COPY --from=builder /go/bin/playwright /usr/local/bin/playwright

# Install required system dependencies for Playwright
RUN yum update -y \
    && yum install -y \
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
    && yum clean all \
    && rm -rf /var/cache/yum

# Install Playwright browsers and dependencies
RUN /usr/local/bin/playwright install --with-deps chromium

# Set execute permissions for the bootstrap
RUN chmod +x /var/runtime/bootstrap

# Set the CMD to the Lambda runtime bootstrap
CMD ["bootstrap"]
