# panw_chronicle_gcs_to_gcs
Creates a Cloud Run job and a trigger which replicate data from Cortex [XDR Event Forwarding](https://docs-cortex.paloaltonetworks.com/r/Cortex-XDR/Cortex-XDR-Pro-Administrator-Guide/Manage-Event-Forwarding) Bucket to Customer's GCS bucket

## Output
1. Cloud Run Job
2. Trigger to execute the job

## Installation/ Deployment Instructions
> [!NOTE]
> Please rech out to your Palo Alto Representative if you need more detailed instructions.

1. Enable following APIs in your project.
   - Cloud Run
   - Artifact Registry
   - Secret Manager
   - Cloud Storage
2. Provide the default compute engine service account the role to access secrtes viz. `Secret Manager Secret Accessor`
3. Setup Cortex [XDR Event forwarding](https://docs-cortex.paloaltonetworks.com/r/Cortex-XDR/Cortex-XDR-Pro-Administrator-Guide/Manage-Event-Forwarding). Note the GCS bucket name and download the service account json from the XDR console
4. Get the service account and store it as a secret in secret manager
5. Create a Destination bucket in your project
6. Clone this repo into Google Cloud shell with `git clone https://github.com/nikhilpurwant/panw_chronicle_gcs_to_gcs.git`
7. Navigate the the cloned directory with `cd panw_chronicle_gcs_to_gcs`
8. Update the environment variables in `env.properties`
9. Provide execute permissions to `deploy.sh` using `chmod 744 deploy.sh`
10. Run `./deploy.sh`
11. Verify whether the cloud run job and the trigger is created.
12. Check Cloud Run Job history by navigating Cloud Run - Jobs - (select) cloud-run-job-cortex-data-sync - History. You can also check the logs by selecting the logs tab there.
