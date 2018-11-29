#!/usr/bin/env bash

# Connect to the repository.
$(aws ecr get-login)

# Build the image for production
docker build --file ./docker/app/Dockerfile --build-arg bundle_install_args="--without development test" -t production .

# Tag the image.
docker tag production:latest 764162651181.dkr.ecr.eu-west-1.amazonaws.com/robots/production

# Push the image.
docker push 764162651181.dkr.ecr.eu-west-1.amazonaws.com/robots/production
