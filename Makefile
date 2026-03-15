.PHONY: help setup-local install run build-image deploy-compose deploy-k8s terraform deploy-kafka litmus deploy-chaos test-load clean status

help:
	@echo "Anaira AI Claims Processor - DevOps/SRE Assignment"
	@echo ""
	@echo "Available targets:"
	@echo " make setup-local     - Verify local dependencies"
	@echo " make build-image     - Build claims processor Docker image"
	@echo " make deploy-compose  - Start Docker observability stack"
	@echo " make deploy-k8s      - Create Kind cluster, install nginx ingress, kyverno and deploy app"
	@echo " make terraform       - Deploy infrastructure using Terraform"
	@echo " make deploy-kafka    - Deploy Kafka and topics using Strimzi"
	@echo " make litmus          - Install LitmusChaos for chaos experiments"
	@echo " make deploy-chaos    - Run chaos experiments"
	@echo " make test-load       - Generate load on claims processor"
	@echo " make clean           - Destroy all resources"
	@echo " make status          - Check Kubernetes resources status"

setup-local:
	@echo "Checking local dependencies..."
	docker --version
	docker compose version
	kubectl version --client
	helm version
	node -v
	make --version
	@echo "All prerequisites installed"


build-image:
	@echo "Building Docker image..."
	docker build -t claims-processor:v1 ./app

deploy-compose:
	@echo "Starting observability stack..."
	docker compose up -d --build
	@echo "Grafana available at http://localhost:3001 (admin/admin)"

deploy-k8s:
	@echo "Creating Kind Kubernetes cluster..."
	kind create cluster --name anaira-cluster --config kind-config.yaml || true
	kubectl cluster-info --context kind-anaira-cluster
	@echo "Loading docker image into kind...."
	kind load docker-image claims-processor:v1 --name anaira-cluster
	@echo "Installing Nginx Ingress Controller..."
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	@echo "Installing Kyverno..."
	helm repo add kyverno https://kyverno.github.io/kyverno/
	helm repo update
	helm install kyverno kyverno/kyverno -n kyverno --create-namespace --version 3.0.0
	@echo "Installing Metrics Server..."
	kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
	kubectl patch deployment metrics-server -n kube-system \
	--type=json \
	-p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

	sleep 20
	@echo "Deploying application manifests..."
	kubectl apply -f k8s/app/configmap.yaml
	kubectl apply -f k8s/app/deployment.yaml
	kubectl apply -f k8s/app/service.yaml
	kubectl apply -f k8s/app/hpa.yaml
	kubectl apply -f k8s/app/network-policy.yaml
	@echo "Deploying Kyverno policies..."
	kubectl apply -f k8s/policies/require-labels.yaml
	@echo "Deploying Ingress resources..."
	kubectl apply -f k8s/ingress.yaml
	@echo "Kubernetes deployment complete"

terraform:
	@echo "Deploying infrastructure using Terraform..."
	cd terraform && terraform init && terraform apply -auto-approve
	@echo "Terraform deployment complete"

deploy-kafka:
	@echo "Creating namespace for Kafka..."
	kubectl create namespace kafka || true
	@echo "Installing Strimzi Kafka Operator..."
	kubectl apply -f https://strimzi.io/install/latest?namespace=kafka -n kafka
	@echo "Applying Kafka cluster configuration..."
	sleep 20
	kubectl apply -f kafka.yaml
	@echo "Creating Kafka topics..."
	kubectl apply -f kafka-topics.yaml
	@echo "Kafka deployment complete"

litmus:
	@echo "Installing LitmusChaos..."
	kubectl apply -f https://litmuschaos.github.io/litmus/litmus-operator-v3.0.0.yaml
	@echo "Verifying LitmusChaos installation..."
	kubectl get pods -n litmus

deploy-chaos:
	@echo "Deploying chaos experiments..."
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