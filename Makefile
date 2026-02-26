.PHONY: help setup-local deploy-compose deploy-k8s deploy-chaos clean test-load
help:
@echo "Anaira AI Claims Processor - DevOps/SRE Assignment"
@echo ""
@echo "Available targets:"
@echo " make setup-local - Install all local dependencies (Kind, Terraform, Helm)"
@echo " make deploy-compose - Launch Phase 1 (Docker Compose observability stack)"
@echo " make deploy-k8s - Launch Phase 2 (Kubernetes on Kind with Kafka)"
@echo " make deploy-chaos - Launch Phase 3 (Chaos experiments)"
@echo " make test-load - Simulate load until crash (Phase 1 proof)"
@echo " make clean - Destroy all resources"
setup-local:
@echo "📦 Installing local dependencies..."
# TODO: Add checks for Docker, Kind, kubectl, Terraform, Helm
@command -v docker >/dev/null 2>&1 || { echo "Docker not found!"; exit 1; }
@echo "✅ Prerequisites check complete"
deploy-compose:
@echo "🐳 Deploying Phase 1 observability stack..."
docker-compose up -d --build
@echo "✅ Access Grafana at http://localhost:3000 (admin/admin)"
deploy-k8s:
@echo "☸️ Creating Kind cluster with 3 nodes..."
kind create cluster --name anaira-cluster --config kind-config.yaml
kubectl cluster-info --context kind-anaira-cluster
@echo "✅ Deploying application + Kafka to cluster..."
kubectl apply -k k8s/
deploy-chaos:
@echo "💥 Deploying Chaos Engineering experiments..."
# TODO: Apply Litmus ChaosEngine manifests
test-load:
@echo "📈 Simulating claim processing load (will crash after ~17 requests)..."
for i in {1..30}; do curl -s http://localhost:3000/process-claim && sleep 2; done
clean:
@echo "🧹 Cleaning up all resources..."
docker-compose down -v
kind delete cluster --name anaira-cluster
@echo "✅ Cleanup complete"