# 基本ブランチ戦略

-   ３環境を作成する
-   GitHub Flow を採用する
-   feature/\*\*に入ったら Azure Container Registry にイメージをプッシュし dev スロットにデプロイ
-   main に pullrequest が出たら staging スロットにデプロイ
-   main に merge されたら staging スロットと main をスワップ

# GitHub Actions のファイル構造

-   .github/workflows/ に GitHub Actions のファイルを配置している

-   build-and-deploy-to-dev.yml  
    feature/\*\* に入ったら Azure Container Registry にイメージをプッシュし dev スロットにデプロイ

-   build-and-deploy-to-staging.yml
    main に pullrequest が出たら Azure Container Registry に Push して staging スロットにデプロイ
-   swap-to-production.yml
    main に merge されたら staging スロットと main をスワップ

# リソースの作成

本レポジトリでは現状リソース準備は自動化しておりません。

Laravel に必要な

-   App Service for Custom Container
-   Azure Container Registry(ACR)
-   Azure Database for MySQL or PostgreSQL
-   Azure Redis Cache

などを作成してください。

# GitHub Actions から Azure 認証情報の取得

Entra ID のアプリケーションを作成することでサービスプリンシパルを作成できます。

そちらのサービスプリンシパルの app_id と ACR の名前を使って下記コマンドを実行してください。

サービスプリンシパルの作成

```
az ad sp create-for-rbac --name "LaravelApp" --role contributor --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} --json-auth
```

この場合 LaravelApp というサービスプリンシパルが作成されます。

そしてそれをあるリソースグループへの Contributer 権限を持つように設定しています。

最小の権限は Azure Container Registry への Push 権限と App Service へ Container Regisry への Pull し Deploy するための 権限です。

下記のような json が返ってきます。
(シークレットはマスクされています。)

```
{
  "clientId": "18a16acf-58f2-4f02-b135-2437b81c6c57",
  "clientSecret": "*****",
  "subscriptionId": "f13a48a2-ca19-404e-900f-a64a7964cf24",
  "tenantId": "2494e1c1-e244-42f7-bc5f-1324bd28a449",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

環境変数の設定

```
export sp_app_id=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx // Service Principal の app_id
export acr_name=xxxxxx // ACR の名前
```

サービスプリンシパルに ACR の pull 権限を付与します。

```
# ACR のリソース ID を取得します

acr_id=$(az acr show --name $acr_name --query id --output tsv)

# Service Principal に ACR への pull 権限を付与します

az role assignment create --assignee $sp_app_id --role acrpull --scope $acr_id

```

こちらのサービスプリンシパルを該当の App Service に割り当てることで、デプロイした後 App Service から ACR にアクセスできるようになります。

# GitHub Actions での環境変数の設定

例を下記に示します。

![GitHub Environment](../img/github/github_environment.png)

本構成では Environment を使って構成しています。

Environent を作成すると各環境に合わせた環境変数を設定できます。

またレビュアーの設定や保護ルールを各環境に合わせて設定可能です。

レビュアーの設定例
![GitHub Environmentのレビュア](../img/github/github_environment_reviewer.png)

使う時には github の yaml 上で下記のように設定します。

各ジョブに environment を設定することができます。

```yaml
name: Swap to Production
on:
    push:
        branches:
            - main
jobs:
    swap-to-production:
        runs-on: ubuntu-latest
        environment: production
```

また Environment ないの環境変数は Environment secrets と Environment Variables の２つに分かれるため、使い分けてください。

Envorinment Variables は秘密性の低い環境変数です。`vars.変数名` という形で使います。

Environment secrets は Environment に紐づいた環境変数です。`secrets.変数名` という形で使います。

設定変数例

| 種類                  | 環境名              | 値                                   |
| --------------------- | ------------------- | ------------------------------------ |
| Environment variables | ACR_NAME            | customcontainer15321                 |
| secrets               | AZURE_CREDENTIALS   | 上記                                 |
| Environment variables | WEBAPP_NAME         | custom-container-laravel             |
| Environment variables | IMAGE_NAME          | laravel-container                    |
| secrets               | AZURE_CLIENT_ID     | 18a16acf-58f2-4f02-b135-2437b81c6c57 |
| secrets               | AZURE_CLIENT_SECRET | CLIENT Secret                        |
| Environment variables | SLOT_NAME           | custom-container-laravel-dev         |
