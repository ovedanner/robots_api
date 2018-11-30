#!/bin/bash

# Connect to the repository.
$(aws ecr get-login)

# Build the image for production
sudo docker build --file ./docker/app/Dockerfile --build-arg bundle_install_args="--without development test" -t production .

# Tag the image.
sudo docker tag production:latest 764162651181.dkr.ecr.eu-west-1.amazonaws.com/robots/production

# Push the image.
sudo docker push 764162651181.dkr.ecr.eu-west-1.amazonaws.com/robots/production

# Tell the service to redeploy.
aws ecs update-service --force-new-deployment --cluster robots-cluster --service robots-service
