NAME = inception
COMPOSE = docker compose -f srcs/docker-compose.yml --env-file srcs/.env

DATA_DIR = /home/$(shell grep '^LOGIN=' srcs/.env | cut -d= -f2)/data

all: up

init:
	mkdir -p $(DATA_DIR)/db
	mkdir -p $(DATA_DIR)/wp

build: init
	$(COMPOSE) build --no-cache

up: init
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

re: fclean up

logs:
	$(COMPOSE) logs -f

clean:
	$(COMPOSE) down --volumes --remove-orphans
docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker réseau rm $(docker network ls -q) 2>/dev/null


fclean: clean
	docker image prune -f
