FROM node:18.18.0-bullseye
WORKDIR /app

# Copy source code
COPY . .

# Copy AptFile [optional]
RUN test -f AptFile && apt update -yqq && xargs -a AptFile apt install -yqq || true

# Copy SetupCommand [optional]
RUN test -f SetupCommand && while read -r cmd; do eval "$cmd"; done < SetupCommand || true

# Install dependencies
ARG SETUP_COMMAND="npm install"
RUN ${SETUP_COMMAND}

# Start the app
ARG START_COMMAND="npm run start"
RUN echo "${START_COMMAND}" > /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["sh", "-c", "/app/entrypoint.sh"]