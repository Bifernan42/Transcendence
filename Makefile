# WP_DATA = /home/data/wordpress #define the path to the wordpress data
# DB_DATA = /home/data/mariadb #define the path to the mariadb data

all: up

up: build
	# @mkdir -p $(WP_DATA)
	# @mkdir -p $(DB_DATA)
	export COMPOSE_HTTP_TIMEOUT=120 && docker-compose -f ./srcs/docker-compose.yml up -d

# stop the containers
down:
	docker-compose -f ./srcs/docker-compose.yml down1w

# stop the containers
stop:
	docker-compose -f ./srcs/docker-compose.yml stop

# start the containers
start:
	docker-compose -f ./srcs/docker-compose.yml start

# build the containers
build:
	docker-compose -f ./srcs/docker-compose.yml build

clean:
	@docker stop $$(docker ps -qa) || true
	@docker rm $$(docker ps -qa) || true
	@docker rmi -f $$(docker images -qa) || true
	@docker volume rm $$(docker volume ls -q) || true
	@docker network rm $$(docker network ls -q) || true
	# @rm -rf $(WP_DATA) || true
	# @rm -rf $(DB_DATA) || true

re: clean up

# prune the containers: execute the clean target and remove all containers, images, volumes and networks from the system.
prune: clean
	@docker system prune -a --volumes -f
