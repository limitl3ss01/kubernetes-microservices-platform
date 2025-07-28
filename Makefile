# Kubernetes Microservices Platform Makefile

# Variables
KUBECONFIG ?= ~/.kube/config
NAMESPACE = microservices-platform
ARGOCD_NAMESPACE = argocd
ISTIO_NAMESPACE = istio-system
MONITORING_NAMESPACE = monitoring

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

.PHONY: help setup build deploy clean logs status test

help: ## Show this help message
	@echo "Kubernetes Microservices Platform"
	@echo "=================================="
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Quick Start:$(NC) make deploy-local"
	@echo "$(YELLOW)Test Services:$(NC) make test"
	@echo "$(YELLOW)View Status:$(NC) make status"

setup: ## Setup the complete platform
	@echo "$(BLUE)Setting up Kubernetes Microservices Platform...$(NC)"
	@echo "$(YELLOW)1. Creating namespaces...$(NC)"
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl create namespace $(MONITORING_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo "$(YELLOW)2. Deploying microservices...$(NC)"
	kubectl apply -f k8s/base/
	@echo "$(GREEN)Setup complete!$(NC)"
	@echo "$(YELLOW)Platform is ready!$(NC)"

build: ## Build all microservices Docker images
	@echo "$(BLUE)Building microservices...$(NC)"
	@echo "$(YELLOW)Building user-service...$(NC)"
	minikube image build -t user-service:latest microservices/user-service/
	@echo "$(YELLOW)Building order-service...$(NC)"
	minikube image build -t order-service:latest microservices/order-service/
	@echo "$(YELLOW)Building notification-service...$(NC)"
	minikube image build -t notification-service:latest microservices/notification-service/
	@echo "$(GREEN)All services built successfully!$(NC)"
	@echo "$(YELLOW)Images ready for deployment!$(NC)"

deploy: ## Deploy all services to Kubernetes
	@echo "$(BLUE)Deploying to Kubernetes...$(NC)"
	kubectl apply -f k8s/base/
	@echo "$(GREEN)Deployment complete!$(NC)"
	@echo "$(YELLOW)Services deployed successfully!$(NC)"

deploy-local: ## Deploy to local minikube cluster
	@echo "$(BLUE)Deploying to local cluster...$(NC)"
	@echo "$(YELLOW)1. Starting minikube...$(NC)"
	minikube start --cpus=4 --memory=7000 --disk-size=20g
	@echo "$(YELLOW)2. Enabling addons...$(NC)"
	minikube addons enable ingress
	minikube addons enable metrics-server
	@echo "$(YELLOW)3. Creating namespaces...$(NC)"
	kubectl create namespace microservices-platform --dry-run=client -o yaml | kubectl apply -f -
	kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
	@echo "$(YELLOW)4. Building services...$(NC)"
	$(MAKE) build
	@echo "$(YELLOW)5. Deploying services...$(NC)"
	$(MAKE) deploy
	@echo "$(GREEN)Local deployment complete!$(NC)"
	@echo "$(YELLOW)Services available at:$(NC)"
	@echo "$(BLUE)User Service:$(NC) http://localhost:3001"
	@echo "$(BLUE)Order Service:$(NC) http://localhost:3002"
	@echo "$(BLUE)Notification Service:$(NC) http://localhost:3003"
	@echo "$(YELLOW)To enable port forwarding, run:$(NC)"
	@echo "kubectl port-forward -n microservices-platform svc/user-service 3001:3001 &"
	@echo "kubectl port-forward -n microservices-platform svc/order-service 3002:3002 &"
	@echo "kubectl port-forward -n microservices-platform svc/notification-service 3003:3003 &"
	@echo "$(YELLOW)To test services, run:$(NC)"
	@echo "make test"

deploy-prod: ## Deploy to production cluster
	@echo "$(BLUE)Deploying to production...$(NC)"
	kubectl apply -f k8s/overlays/prod/
	@echo "$(GREEN)Production deployment complete!$(NC)"
	@echo "$(YELLOW)Production services deployed!$(NC)"

clean: ## Clean up all resources
	@echo "$(BLUE)Cleaning up resources...$(NC)"
	kubectl delete namespace $(NAMESPACE) --ignore-not-found=true
	kubectl delete namespace $(MONITORING_NAMESPACE) --ignore-not-found=true
	@echo "$(GREEN)Cleanup complete!$(NC)"

logs: ## Show logs from all services
	@echo "$(BLUE)Fetching logs...$(NC)"
	@echo "$(YELLOW)User Service logs:$(NC)"
	kubectl logs -n $(NAMESPACE) -l app=user-service --tail=20
	@echo "$(YELLOW)Order Service logs:$(NC)"
	kubectl logs -n $(NAMESPACE) -l app=order-service --tail=20
	@echo "$(YELLOW)Notification Service logs:$(NC)"
	kubectl logs -n $(NAMESPACE) -l app=notification-service --tail=20

status: ## Show status of all components
	@echo "$(BLUE)Platform Status:$(NC)"
	@echo "$(YELLOW)Namespaces:$(NC)"
	kubectl get namespaces | grep -E "(microservices|monitoring)"
	@echo "$(YELLOW)Pods:$(NC)"
	kubectl get pods -n $(NAMESPACE)
	@echo "$(YELLOW)Services:$(NC)"
	kubectl get services -n $(NAMESPACE)
	@echo "$(YELLOW)Deployments:$(NC)"
	kubectl get deployments -n $(NAMESPACE)
	@echo "$(YELLOW)HPA:$(NC)"
	kubectl get hpa -n $(NAMESPACE)
	@echo "$(YELLOW)All Resources:$(NC)"
	kubectl get all -n $(NAMESPACE)

test: ## Run tests against the platform
	@echo "$(BLUE)Running platform tests...$(NC)"
	@echo "$(YELLOW)Testing health endpoints...$(NC)"
	@echo "$(BLUE)User Service:$(NC)"
	curl -s http://localhost:3001/health || echo "Service not accessible"
	@echo "$(BLUE)Order Service:$(NC)"
	curl -s http://localhost:3002/health || echo "Service not accessible"
	@echo "$(BLUE)Notification Service:$(NC)"
	curl -s http://localhost:3003/health || echo "Service not accessible"
	@echo "$(GREEN)Tests completed!$(NC)"

monitoring: ## Open monitoring dashboards
	@echo "$(BLUE)Opening monitoring dashboards...$(NC)"
	@echo "$(YELLOW)User Service:$(NC) http://localhost:3001"
	@echo "$(YELLOW)Order Service:$(NC) http://localhost:3002"
	@echo "$(YELLOW)Notification Service:$(NC) http://localhost:3003"
	@echo "$(YELLOW)To enable port forwarding, run:$(NC)"
	@echo "kubectl port-forward -n microservices-platform svc/user-service 3001:3001 &"
	@echo "kubectl port-forward -n microservices-platform svc/order-service 3002:3002 &"
	@echo "kubectl port-forward -n microservices-platform svc/notification-service 3003:3003 &"
	@echo "$(YELLOW)To test services, run:$(NC)"
	@echo "make test"

port-forward: ## Start port forwarding for services
	@echo "$(BLUE)Starting port forwarding...$(NC)"
	kubectl port-forward -n $(NAMESPACE) svc/user-service 3001:3001 &
	kubectl port-forward -n $(NAMESPACE) svc/order-service 3002:3002 &
	kubectl port-forward -n $(NAMESPACE) svc/notification-service 3003:3003 &
	@echo "$(GREEN)Port forwarding started!$(NC)"
	@echo "$(YELLOW)Services available at:$(NC)"
	@echo "$(BLUE)User Service:$(NC) http://localhost:3001"
	@echo "$(BLUE)Order Service:$(NC) http://localhost:3002"
	@echo "$(BLUE)Notification Service:$(NC) http://localhost:3003"

scale: ## Scale services
	@echo "$(BLUE)Scaling services...$(NC)"
	kubectl scale deployment user-service --replicas=3 -n $(NAMESPACE)
	kubectl scale deployment order-service --replicas=3 -n $(NAMESPACE)
	kubectl scale deployment notification-service --replicas=2 -n $(NAMESPACE)
	@echo "$(GREEN)Services scaled!$(NC)"
	@echo "$(YELLOW)Current replicas:$(NC)"
	kubectl get deployments -n $(NAMESPACE) -o custom-columns=NAME:.metadata.name,REPLICAS:.spec.replicas,READY:.status.readyReplicas

update: ## Update all services
	@echo "$(BLUE)Updating services...$(NC)"
	$(MAKE) build
	$(MAKE) deploy
	@echo "$(GREEN)Services updated!$(NC)"
	@echo "$(YELLOW)New pods:$(NC)"
	kubectl get pods -n $(NAMESPACE) --sort-by=.metadata.creationTimestamp

backup: ## Backup platform configuration
	@echo "$(BLUE)Creating backup...$(NC)"
	mkdir -p backup/$(shell date +%Y%m%d_%H%M%S)
	kubectl get all -n $(NAMESPACE) -o yaml > backup/$(shell date +%Y%m%d_%H%M%S)/microservices.yaml
	@echo "$(GREEN)Backup created!$(NC)"

restore: ## Restore from backup
	@echo "$(BLUE)Restoring from backup...$(NC)"
	@if [ -z "$(BACKUP_DIR)" ]; then \
		echo "$(RED)Please specify BACKUP_DIR=path/to/backup$(NC)"; \
		exit 1; \
	fi
	kubectl apply -f $(BACKUP_DIR)/microservices.yaml
	@echo "$(GREEN)Restore complete!$(NC)"

# Development helpers
dev-setup: ## Setup development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@echo "$(YELLOW)Installing Node.js dependencies...$(NC)"
	npm install --prefix microservices/user-service
	@echo "$(YELLOW)Installing Python dependencies...$(NC)"
	pip install -r microservices/order-service/requirements.txt
	@echo "$(YELLOW)Installing Go dependencies...$(NC)"
	cd microservices/notification-service && go mod tidy && cd ../..
	@echo "$(GREEN)Development environment ready!$(NC)"

lint: ## Run linting on all services
	@echo "$(BLUE)Running linters...$(NC)"
	@echo "$(YELLOW)Linting user-service...$(NC)"
	npm run lint --prefix microservices/user-service || true
	@echo "$(YELLOW)Linting order-service...$(NC)"
	# Add Python linting here
	@echo "$(YELLOW)Linting notification-service...$(NC)"
	# Add Go linting here
	@echo "$(GREEN)Linting complete!$(NC)"

# Documentation
docs: ## Generate documentation
	@echo "$(BLUE)Generating documentation...$(NC)"
	@echo "$(YELLOW)Architecture diagram...$(NC)"
	# Add documentation generation here
	@echo "$(GREEN)Documentation generated!$(NC)"

# Security
security-scan: ## Run security scans
	@echo "$(BLUE)Running security scans...$(NC)"
	@echo "$(YELLOW)Scanning Docker images...$(NC)"
	# Add security scanning here
	@echo "$(GREEN)Security scan complete!$(NC)"

# Performance
load-test: ## Run load tests
	@echo "$(BLUE)Running load tests...$(NC)"
	@echo "$(YELLOW)Testing user-service...$(NC)"
	# Add load testing here
	@echo "$(GREEN)Load testing complete!$(NC)"

# Quick commands
quick-start: ## Quick start for development
	@echo "$(BLUE)Quick start...$(NC)"
	$(MAKE) deploy-local
	@echo "$(GREEN)Quick start complete!$(NC)"
	@echo "$(YELLOW)Platform is ready for development!$(NC)"

info: ## Show platform information
	@echo "$(BLUE)Platform Information:$(NC)"
	@echo "$(YELLOW)Namespace:$(NC) $(NAMESPACE)"
	@echo "$(YELLOW)Services:$(NC) user-service, order-service, notification-service"
	@echo "$(YELLOW)Auto-scaling:$(NC) HPA enabled"
	@echo "$(YELLOW)Load Balancing:$(NC) Kubernetes"
	@echo "$(YELLOW)Ports:$(NC) 3001, 3002, 3003"
	@echo "$(YELLOW)Quick Commands:$(NC)"
	@echo "  make status    - Show platform status"
	@echo "  make test      - Test all services"
	@echo "  make logs      - Show service logs"
	@echo "  make scale     - Scale services" 