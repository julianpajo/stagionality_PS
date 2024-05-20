FROM postgres:12-bullseye

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD pg_isready -U keycloak || exit 1