hello:
	cat ./Makefile

deploy:
	docker compose build --push
	docker stack deploy -c docker-compose.yml cs

down:
	docker stack rm cs

service:
	docker service ls

c:
	docker exec -it $$(docker ps -qf name=caddy) sh -c 'cat /config/caddy/Caddyfile.autosave'