NAME = inception
COMPOSE = docker compose -f srcs/docker-compose.yml --env-file srcs/.env

IMAGES   := nginx wordpress mariadb
VOLUMES  := srcs_db_data srcs_wp_data
NETWORK  := inception

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
	$(COMPOSE) down --remove-orphans

clean: down
	- docker volume rm $(VOLUMES) 2>/dev/null || true
	- docker network rm $(NETWORK) 2>/dev/null || true

fclean: clean
	- docker rmi -f $(IMAGES) 2>/dev/null || true
	- docker image prune -f
	- docker builder prune -f

.PHONY: init build up down re logs clean fclean
