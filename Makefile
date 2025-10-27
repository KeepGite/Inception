NAME     := inception
COMPOSE  := docker compose -f srcs/docker-compose.yml --env-file srcs/.env

LOGIN    ?= $(shell awk -F= '/^LOGIN=/{print $$2}' srcs/.env 2>/dev/null)
LOGIN    ?= $(shell whoami)

DATA_DIR := /home/$(LOGIN)/data

IMAGES   := nginx wordpress mariadb
VOLUMES  := srcs_db_data srcs_wp_data
NETWORK  := inception

.PHONY: all init build up down logs ps clean fclean re

all: up

init:
	@mkdir -p $(DATA_DIR)/db
	@mkdir -p $(DATA_DIR)/wp

build: init
	$(COMPOSE) build

rebuild: init
	$(COMPOSE) build --no-cache

up: init
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down --remove-orphans

logs:
	$(COMPOSE) logs -f --tail=100

ps:
	$(COMPOSE) ps

clean: down
	- docker network rm $(NETWORK) 2>/dev/null || true

fclean: clean
	- docker volume rm $(VOLUMES) 2>/dev/null || true
	- docker rmi -f $(IMAGES) 2>/dev/null || true
	- docker image prune -f
	- docker builder prune -f

re: fclean up

