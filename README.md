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
