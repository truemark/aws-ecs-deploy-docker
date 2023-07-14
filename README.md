# TrueMark AWS ECS Deploy

This project aims to simplify the deployment of docker images to an existing ECS service. For automation to
create and destroy infrastructure for an AWS ECS service, see the aws-ecs-infra-docker repository.

## Execute from CLI

```bash
docker run -it --rm \
    -e AWS_ACCESS_KEY_ID="<key>" \
    -e AWS_SECRET_ACCESS_KEY="<secret>" \
    -e AWS_DEFAULT_REGION="<region>" \
    truemark/aws-ecs-deploy:latest \
    -c "<cluster>" \
    -s "<service>" \
    -i "<image>"
```

## Execute as BitBucket Pipeline Pipe

```yaml
pipelines:
  branches:
    master:
      - step:
          name: Deploy
          script:
            - pipe: docker://truemark/aws-ecs-deploy:latest
              variables:
                AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
                AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
                AWS_PROFILE: $AWS_DEFAULT_REGION
                CLUSTER: $CLUSTER
                SERVICE: $SERVICE
                IMAGE: acme/someimage:$BITBUCKET_BUILD_NUMBER-release
``` 

# What are all the environment variables supported by this image?

| Environment Variable          | Description                                                                         |
|:------------------------------|:------------------------------------------------------------------------------------|
| AWS_ACCESS_KEY_ID             | Optional access key if using default AWS authentication.                            |
| AWS_ASSUME_ROLE_ARN           | Optional role to assume.                                                            |
| AWS_OIDC_ROLE_ARN             | Alternative variable to AWS_ROLE_ARN.                                               |
| AWS_ROLE_SESSION_NAME         | Optional session name used in audit logs used when assuming a role.                 |
| AWS_SECRET_ACCESS_KEY         | Optional secret access key if using default AWS authentication.                     |
| AWS_SESSION_TOKEN             | Optional session token used with temporary credentials.                             |
| AWS_WEB_IDENTITY_TOKEN        | Optional OIDC token if using AWS OIDC authentication.                               |
| AWS_WEB_IDENTITY_TOKEN_FILE   | Optional token file if using AWS OIDC authentication.                               |
| CLUSTER                       | The name of the ECS cluster to deploy to.                                           |
| SERVICE                       | The name of the ECS service to deploy to.                                           |
| IMAGE                         | The image to deploy.                                                                |
| PRUNE_REPOSITORY_CREDENTIALS  | Optional flag to prune repository credentials from the task definition on deploy.   |
