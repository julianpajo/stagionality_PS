FROM quay.io/keycloak/keycloak:legacy

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/auth/realms/master || exit 1