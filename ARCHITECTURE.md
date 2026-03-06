System Architecture
![System Architecture](<Architecture.drawio (1).png>)

• Phase 1 – Observability Stack

In the first phase an observability stack was deployed using Docker Compose.  
Prometheus was used to collect metrics from the Node.js service, while Grafana provided dashboards for monitoring system performance. Loki and Promtail were used for centralized log aggregation and visualization.

• Phase 2 – Kubernetes Deployment

The application was containerized and deployed on a local Kubernetes cluster using Kind.  
Core Kubernetes resources were defined including Deployment, Service, Ingress, and Horizontal Pod Autoscaler (HPA).  
Ingress handled external HTTP routing while the Service exposed the application internally. HPA enabled automatic scaling of pods based on CPU utilization.

• Phase 3 – Event Streaming and Infrastructure as Code**

Kafka was introduced as the event streaming platform using Strimzi.  
The Claims Processor API publishes claim events to a Kafka topic.  
These events are then processed and persisted to object storage using LocalStack which simulates AWS S3 in the local development environment.Infrastructure provisioning for cloud resources was managed using Terraform to simulate production-style infrastructure management.

• Phase 4 – Chaos Engineering and SRE Validation

Chaos engineering experiments were performed using LitmusChaos to validate the resilience of the system.  
Experiments such as pod deletion, CPU stress, and network latency were introduced to test the system's behavior under failure conditions.Kyverno was used as a policy engine to enforce Kubernetes governance policies such as mandatory labels and security controls.


• Data Flow

The data flow of the system begins when a client sends an HTTP POST request to the `/process-claim` endpoint.The request enters the Kubernetes cluster through the Ingress controller and is routed to the Claims Processor API service.The API processes the claim request and publishes an event to a Kafka topic using the Kafka producer.Kafka acts as the event streaming backbone of the architecture, allowing asynchronous processing and decoupling between services.A consumer processes the event and stores the resulting data in LocalStack S3, which emulates AWS S3 storage for local development.

This architecture ensures scalability, reliability, and asynchronous processing of claim events.

• Multi-Account AWS Mapping

In a production environment this architecture would run on AWS using managed services.The local Kind Kubernetes cluster used in this assignment would be replaced with Amazon EKS for production workloads.Kafka deployed via Strimzi would be replaced with Amazon MSK for managed Kafka event streaming.LocalStack S3 used for local development would be replaced with Amazon S3 for durable object storage.
Infrastructure would typically be provisioned using Terraform across multiple AWS accounts such as development, staging, and production.This multi-account strategy improves security isolation, governance, and deployment control across environments.