# syntax=docker/dockerfile:1
# Lacework Agent: adding a build stage
FROM lacework/datacollector:6.3.0-sidecar AS agent-build-image

FROM python:3.8
RUN apt-get update && apt-get install -y \
   curl \
   jq \
   sed \
   && rm -rf /var/lib/apt/lists/*

# Lacework Agent: copying the binary
COPY --from=agent-build-image /var/lib/lacework-backup /var/lib/lacework-backup
ARG LW_SERVER_URL
# Lacework Agent: setting up configurations  
RUN  --mount=type=secret,id=LW_AGENT_ACCESS_TOKEN  \
  mkdir -p /var/lib/lacework/config &&             \
  echo '{"serverurl": "'${LW_SERVER_URL:-https://api.lacework.net}'", "perfmode":"lite", "autoupgrade":"disable", "tokens": {"accesstoken": "'$( cat /run/secrets/LW_AGENT_ACCESS_TOKEN)'"}}' > /var/lib/lacework/config/config.json

# Set the working directory to /app
WORKDIR /app

# copy the requirements file used for dependencies
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
RUN pip install --trusted-host pypi.python.org -r requirements.txt

# Copy the rest of the working directory contents into the container at /app
COPY . .

ENV FLASK_APP=app

# Run app.py when the container launches
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT [ "/docker-entrypoint.sh" ]
