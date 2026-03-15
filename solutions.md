DevOps / SRE Assignment-Solution

This document presents the implementation, experiments, and observations for the Anaira AI Claims Processor system.

The objective of this assignment was to demonstrate:

• Cloud-native deployment
• Observability-driven debugging 
• Chaos engineering experiments
• Site Reliability Engineering (SRE) practices

• Section 1 – Phase Evidence (Screenshots)
This section contains evidence collected during each phase of the assignment.

Screenshots are used to demonstrate that the infrastructure, observability stack, and chaos experiments were successfully executed.

• Phase 0 – Environment Setup

The development environment was prepared using the required tools including Docker, Kubernetes (Kind), kubectl, Helm, Node.js, and Make.

All required dependencies were installed and verified to ensure compatibility with the project environment.

The Makefile was used to simplify setup and deployment operations.


This command validated local dependencies and prepared the development environment.

• Phase 1- Observability Stack Deployment:-

The observability stack was deployed locally using Docker Compose.

This stack provides monitoring, logging, and tracing capabilities required to analyze system behavior.

Key components deployed:
• Prometheus-Metrics collection
• Grafana - Metrics visualization
• Loki - Log aggregation
• Promtail - Log shipping
• Jaeger - Distributed tracing
• Kafka - Event streaming
• LocalStack - AWS service simulation

Grafana dashboards were used to visualize metrics such as request latency,request rate and error rates.

![Grafana Observability Dashboard](Observability.png)

• Phase 2 – Kubernetes Deployment

The claims processor application was deployed to a Kubernetes cluster created using Kind.

Kubernetes resources deployed include:
• Deployment
• Service
• Ingress
• Horizontal Pod Autoscaler (HPA)

![Pod Auto Restart](k8s-pod-auto-restart.png-1.png)
![HPA Scaling](HPA-scaling-under-load-1.png)
![Kyverno Policy Rejection](kyverno-policy-rejection-1.png)

• Phase 3 — Cloud-Native IaC + Event Streaming

Kafka was integrated into the application to support event-driven processing of claim events.

![Terraform state showing created infrastructure](Terraform-state.png)
![LocalStack S3 and SQS resources](Localstack-s3-sqs.png)
![Kafka topics created](Kafka-topics.png) 

• Phase 4 — Chaos Engineering and SRE Validation

Chaos experiments were deployed using LitmusChaos to test system resilience.

![Kubernetes pod restart during chaos testing](chaos-pod-restart.png) 
![HPA scaling during chaos experiment](chaos-hpa-scaling-1.png) 
![Network latency chaos experiment](chaos-network-latency-1.png)

• Section 2 - Chaos Experiment Results

| Chaos Experiment | Failure Injected | System Response | Recovery Time (RTO) |
|------------------|------------------|-----------------|---------------------|
| Pod Delete | Pod terminated | Kubernetes recreated pod automatically | ~10 seconds |
| CPU Stress | High CPU utilization | HPA scaled pods from 2 → 6 | ~15 seconds |
| Network Latency | Artificial latency injected | Increased response latency and temporary SLO degradation | ~20 seconds |

• Section 3 - Reflection Questions 

Phase 1 — Observability Stack

Question:
Why does the Node.js process crash at exactly 256MB? Why doesn't Kubernetes memory limit help here in Docker Compose? What's the difference between docker run --memory and Kubernetes resource limits?

Answer:
The Node.js service crashes at 256MB because the container has a memory limit set in Docker Compose. As the application keeps large arrays in memory, so the heap keeps growing until it reaches the limit. When that happens, the container eventually exceeds the limit and the linux OOM   i.e.(Out Of Memory) killer terminates the process.
Kubernetes memory limits do not apply in Docker Compose because Docker Compose does not use kubernetes resource management.Kubernetes runs inside a cluster and enforces memory using requests and limits,while Docker Compose only applies container-level limits. 
The main difference is that docker run --memory only sets a maximum memory limit for a container, whereas Kubernetes resource limits include memory requests for scheduling, limits for maximum usage, and automatic pod restart if the container is killed. 

