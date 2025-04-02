## ディレクトリ構成
```
├─ environments
│  ├─ prd
│  ├─ stg
│  └─ dev
│     ├─ main.tf
│     ├─ local.tf
│     ├─ variable.tf
│     └─ (terraform.tfvars)
│
└─ modules(各Moduleにmain.tf,variable.tf,output.tfが存在)
      ├─ cloudtrail（Trail証跡と格納先S3バケット/CloudWatch Logs）
      ├─ initializer（tfstate用S3バケット作成）
      └─ monitoring（Metrics FilterやAlarm、EventBridgeなど監視関連のリソース）
```
