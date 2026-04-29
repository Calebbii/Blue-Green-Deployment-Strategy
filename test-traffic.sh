#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name blue-green-project \
  --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDNS'].OutputValue" \
  --output text)

echo -e "${YELLOW}Testing traffic distribution...${NC}"
echo -e "${YELLOW}ALB URL: http://$ALB_DNS${NC}\n"

declare -A counts
total=20

for i in $(seq 1 $total); do
  response=$(curl -s http://$ALB_DNS | grep -o "BLUE\|GREEN" | head -1)
  counts[$response]=$((${counts[$response]}+1))
  echo -n "."
done

echo -e "\n\n${YELLOW}Results (${total} requests):${NC}"
echo -e "${GREEN}BLUE: ${counts[BLUE]:-0} requests${NC}"
echo -e "${GREEN}GREEN: ${counts[GREEN]:-0} requests${NC}"

if [ ${counts[GREEN]:-0} -eq $total ]; then
  echo -e "\n${GREEN}✅ 100% traffic on GREEN - Deployment successful!${NC}"
elif [ ${counts[BLUE]:-0} -eq $total ]; then
  echo -e "\n${GREEN}✅ 100% traffic on BLUE - Rollback successful!${NC}"
fi
