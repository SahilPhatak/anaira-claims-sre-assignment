# Anaira AI Claims Processor- DevOps/SRE Assignment Solution

This document describe the implementation of a cloud-native claims processing platform with observability, resilence testing, and chaos engineering experiments.

The project demonstrates key Site Reliability Engineering practices such asc

• Service Level Objectives (SLOs)
• Error budget monitoring
• Kubernetes autoscaling
• Chaos engineering validation
• Observability-driven debugging

1) Prerequisites
The following tools were used to implement and test the system.

Tool                         Version
Docker                       29.2.1, build a5c7197
Docker Compose               v5.0.2
kubectl                      v1.34.1
Kubernetes                   v1.29.2
Helm                         v3.20.0
Node.js                      v12.22.9
Make                         v4+

Verify installation:
docker --version  
kubectl version --client  
helm version  
node -v  
make --version  

2) One-Command Setup

The project includes a Makefile that automates environment setup and deployment.

Run the following commands:
make setup-local  
make deploy-compose  
make deploy-k8s  
make deploy-chaos
make status

These commands will:

i. Prepare the local development environment
ii. Deploy the observability stack using Docker Compose
iii. Deploy the application to Kubernetes
iv. Run chaos engineering experiments
v. Checks status of kubernetes resources

3) Access URLs

After deployment the following services will be available:

Grafana Dashboard  
http://localhost:3001  
 
Claims Processor API  
http://localhost:3000  

Prometheus Metrics  
http://localhost:9090  

These dashboards can be used to observe system behavior and monitor reliability metrics.

To generate traffic and simulate workload run:

make test-load

This command continuously sends requests to the claims processing API and helps trigger autoscaling and observability metrics.

Clean Teardown

To stop and remove all resources run:

make clean

This will:

• stop Docker containers  
• delete Kubernetes resources  
• clean up the local environment




