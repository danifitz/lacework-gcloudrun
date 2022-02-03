# syntax=docker/dockerfile:1
### LW Agent (1) adding a build stage ######################
FROM lacework/datacollector:latest AS agent-build-image
############################################################

FROM python:3.8
RUN apt-get update && apt-get install -y \
   curl \
   jq \
   sed \
   && rm -rf /var/lib/apt/lists/*

### LW Agent (2) copying the binary  #######################
COPY --from=agent-build-image  /var/lib/backup/*/datacollector /var/lib/lacework/datacollector
### LW Agent (3) setting up configurations
RUN   LW_AGENT_ACCESS_TOKEN="81dcb2bf8db325df979c94c6e32190622ba5a774d8f470b198a59af1" && \
      mkdir -p /var/log/lacework                 && \
      mkdir -p /var/lib/lacework/config          && \
      echo '{"perfmode":"lite", "autoupgrade":"disable", "tokens": {"accesstoken": "'${LW_AGENT_ACCESS_TOKEN}'"}}' > /var/lib/lacework/config/config.json
############################################################

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