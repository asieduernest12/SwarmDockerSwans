help:
	echo $$PWD;
	cat ./Makefile

swarm:
	cd /app
	docker compose exec -it node-a sh -c 'cd /app;apk add make --force; make down'
	docker compose up -d
	docker compose exec -it node-a sh -c "cd /app; apk add make --force; make deploy"
	
c:
	cd /app
	docker -H node-a compose  exec -it sh -c 'cat /config/caddy/Caddyfile.autosave'

services:
	cd /app
	docker compose exec -it node-a sh -c 'docker service ls'

app_log:
	cd /app
	docker compose exec -it node-a sh -c 'docker service logs cs_app'

curl:
	apk add curl;
	curl app.localhost -IL

stack_ps:
	cd /app
	docker compose exec -it node-a sh -c 'docker stack ps cs'

alias:
	ln -sf /app/alias.sh /etc/profile.d/aliases_.sh
