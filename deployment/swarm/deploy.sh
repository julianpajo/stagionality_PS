#!/bin/bash

sudo systemctl stop apache2
docker stack deploy -d -c traefik.yml traefik
docker stack deploy -d -c auth.yml auth

sleep 5

traefik_ip=$(docker service inspect traefik_proxy --format='{{range .Endpoint.VirtualIPs}}{{.Addr}}{{end}}' | cut -d'/' -f1)
auth_oauth2proxy_container=$(docker ps -qf "name=auth_oauth2-proxy")
docker exec -u root -i "$auth_oauth2proxy_container" sh -c "echo '$traefik_ip keycloak.euler.local' >> /etc/hosts"

docker stack deploy -d -c euler.yml euler

sleep 5

restapi_container=$(docker ps -qf "name=euler_restapi")
docker exec -u root -i "$restapi_container" sh -c "echo '$traefik_ip geoserver.euler.local' >> /etc/hosts"
docker exec -u root -i "$restapi_container" sh -c "echo '$traefik_ip displacement.euler.local' >> /etc/hosts"

gui_container=$(docker ps -qf "name=euler_gui")
docker exec -u root -i "$gui_container" sh -c "echo '$traefik_ip displacement.euler.local' >> /etc/hosts"
docker exec -u root -i "$gui_container" sh -c "echo '$traefik_ip keycloak.euler.local' >> /etc/hosts"