#!/bin/bash

set -euo pipefail

# Set environment
ALB_DNS_NAME="starttech-alb-1666232340.us-east-1.elb.amazonaws.com"
CDN_URL="d3g5onb8i0gty8.cloudfront.net"

echo "Performing health check on the backend application..."
HTTP_STATUS_ALB=$(curl -o /dev/null -s -w "%{http_code}\n" "http://$ALB_DNS_NAME/health")

if [[ "$HTTP_STATUS_ALB" -eq 200 ]]; then
    echo "ALB Health Check Passed: HTTP $HTTP_STATUS_ALB"
else
    echo "ALB Health Check Failed: HTTP $HTTP_STATUS_ALB"
fi

echo "Performing health check on the frontend application..."
HTTP_STATUS_CDN=$(curl -o /dev/null -s -w "%{http_code}\n" "https://$CDN_URL")
if [[ "$HTTP_STATUS_CDN" -eq 200 ]]; then
    echo "CDN Health Check Passed: HTTP $HTTP_STATUS_CDN"
else
    echo "CDN Health Check Failed: HTTP $HTTP_STATUS_CDN"
fi
