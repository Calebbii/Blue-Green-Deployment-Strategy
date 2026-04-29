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

### 1. Blue Environment (Current Production)
![Blue Environment](./images/Blue%20instance%20launched.png)
*ALB serving BLUE environment before traffic switch*

### 2. Green Environment (After Switch)
![Green Environment](./images/Green%20direct%20access.png)
*ALB serving GREEN environment after successful switch*

### 3. Target Groups - Healthy Status
![Target Groups](./images/Target%20groups%20created.png)
*Both Blue and Green target groups showing healthy status*

### 4. ALB Listener - Traffic Routing
![Listener Configuration](./images/ALB%20active.png)
*ALB listener forwarding traffic to GREEN target group*

### 5. Application Load Balancer
![Load Balancer](./images/ALB%20active.png)
*BlueGreen-ALB configuration and DNS settings*

### 6. CloudWatch Alarms
![CloudWatch Alarms](./images/CloudWatch%20alarms.png)
*Monitoring alarms configured for error rate, latency, and health checks*

### 7. Rollback Demonstration
![Rollback](screenshots/rollback.png)
*Successful rollback to BLUE environment*


### 1. Security Groups Created
![Security Groups](./screenshots/1-security-groups.png)
*ALB-SG and Web-SG security groups configured*

### 2. Blue Instance Launched
![Blue Instance](./screenshots/2-blue-instance.png)
*Blue environment instance - Production v1.0.0*

### 3. Green Instance Launched
![Green Instance](./screenshots/3-green-instance.png)
*Green environment instance - New version v2.0.0*

### 4. Both Instances Running
![Instances Running](./screenshots/4-instances-running.png)
*Both Blue and Green instances in 'running' state*

### 5. Target Groups Created
![Target Groups](./screenshots/5-target-groups.png)
*blue-targets and green-targets created in EC2*

### 6. Blue Target Group - Healthy
![Blue Healthy](./screenshots/6-blue-healthy.png)
*Blue target group shows 'healthy' status*

### 7. Green Target Group - Healthy
![Green Healthy](./screenshots/7-green-healthy.png)
*Green target group shows 'healthy' status after registration*

### 8. ALB Creation Started
![ALB Creation](./screenshots/8-alb-creation.png)
*BlueGreen-ALB creation in progress*

### 9. ALB Active
![ALB Active](./screenshots/9-alb-active.png)
*Load balancer status: active*

### 10. Blue Response from ALB
![Blue Response](./screenshots/10-blue-response.png)
*Browser/curl showing BLUE environment (v1.0.0)*


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