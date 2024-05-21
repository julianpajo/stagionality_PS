FROM kartoza/geoserver

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/geoserver/web || exit 1