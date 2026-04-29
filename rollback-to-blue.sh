#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}🚨 EMERGENCY ROLLBACK INITIATED 🚨${NC}"
echo -e "${RED}========================================${NC}"

STACK_NAME="blue-green-project"

# Get resources
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

echo -e "${YELLOW}Switching ALL traffic back to BLUE...${NC}"

aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions \
    "[{\"Type\":\"forward\",\"ForwardConfig\":{\"TargetGroups\":[{\"TargetGroupArn\":\"$BLUE_TG\",\"Weight\":100},{\"TargetGroupArn\":\"$GREEN_TG\",\"Weight\":0}]}}]"

echo -e "${GREEN}✅ Rollback complete! Traffic restored to Blue${NC}"

# Verify rollback
ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDNS'].OutputValue" \
  --output text)

echo -e "\n${YELLOW}Verifying rollback:${NC}"
for i in {1..3}; do
  RESPONSE=$(curl -s http://$ALB_DNS | grep -i "BLUE")
  if [ -n "$RESPONSE" ]; then
    echo -e "${GREEN}✓ Request $i served by BLUE${NC}"
  fi
done

echo -e "\n${GREEN}Blue environment is now serving all traffic${NC}"
