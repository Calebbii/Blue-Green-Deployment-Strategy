# Blue-Green Deployment Strategy

## 📋 Project Overview

This project implements a **Blue-Green Deployment** strategy for a web application with **zero-downtime** deployments. The infrastructure runs on AWS using EC2 instances behind an Application Load Balancer (ALB) with separate Blue (production) and Green (new version) environments.

### Key Features
- ✅ Zero-downtime deployments
- ✅ Automated traffic switching between environments
- ✅ CloudWatch monitoring and alarms
- ✅ Instant rollback capability
- ✅ Health check validation before traffic switch

---

### Architecture Components
- **Blue Environment**: Current production version (v1.0.0)
- **Green Environment**: New version ready for switch (v2.0.0)
- **ALB**: Routes traffic between Blue and Green target groups
- **CloudWatch**: Monitors health, latency, and error rates

---



## 📸 Screenshots

### 1. Blue Instance Launched
![Blue Environment](./images/Blue%20instance%20launched.png)
*ALB serving BLUE environment before traffic switch*

### 2. Green Instance Launched
![Green Environment](./images/Green%20instance%20launched.png)
*ALB serving GREEN environment after successful switch*

### 4. Both Instances Running
![Instances Running](./images/Both%20instances%20running.png)
*Both Blue and Green instances in 'running' state*

### 5. Target Groups Created
![Target Groups](./images/Target%20groups%20created.png)
*blue-targets and green-targets created in EC2*

### 3. Target Groups - Healthy Status
![Target Groups](./images/Target%20groups%20created.png)
*Both Blue and Green target groups showing healthy status*

### 6. Blue Target Group - Healthy
![Blue Healthy](./images/Blue%20target%20group%20-%20healthy.png)
*Blue target group shows 'healthy' status*

### 7. Green Target Group - Healthy
![Green Healthy](./images/Green%20target%20group%20-%20healthy.png)
*Green target group shows 'healthy' status after registration*

### 8. ALB Creation Started
![ALB Creation](./images/ALB%20creation%20started.png)
*BlueGreen-ALB creation in progress*

### 9. ALB Active
![ALB Active](./images/ALB%20active.png)
*Load balancer status: active*

### 10. Blue Response from ALB
![Blue Response](./images/Blue%20response%20from%20ALB.png)
*Browser/curl showing BLUE environment (v1.0.0)*

### 11. Green Direct Access
![Green Direct](./images/Green%20direct%20access.png)
*Direct access to Green instance showing v2.0.0*

### 12. Listener Before Edit (Blue)
![Listener Blue](./images/Blue%20response%20from%20ALB.png)
*ALB listener showing default action: blue-targets*

### 13. Listener After Edit (Green)
![Listener Green](./images/Green%20direct%20access.png)
*ALB listener after switch: default action changed to green-targets*

### 14. Green Response from ALB
![Green Response](./images/Green%20direct%20access.png)
*ALB showing GREEN environment after successful switch*

### 6. CloudWatch Alarms
![CloudWatch Alarms](./images/CloudWatch%20alarms.png)
*Monitoring alarms configured for error rate, latency, and health checks*

### 7. Rollback Demonstration
![Rollback](./images/)
*Successful rollback to BLUE environment*

---

## 🚀 Deployment Guide

### Prerequisites
- AWS Account with appropriate permissions
- EC2 Key Pair (`blue-green-key`)
- AWS CLI configured locally

### Deploy Infrastructure

```bash
# Deploy CloudFormation stack
aws cloudformation create-stack \
  --stack-name blue-green-project \
  --template-body file://blue-green.yaml \
  --parameters ParameterKey=KeyName,ParameterValue=blue-green-key \
  --capabilities CAPABILITY_IAM

# Wait for completion
aws cloudformation wait stack-create-complete --stack-name blue-green-project

# Get ALB URL
ALB_URL=$(aws cloudformation describe-stacks \
  --stack-name blue-green-project \
  --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDNS'].OutputValue" \
  --output text)

echo "ALB URL: http://$ALB_URL"