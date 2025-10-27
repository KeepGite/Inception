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

fclean: clean
	docker image prune -f
