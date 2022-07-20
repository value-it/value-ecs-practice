#!/bin/sh

# スタック全削除

CURRENT_DIR=$(cd $(dirname $0); pwd)
cd $CURRENT_DIR

# S3バケット削除
echo "delete s3 bucket"
# バージョニングオブジェクト全削除
RES=`aws s3api delete-objects --bucket ecs-practice-logs-dev \
--delete "$(aws s3api list-object-versions --bucket ecs-practice-logs-dev \
--query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"`
# バケット削除
aws s3 rb s3://ecs-practice-logs-dev --force

# ECRリポジトリ削除
echo "delete ecr repository"
aws ecr delete-repository --repository-name ecs-practice/fluentbit-dev-my-firelens --force

# ---

# ECSサービス
echo "delete-stack ecs-practice-template-ecs-service"
aws cloudformation delete-stack --stack-name ecs-practice-template-ecs-service
aws cloudformation wait stack-delete-complete --stack-name ecs-practice-template-ecs-service

# ECSアプリログ用fluentbitイメージECRと送信先S3バケット
echo "delete-stack ecs-practice-template-ecs-logs-s3"
aws cloudformation delete-stack --stack-name ecs-practice-template-ecs-logs-s3
aws cloudformation wait stack-delete-complete --stack-name ecs-practice-template-ecs-logs-s3

# ECSタスク定義
echo "delete-stack ecs-practice-template-ecs-task"
aws cloudformation delete-stack --stack-name ecs-practice-template-ecs-task
aws cloudformation wait stack-delete-complete --stack-name ecs-practice-template-ecs-task

# ECS用Role
echo "delete-stack ecs-practice-template-ecs-role"
aws cloudformation delete-stack --stack-name ecs-practice-template-ecs-role

# ALB
echo "delete-stack ecs-practice-template-alb"
aws cloudformation delete-stack --stack-name ecs-practice-template-alb
aws cloudformation wait stack-delete-complete --stack-name ecs-practice-template-alb

# 基本SecurityGroup
echo "delete-stack ecs-practice-template-securitygroup"
aws cloudformation delete-stack --stack-name ecs-practice-template-securitygroup
aws cloudformation wait stack-delete-complete --stack-name ecs-practice-template-securitygroup

# 基本ネットワーク
echo "delete-stack ecs-practice-template-network"
aws cloudformation delete-stack --stack-name ecs-practice-template-network
aws cloudformation wait stack-delete-complete --stack-name ecs-practice-template-network
