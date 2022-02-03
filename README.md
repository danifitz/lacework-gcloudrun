# lacework-gcloudrun

1. Build the image - `docker build -t gcloudruntest:latest .`
2. Create a GCP Artifact Registry
3. Tag your image - `docker tag gcloudruntest:latest <your_artifact_registry>/gcloudruntest:latest`
4. Push your image - `docker push <your_artifact_registry>/gcloudruntest:latest`
5. Right click on image in artifact registry and select deploy to cloud run
6. Run the image - currently tested with always allocated CPU, second generation environment, make sure to expose port 5000
7. Make some requests to the app and wait for the host to appear in Lacework.