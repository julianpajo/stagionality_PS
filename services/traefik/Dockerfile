FROM traefik:v2.4

RUN apk add --no-cache curl

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:80 || exit 1
