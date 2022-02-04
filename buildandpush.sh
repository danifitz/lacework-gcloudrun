#!/bin/sh

# GCP info
export GCP_REGION="YOUR_GCP_REGION"
export GCP_PROJECT="YOUR_PROJECT_NAME"
export GCP_ARTIFACT_REPO="YOUR_ARTIFACT_REPO"
export GCP_ARTIFACT_REGISTRY_NAME="${GCP_REGION}-docker.pkg.dev/"

# Image info
export IMAGE_NAME="YOUR_IMAGE"
export IMAGE_TAG="YOUR_TAG"

# Store the Lacework Agent access token in a file (See Requirements to obtain one)
echo "YOUR_AGENT_ACCESS_TOKEN" > token.key

# Build and tag the image
# --build-arg flag is optional, defaults to https://api.lacework.net. See https://docs.lacework.com/agent-server-url
DOCKER_BUILDKIT=1 docker build \
  --secret id=LW_AGENT_ACCESS_TOKEN,src=token.key \
  --build-arg LW_SERVER_URL=https://api.lacework.net \
  --force-rm=true \
  --tag "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/${GCP_ARTIFACT_REPO}/${IMAGE_NAME}:${IMAGE_TAG}" .

# Login to Artifact Registry and push the image
gcloud auth configure-docker ${GCP_REGION}-docker.pkg.dev
docker push "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/${GCP_ARTIFACT_REPO}/${IMAGE_NAME}:${IMAGE_TAG}"