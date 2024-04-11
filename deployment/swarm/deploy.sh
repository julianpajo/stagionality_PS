#!/bin/bash

sudo systemctl stop apache2
docker stack deploy -c traefik.yml traefik
docker stack deploy -c auth.yml auth

sleep 5

traefik_ip=$(docker service inspect traefik_proxy --format='{{range .Endpoint.VirtualIPs}}{{.Addr}}{{end}}' | cut -d'/' -f1)
auth_oauth2proxy_container=$(docker ps -qf "name=auth_oauth2-proxy")
docker exec -u root -i "$auth_oauth2proxy_container" sh -c "echo '$traefik_ip keycloak.euler.local' >> /etc/hosts"


docker stack deploy -c euler.yml euler