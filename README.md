# Install the Lacework agent in a Google Cloud Run environment

## Motivation
According to Google: *Cloud Run is a managed compute platform that enables you to run containers that are invocable via requests or events. Cloud Run is serverless: it abstracts away all infrastructure management, so you can focus on what matters most.*

This means Google will handle managing and securing of the infrastructure including security groups, patch management, OS configuring and hardening. However there is still a considerable attack surface that needs to be considered for a public facing application and you also lose a lot of the visibility you might have when the underlying infrastructure is accessible by you.

This guide demonstrates how to gain visibility into the execution of containers running in Google Cloud Run using the Lacework agent.

## Demo

If you want to spin up a quick demo, you can use this project
* [Install the gcloud CLI](https://cloud.google.com/sdk/docs/install)
* Open the GCP Console, create a new project
* Create a new Artifact registry
* Create a new repo in the artifact registry
* Open `buildandpush.sh` and replace the values for region, project, artifact repo, image name and tag.
* Login with the gcloud CLI `gcloud auth login`
* Make the script executable `chmod +x buildandpush.sh` and run the script `./buildandpush`

## Instructions

Installation requires three steps:
* Add the Agent to your existing `Dockerfile`
* Build and push image
* Deploy and run on Google Cloud Run

### Step 1: Add the Agent to your existing `Dockerfile`

This step consists of a (a) adding a build stage, (b) copying the Lacework agent binary, and (c) setting up configurations.

The following is a full example of a very simple `Dockerfile` along with its entrypoint script. This example adds three lines and comments indicating the Lacework Agent additions.

```
# syntax=docker/dockerfile:1
# Lacework Agent: adding a build stage
FROM lacework/datacollector:latest-sidecar AS agent-build-image

FROM ubuntu:latest
RUN apt-get update && apt-get install -y \
  ca-certificates \
  curl \
  jq \
  sed \
  && rm -rf /var/lib/apt/lists/*

# Lacework Agent: copying the binary
COPY --from=agent-build-image /var/lib/lacework-backup /var/lib/lacework-backup

# Lacework Agent: setting up configurations  
RUN  --mount=type=secret,id=LW_AGENT_ACCESS_TOKEN  \
  mkdir -p /var/lib/lacework/config &&             \
  echo '{"serverurl": "'${LW_SERVER_URL:-https://api.lacework.net}'", "perfmode":"lite", "autoupgrade":"disable", "tokens": {"accesstoken": "'$( cat /run/secrets/LW_AGENT_ACCESS_TOKEN)'"}}' > /var/lib/lacework/config/config.json

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT [ "/docker-entrypoint.sh" ]
```

And the /docker-entrypoint.sh would include the following:

```
#!/bin/sh

# Lacework Agent: configure and start the data collector
/var/lib/lacework/datacollector &

/path/to/your/existing/script
```

The `RUN` command uses BuildKit to securely pass the Lacework Agent access token as LW_AGENT_ACCESS_TOKEN. This is recommended, but not a requirement.

Note that it is also possible to install the Lacework Agent by fetching and installing the binaries from our official GitHub repository. Optionally, some customers choose to upload the lacework/datacollector:latest images into their own image registry.

### Step 2: Build and push image

Now that our image has been defined locally, it can be built and pushed to a container registry such as Google Artifact Registry.

Consider the following example script:

```
#!/bin/sh

# GCP info
export GCP_REGION="europe-west2"
export GCP_PROJECT="danf-cloud-run-test"
export GCP_ARTIFACT_REPO="cloudrun"
export GCP_ARTIFACT_REGISTRY_NAME="${GCP_REGION}-docker.pkg.dev/"

# Image info
export IMAGE_NAME="gcloudruntest"
export IMAGE_TAG="latest"

# Store the Lacework Agent access token in a file (See Requirements to obtain one)
echo "YOUR_AGENT_ACCESS_TOKEN_HERE" > token.key

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
```

### Step 3: Deploy and run on Google Cloud Run

#### Option 1: Deploy using gcloud CLI
*Note:Specifying the execution environment when deploying using the CLI is currently a beta feature.*

Run the command below, replacing the details for your project, registry name, image name and tag.

```
gcloud beta run deploy myTestService --image ${YOUR_REGION}-docker.pkg.dev/${YOUR_GCP_PROJECT}/${YOUR_REGISTRY_NAME}/${IMAGE_NAME}:${IMAGE_TAG} \
    --min-instances 0 --max-instances 5 --execution-environment gen2
```

#### Option 2: Deploy using the GCP Console.

* Login to the GCP console
* Go to the Cloud Run service
* Create a new service
* Fill in the usual details like container image URL, service name, region etc.
* In *CPU allocation and pricing* section choose *CPU is always allocated*
* Expand the *Container, Variables & Secrets, Connections, Security* section and in the *Container* tab under *Execution environment* choose *Second generation*
* Fill in any other necessary details to deploy your application then click the create button

## Limitations

* This only works with second generation environments: `metadata.annotations.run.googleapis.com/execution-environment: gen2`
* The lacework agent must be included in the application Docker image
* The Lacework agent requires the CPU to always be allocated in order to work.

# To Do's

* Test on Cloud Run for GKE Anthos
* Test with CPU is only allocated during request processing
