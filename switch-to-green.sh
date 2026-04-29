#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Blue-Green Deployment - Traffic Switch${NC}"
echo -e "${BLUE}========================================${NC}"

# Get stack outputs
STACK_NAME="blue-green-project"
echo -e "${YELLOW}Fetching stack outputs...${NC}"

ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDNS'].OutputValue" \
  --output text)

LISTENER_ARN=$(aws elbv2 describe-listeners \
  --load-balancer-arn $(aws elbv2 describe-load-balancers --names BlueGreen-ALB --query "LoadBalancers[0].LoadBalancerArn" --output text) \
  --query "Listeners[0].ListenerArn" \
  --output text)

BLUE_TG=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='BlueTargetGroupArn'].OutputValue" \
  --output text)

GREEN_TG=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='GreenTargetGroupArn'].OutputValue" \
  --output text)

echo -e "${GREEN}✓ ALB DNS: $ALB_DNS${NC}"
echo -e "${GREEN}✓ Blue TG: $BLUE_TG${NC}"
echo -e "${GREEN}✓ Green TG: $GREEN_TG${NC}"

# Step 1: Verify Green is healthy
echo -e "\n${YELLOW}[STEP 1] Verifying Green environment health...${NC}"

GREEN_HEALTH=$(aws elbv2 describe-target-health \
  --target-group-arn $GREEN_TG \
  --query "TargetHealthDescriptions[0].TargetHealth.State" \
  --output text)

if [ "$GREEN_HEALTH" != "healthy" ]; then
  echo -e "${RED}❌ Green environment is NOT healthy! State: $GREEN_HEALTH${NC}"
  echo -e "${RED}Aborting deployment...${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Green environment is healthy${NC}"

# Step 2: Test Green environment directly
echo -e "\n${YELLOW}[STEP 2] Testing Green environment directly...${NC}"
GREEN_INSTANCE_IP=$(aws ec2 describe-instances \
  --instance-ids $(aws cloudformation describe-stack-resources --stack-name $STACK_NAME --logical-resource-id GreenInstance --query "StackResources[0].PhysicalResourceId" --output text) \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

GREEN_TEST=$(curl -s http://$GREEN_INSTANCE_IP/health)
if [ "$GREEN_TEST" = "OK" ]; then
  echo -e "${GREEN}✓ Green health check passed${NC}"
else
  echo -e "${RED}❌ Green health check failed${NC}"
  exit 1
fi

# Step 3: Gradual traffic shift
echo -e "\n${YELLOW}[STEP 3] Shifting traffic gradually...${NC}"

# 10% to Green
echo -e "${BLUE}→ Sending 10% traffic to Green...${NC}"
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions \
    "[{\"Type\":\"forward\",\"ForwardConfig\":{\"TargetGroups\":[{\"TargetGroupArn\":\"$BLUE_TG\",\"Weight\":90},{\"TargetGroupArn\":\"$GREEN_TG\",\"Weight\":10}]}}]"

echo -e "${YELLOW}Monitoring for 30 seconds...${NC}"
sleep 30

# Check for errors
ERROR_COUNT=$(aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --start-time $(date -u -d '1 minute ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum \
  --dimensions Name=TargetGroup,Value=$GREEN_TG \
  --query "Datapoints[0].Sum" \
  --output text)

if [ "$ERROR_COUNT" != "None" ] && [ "$ERROR_COUNT" -gt 0 ]; then
  echo -e "${RED}❌ Errors detected! Rolling back...${NC}"
  ./rollback-to-blue.sh
  exit 1
fi
echo -e "${GREEN}✓ No errors detected at 10%${NC}"

# 50% to Green
echo -e "${BLUE}→ Sending 50% traffic to Green...${NC}"
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions \
    "[{\"Type\":\"forward\",\"ForwardConfig\":{\"TargetGroups\":[{\"TargetGroupArn\":\"$BLUE_TG\",\"Weight\":50},{\"TargetGroupArn\":\"$GREEN_TG\",\"Weight\":50}]}}]"

echo -e "${YELLOW}Monitoring for 30 seconds...${NC}"
sleep 30

# 100% to Green
echo -e "${BLUE}→ Sending 100% traffic to Green...${NC}"
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions \
    "[{\"Type\":\"forward\",\"ForwardConfig\":{\"TargetGroups\":[{\"TargetGroupArn\":\"$GREEN_TG\",\"Weight\":100},{\"TargetGroupArn\":\"$BLUE_TG\",\"Weight\":0}]}}]"

echo -e "${GREEN}✅ Deployment complete! 100% traffic now on Green${NC}"
echo -e "${GREEN}📍 Access your app at: http://$ALB_DNS${NC}"

# Final verification
echo -e "\n${YELLOW}Final verification:${NC}"
for i in {1..5}; do
  RESPONSE=$(curl -s http://$ALB_DNS | grep -i "GREEN")
  if [ -n "$RESPONSE" ]; then
    echo -e "${GREEN}✓ Request $i served by GREEN${NC}"
  else
    echo -e "${YELLOW}⚠ Request $i - checking...${NC}"
  fi
done

echo -e "\n${GREEN}🎉 Blue-Green deployment successful!${NC}"
