.PHONY: help setup-local build-image deploy-compose deploy-k8s deploy-kafka deploy-chaos test-load clean

help:
	@echo "Anaira AI Claims Processor - DevOps/SRE Assignment"
	@echo ""
	@echo "Available targets:"
	@echo " make setup-local     - Verify local dependencies"
	@echo " make build-image     - Build claims processor Docker image"
	@echo " make deploy-compose  - Start Docker observability stack"
	@echo " make deploy-k8s      - Create Kind cluster and deploy app"
	@echo " make deploy-kafka    - Deploy Kafka and Kafka topics"
	@echo " make deploy-chaos    - Run chaos experiments"
	@echo " make test-load       - Generate load on claims processor"
	@echo " make clean           - Destroy all resources"
    @echo "make status		     - Check status of Kubernetes resources"

setup-local:
	@echo "Checking local dependencies..."
	@command -v docker >/dev/null 2>&1 || { echo "Docker not installed"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "kubectl not installed"; exit 1; }
	@command -v kind >/dev/null 2>&1 || { echo "Kind not installed"; exit 1; }
	@echo "All prerequisites installed"

build-image:
	@echo "Building Docker image..."
	docker build -t claims-processor:v1 .

deploy-compose:
	@echo "Starting observability stack..."
	docker compose up -d --build
	@echo "Grafana available at http://localhost:3000  (admin/admin)"

deploy-k8s:
	@echo "Creating Kind Kubernetes cluster..."
	kind create cluster --name anaira-cluster --config kind-config.yaml || true
	kubectl cluster-info --context kind-anaira-cluster
	@echo "Deploying application manifests..."
	kubectl apply -f k8s/
	@echo "Kubernetes deployment complete"

deploy-kafka:
	@echo "Deploying Kafka cluster using Strimzi..."
	kubectl apply -f kafka.yaml
	@echo "Creating Kafka topics..."
	kubectl apply -f kafka-topics.yaml
	@echo "Kafka deployment complete"

deploy-chaos:
	@echo "Deploying Chaos Engineering experiments..."
	kubectl apply -f k8s/chaos/cpu-stress.yaml
	kubectl apply -f k8s/chaos/network-latency.yaml
	kubectl apply -f k8s/chaos/pod-delete.yaml
	@echo "Chaos experiments deployed"

test-load:
	@echo "Generating load on claims processor..."
	for i in {1..30}; do \
		curl -s http://localhost:3000/process-claim; \
		sleep 2; \
	done
	@echo "Load test finished"

clean:
	@echo "Cleaning up Docker resources..."
	docker compose down -v
	@echo "Deleting Kind cluster..."
	kind delete cluster --name anaira-cluster
	@echo "Cleanup complete"

status:
  	@echo "Kubernetes Pods:"
	kubectl get pods -A
	@echo "Services:"
	kubectl get svc
	@echo "Deployments:"
	kubectl get deployments
	@echo "HPAs:"
	kubectl get hpa