.PHONY: build run stop start restart logs shell status clean reset help

IMAGE_NAME := 3cx-pbx
CONTAINER_NAME := 3cx-pbx

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image
	docker build -t $(IMAGE_NAME) .

run: ## Build and run the container (first time setup)
	./run.sh

stop: ## Stop the container
	docker stop $(CONTAINER_NAME)

start: ## Start a stopped container
	docker start $(CONTAINER_NAME)

restart: ## Restart the container
	docker restart $(CONTAINER_NAME)

logs: ## Follow container logs
	docker logs -f $(CONTAINER_NAME)

shell: ## Open a shell in the container
	docker exec -it $(CONTAINER_NAME) bash

status: ## Show container status and ports
	@docker ps --filter name=$(CONTAINER_NAME) --format "table {{.Status}}\t{{.Ports}}"
	@echo ""
	@docker exec $(CONTAINER_NAME) ss -tlnp 2>/dev/null || true

update: ## Run 3CX update inside container
	docker exec $(CONTAINER_NAME) bash -c "apt-get update && apt-get upgrade -y 3cxpbx"

clean: ## Stop and remove the container (keeps data)
	docker stop $(CONTAINER_NAME) 2>/dev/null || true
	docker rm $(CONTAINER_NAME) 2>/dev/null || true

reset: ## Full reset - removes container AND all data
	@echo "WARNING: This will delete all 3CX data!"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ]
	docker stop $(CONTAINER_NAME) 2>/dev/null || true
	docker rm $(CONTAINER_NAME) 2>/dev/null || true
	rm -rf ./data/*
	@echo "Reset complete. Run 'make run' to start fresh."

install-deps: ## Check for required dependencies
	@command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed."; exit 1; }
	@echo "All dependencies satisfied."
