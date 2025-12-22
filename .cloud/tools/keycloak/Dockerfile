# Use the official Keycloak image as base
FROM quay.io/keycloak/keycloak:26.4.7 as builder

# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

WORKDIR /opt/keycloak

RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:26.4.7
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Configure ports
#ENV KC_HOSTNAME=localhost

# Copy custom realms if needed
COPY realms/sso-realm.json /opt/keycloak/data/import/api-realm-realm.json

EXPOSE 8080
# EXPOSE 9000

# Start Keycloak in production mode
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]