FROM golang:1.21.1-bullseye AS builder

# Build Args
ARG BUILD_COMMAND="go build -o app ."
ARG BINARY_NAME="app"
ARG CGO_ENABLED="0"
# Env setup
ENV CGO_ENABLED=${CGO_ENABLED}

# Setup workdir
WORKDIR /build

# Copy source code
COPY . .

# Copy AptFile [optional]
RUN test -f AptFile && apt update -yqq && xargs -a AptFile apt install -yqq || true

# Copy SetupCommand [optional]
RUN test -f SetupCommand && while read -r cmd; do eval "$cmd"; done < SetupCommand || true

# Fetch dependencies
RUN go mod download

RUN ${BUILD_COMMAND}

# Runner stage
FROM golang:1.21.1-bullseye AS runner

# Build Args
ARG BINARY_NAME="app"
ARG START_COMMAND="./app"

# Setup workdir
WORKDIR /user

# Copy binary
COPY --from=builder /build/${BINARY_NAME} .

# Install OS dependencies

# Copy AptFile [optional]
COPY AptFile* ./
RUN test -f AptFile && apt update -yqq && xargs -a AptFile apt install -yqq || true

# Copy SetupCommand [optional]
COPY SetupCommand* ./
RUN test -f SetupCommand && while read -r cmd; do eval "$cmd"; done < SetupCommand || true

# Create entrypoint
RUN echo ${START_COMMAND} > /user/entrypoint.sh
RUN chmod +x /user/entrypoint.sh

# Setup Entrypoint
ENTRYPOINT ["sh", "-c", "/user/entrypoint.sh"]
