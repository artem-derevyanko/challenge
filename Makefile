#! /usr/bin/make

.DEFAULT_GOAL := help
mode ?= local

user=1000

app_name = nextjs

docker_compose_bin = $(shell command -v docker-compose 2> /dev/null)
docker_compose_production = $(docker_compose_bin) -f docker-compose.production.yaml --env-file=".env.production"
docker_compose_dev = $(docker_compose_bin) -f docker-compose.development.yaml --env-file=".env.local"

terraform_dir = infrastracture/terraform
terraform_plan = production.plan
terraform_vars = production.tfvars
terraform := @$(shell command -v terraform 2> /dev/null) -chdir=$(terraform_dir)

hasura_bin := npx hasura-cli --project hasura --envfile ../.env.$(mode)

help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

---------------: ## ------[ ACTIONS ]---------
##Actions --------------------------------------------------

init-release: ## Initialize first release on AWS
	$(terraform) init

destroy-release: ## Destroy all resources for created release on AWS
	$(terraform) apply -var-file=$(terraform_vars) -destroy
	@echo "Successfully destroyed..."

release: ## Start release on AWS (Deploy infrastructure on AWS)
	$(terraform) fmt
	$(terraform) plan -var-file=$(terraform_vars) -out=$(terraform_plan)
	$(terraform) apply $(terraform_plan)

	@rm $(terraform_dir)/$(terraform_plan)
	@echo "Successfully released..."

deploy: ## Deploy app changes to AWS
	$(docker_compose_production) build
	$(docker_compose_production) push

	@sleep 60
	@aws ecs update-service --cluster "app-cluster" --service "app-service" --force-new-deployment

up: ## Set up application (start all containers in background and migrate db)
	$(docker_compose_dev) up -d
	$(docker_compose_dev) run --rm --user="$(user)" $(app_name) yarn install

	@make sync-db

start-dev: ## Start application for local development
	$(docker_compose_dev) run --rm --user="$(user)" -p 3000:3000 -p 8101:9229 $(app_name) yarn dev

down: ## Stop application
	$(docker_compose_dev) down

shell: ## Shell app
	$(docker_compose_dev) run --rm --user="$(user)" $(app_name) sh

sync-db: ## Sync all db changes (you can specify argument `MODE` to `production`/`local` (by default)
	$(hasura_bin) metadata apply
	$(hasura_bin) migrate apply
	$(hasura_bin) metadata reload