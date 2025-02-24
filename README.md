## システム構成図
<img width="1025" alt="image" src="https://github.com/user-attachments/assets/b01f5978-4533-47a2-b61d-75b9403f83bb" />
<br><br>

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
