#!/bin/sh

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

# ECSタスク定義
aws cloudformation deploy \
--stack-name ecs-practice-template-ecs-task \
--template-file ./cloudformation/04.02.ecs.task.def.yaml

# ECSアプリログ用fluentbitイメージECRと送信先S3バケット作成
aws cloudformation deploy \
--stack-name ecs-practice-template-ecs-logs-s3 \
--template-file ./cloudformation/04.03.ecs.fluentbit.yaml

# flulentbitイメージを作成してECRにPUSHする
ACCOUNT_ID=`aws sts get-caller-identity --query 'Account' --output text`
docker build -f ./Dockerfile -t fluentbit-dev-my-firelens .
docker tag fluentbit-dev-my-firelens:latest $ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/ecs-practice/fluentbit-dev-my-firelens:latest
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com
docker push $ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/ecs-practice/fluentbit-dev-my-firelens:latest

# ECSサービス
aws cloudformation deploy \
--stack-name ecs-practice-template-ecs-service \
--template-file ./cloudformation/04.04.ecs.service.yaml

