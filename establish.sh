#!/bin/sh

set -eu
trap 'echo "ERROR: failed at line $LINENO" >&2' ERR

CURRENT_DIR=$(cd $(dirname $0); pwd)
cd $CURRENT_DIR

# 基本ネットワーク構築
aws cloudformation deploy \
--stack-name ecs-practice-template-network \
--template-file ./cloudformation/01-create-network.yaml


# 基本SecurityGroup作成
aws cloudformation deploy \
--stack-name ecs-practice-template-securitygroup \
--template-file ./cloudformation/02-securitygroup.yaml


# ALB作成
aws cloudformation deploy \
--stack-name ecs-practice-template-alb \
--template-file ./cloudformation/03-alb.yaml


# ECS定義作成
# ECS用Role
aws cloudformation deploy \
--stack-name ecs-practice-template-ecs-role \
--template-file ./cloudformation/04.01.ecs.task.role.yaml \
--capabilities CAPABILITY_NAMED_IAM

# ECSアプリログ用fluentbitイメージECRと送信先S3バケット作成
aws cloudformation deploy \
--stack-name ecs-practice-template-ecs-logs-s3 \
--template-file ./cloudformation/04.02.ecs.fluentbit.yaml

# ECSタスク定義
aws cloudformation deploy \
--stack-name ecs-practice-template-ecs-task \
--template-file ./cloudformation/04.03.ecs.task.def.yaml

# flulentbitイメージを作成してECRにPUSHする
ACCOUNT_ID=`aws sts get-caller-identity --query 'Account' --output text`
# 1) builder を用意
if ! docker buildx inspect ecs-plactice-builder >/dev/null 2>&1; then
  docker buildx create --name ecs-plactice-builder --use
else
  docker buildx use ecs-plactice-builder
fi

# 2) ECR login
aws ecr get-login-password --region ap-northeast-1 \
  | docker login --username AWS --password-stdin \
  $ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com

# 3) amd64でビルドして直接push
docker buildx build \
  --platform linux/amd64 \
  -f ./Dockerfile \
  -t $ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/ecs-practice/fluentbit-dev-my-firelens:latest \
  --push .

# ECSサービス
aws cloudformation deploy \
--stack-name ecs-practice-template-ecs-service \
--template-file ./cloudformation/04.04.ecs.service.yaml

# ECSタスク起動
aws ecs update-service \
--cluster ecs-practice-app \
--service ecs-practice-service \
--desired-count 2 > /dev/null 2>&1

