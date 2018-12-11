#!/bin/bash

AWS_ECS_REPO=REPO_URL
AWS_ECS_CLUSTER=CLUSTER
AWS_ECS_SERVICE=SERVICE

# Connect to the repository.
$(aws ecr get-login)

# Build the image for production
docker build --file ./docker/app/Dockerfile --build-arg bundle_install_args="--without development test" -t production .

# Tag the image.
docker tag production:latest ${AWS_ECS_REPO}

# Push the image.
docker push ${AWS_ECS_REPO}

# Tell the service to redeploy.
aws ecs update-service --force-new-deployment --cluster ${AWS_ECS_CLUSTER} --service ${AWS_ECS_SERVICE}
