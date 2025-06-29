#!/bin/bash

echo "Building Docker image..."
if docker build -t iu-apache:latest .; then
  echo "Build succeeded. Loading image into Minikube..."
  minikube image load iu-apache:latest
else
  echo "Build failed. Skipping image load." >&2
  exit 1
fi
