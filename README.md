# laravel_ecs_rds_template

## 概要
Laravelを動かすためのECSとAurora（PostgreSQL）を作成するテンプレートです。
2023年ごろ作成です。最新だと動かないかもです。
実行した時のTerraformバージョンは、v1.7.4です。

##　イメージ

![image](/image/ecs_rds_sample001.jpg)

## 前提
- tfstate格納用のS3バケットは作成ずみ
- ECSに使うためのnginxとlaravelのコンテナイメージはECRにプッシュ済み
- ACMにドメインのSSL証明書登録済み

## ディレクトリ構成

- modules：AWSリソースを作成する処理を書いているファイルを格納しています。
  - bastion：踏み台EC2を作成。
  - ecs：ECSを作成。
  - load-balancer：ALBを作成。
  - rds：Aurora PostgreSQL互換を作成。
  - security-group：利用するセキュリティグループを作成。
  - ssm：データベース接続情報をパラメータストアに作成。
  - vpc：VPC関連を作成。
- staging：main.tf内でmodulesにある処理を呼んでいます。環境ごとにこのフォルダを作成するイメージです。

## 引数の説明
実行時にterraform.tfvarsファイルの引数を受け取って処理します。

- app_name：アプリケーション名です。リソース名やtagに使っています。
- php_image：ECRに登録しているPHPコンテナのイメージを指定します。
- web_image：ECRに登録しているnginxコンテナのイメージを指定します。
- db_database：初期データベースのデータベース名を指定します。
- db_username：アプリケーションの使うユーザー名を指定します。
- db_password：アプリケーションの使うユーザーのパスワードを指定します。
- db_username_super_user：スーパーユーザーのユーザー名です。
- db_password_super_user：スーパーユーザーのパスワードです。
- log_channel：Laravelの環境変数に影響する値です。
- alb_domain：SSL証明書を取得しているドメインです。

## その他
- Route53でALBへの向け先設定を手動でする必要があるかもです。
