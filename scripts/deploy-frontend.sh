#!/bin/bash

set -euo pipefail

# Set environment
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../Client"
BUCKET_NAME=starttech-frontend-bkt
DISTRIBUTION_ID=E1VXPVZBO8NYM0

echo "Building the app..."
cd "$APP_DIR"
npm install
npm run build

echo "Syncing with S3..."
aws s3 sync dist/ s3://${BUCKET_NAME}/ --delete

echo "Invalidating CloudFront cache..."
aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths "/*"

echo "Frontend application deployment completed successfully!"