Phase 2 — Kubernetes SRE Practices

Question:
In production at Anaira (AWS EKS), we use a multi-account setup (Dev/UAT/Prod). How would you modify this K8s setup to represent separate accounts? Would you use namespaces, separate clusters, or both?What's the trade-off for insurance compliance (IRDAI audit trails)

Answer:
Since it is already said that the production uses seperate AWS accounts for Dev,UAT and Prod,I would keep seperate EKS clusters in each account.So it reduces the risk of issues in Dev or UAT affecting production.
Within each clusters, i would still like to use kubernetes namespaces to organize applications,teams etc.
The trade-off is that multiple accounts and clusters increase operational complexity and cost,but they also provide security,compliance and reliability which is important for regulated industries like insurance.


Phase 3 — Cloud-Native IaC + Event Streaming

Question:
"In our production AWS setup, we have separate accounts for Dev/UAT/Prod, each with its own VPC. How would you structure Terraform to deploy this same S3 bucket across 3 accounts using Terraform workspaces or separate state files? What's the risk if we use a single state file for multi-account deployments?"
Answer:
Since Dev,UAT and Prod are in separate AWS accounts,I would structure Terraform so that each environment has its own state file.This can be done using Terraform workspaces for each account.So each environment would use different AWS credentials and its own remote state.The same terraform module for the s3 bucket can be reused but it will be deployed separately in each account.
The risk of using a single state file for multiple accounts is that terraform may track resources from all environments together.This can cause changes or deletions in wrong account.Keeping separate state files per account is safer and aligns better with productions and compliance practices.

Phase 4 — Chaos Engineering & SRE Validation

Question:
"In production, what AWS service would replace Litmus for chaos testing? Compare AWS FIS (Fault Injection Simulator) vs Gremlin vs Litmus. Which would you recommend for insurance workloads where downtime directly impacts claim payouts?"

Answer:
In production, AWS Fault Injection Simulator (FIS) would be the best AWS service to replace Litmus for chaos testing.
Litmus is open source and works well with Kubernetes, but it requires more setup and management.
Gremlin is a commercial chaos engineering platform with advanced features and good observability, but it adds extra cost and external dependency.
AWS FIS integrates natively with AWS services, IAM, CloudWatch, and EKS, making it easier to control and audit experiments.
For insurance workloads, where downtime can directly affect claim payouts, I would recommend AWS FIS. It provides controlled experiments, strong IAM permissions and better integration with AWS monitoring and logging which helps support compliance requirements.

• Section 4 - Production Migration Plan

To move this system from a local environment to production, I would deploy the Kubernetes workloads on Amazon EKS instead of Kind. Infrastructure such as S3 buckets, SQS queues, and networking would be provisioned using Terraform in separate AWS accounts for Dev, UAT, and Production. Kafka could be replaced with Amazon MSK for managed event streaming. Observability tools like Prometheus and Grafana would be deployed using Helm charts, while logs could be sent to a centralized logging service such as CloudWatch. This setup would provide better scalability, security isolation, and compliance required for insurance workloads.

• Section 5 — Memory Leak Fix

The application intentionally simulates a memory leak by continuously storing large objects in a global array (`memoryLeakCollector`). Each request allocates about 15 MB of data and pushes it into the array, which causes the heap memory to grow indefinitely.Because the container has a memory limit of 256 MB, the Node.js process eventually exceeds the limit and gets terminated with an Out Of Memory (OOM) error.A simple fix would be to avoid storing request data in a global array and instead process the data without retaining it in memory. For example:
```javascript
app.get('/process-claim', (req, res) => {
  const claimData = new Array(15 * 1024 * 1024).fill('REDACTED_CLAIM_DATA');

  // process claim without storing in global memory
  console.log("Processing claim request");

  res.send("Claim processed successfully");
});