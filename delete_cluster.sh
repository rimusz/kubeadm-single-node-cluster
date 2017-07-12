#!/bin/bash

# Get settings from the file
source settings

# Cleanup
gcloud compute instances delete ${SERVER}

gcloud compute firewall-rules delete default-allow-${SERVER}

rm ${SERVER}.conf
