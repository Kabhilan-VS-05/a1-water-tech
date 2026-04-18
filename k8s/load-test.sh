#!/bin/bash
# Simple script to generate traffic for Prometheus metrics
echo "Generating traffic for A1 Water Tech Backend..."

for i in {1..50}; do
  curl -s http://localhost:3000/health > /dev/null
  curl -s http://localhost:3000/metrics > /dev/null
  # Add other endpoints if available, e.g. /api/products
  # curl -s http://localhost:3000/api/products > /dev/null
  echo -n "."
  sleep 0.2
done

echo ""
echo "Traffic generation complete! Check Prometheus dashboard."
