# CloudFormationでECS（nginx＋fluentbit）環境を構築する雛形

fluentbitはS3にのみログ出力する設定


## 事前準備

### 作業用端末にAWS CLI v2をインストール
https://aws.amazon.com/jp/cli/

### AWS CLI の名前付きプロファイルを作成
各種リソースを操作可能なIAMユーザーのプロファイルを作成する  
https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/cli-configure-profiles.html

---

## 手順

### 0. 環境変数設定
事前に作成したAWSプロファイルを指定（プロファイル名は適宜修正）
```shell
export AWS_PROFILE=hogehoge
```

### 1. 基本ネットワーク構築
```shell
aws cloudformation deploy \
--stack-name ecs-practice-template-network \
--template-file ./cloudformation/01-create-network.yaml
```

### 2. 基本SecurityGroup作成
```shell
aws cloudformation deploy \
--stack-name ecs-practice-template-securitygroup \
--template-file ./cloudformation/02-securitygroup.yaml 
```

### 3. ALB作成
```shell
aws cloudformation deploy \
--stack-name ecs-practice-template-alb \
--template-file ./cloudformation/03-alb.yaml
```

### 4. ECS定義作成
```shell
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

# flulentbitイメージ作成
./fluentbit/make-fluentbit-image.sh

# ECSサービス
aws cloudformation deploy \
--stack-name ecs-practice-template-ecs-service \
--template-file ./cloudformation/04.04.ecs.service.yaml \
--parameter-overrides MinCapacity=2 MaxCapacity=10
```

## URL
以下でALBのDNS名を確認
> https://ap-northeast-1.console.aws.amazon.com/ec2/v2/home?region=ap-northeast-1#LoadBalancers:sort=loadBalancerName

http://{{上記で確認したDNS名}}/  
でアクセス