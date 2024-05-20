FROM bitnami/oauth2-proxy:7.3.0

USER root
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:4180 || exit 1

USER 1001
