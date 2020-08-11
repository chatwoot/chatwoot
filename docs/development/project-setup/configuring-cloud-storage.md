---
path: "/docs/configuring-cloud-storage"
title: "Configuring Cloud Storage"
---

### Using Amazon S3

You can get started with [Creating an S3 bucket](https://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html) and [Create an IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html) to configure the following details.

Configure the following env variables. 

```bash
ACTIVE_STORAGE_SERVICE='amazon'
S3_BUCKET_NAME=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=
```


### Using Google GCS

Configure the following env variables. 

```bash
ACTIVE_STORAGE_SERVICE='google'
GCS_PROJECT=
GCS_CREDENTIALS=
GCS_BUCKET=
```

the value of the `GCS_CREDENTIALS` should be a json formatted string containing the following keys

```bash
{
  "type": "service_account",
  "project_id" : "",
  "private_key_id" : "",
  "private_key" : "",
  "client_email" : "",
  "client_id" : "",
  "auth_uri" : "",
  "token_uri" : "",
  "auth_provider_x509_cert_url" : "",
  "client_x509_cert_url" : ""
}
``` 

### Using Microsoft Azure

Configure the following env variables. 

```bash
ACTIVE_STORAGE_SERVICE='microsoft'
AZURE_STORAGE_ACCOUNT_NAME=
AZURE_STORAGE_ACCESS_KEY=
AZURE_STORAGE_CONTAINER=
```


### Using Amazon S3 Compatible Service

Use s3 compatible service such as [DigitalOcean Spaces](https://www.digitalocean.com/docs/spaces/resources/s3-sdk-examples/#configure-a-client), Minio.

Configure the following env variables. 

```bash
ACTIVE_STORAGE_SERVICE='s3_compatible'
STORAGE_BUCKET_NAME=
STORAGE_ACCESS_KEY_ID=
STORAGE_SECRET_ACCESS_KEY=
STORAGE_REGION=nyc3
STORAGE_ENDPOINT=https://nyc3.digitaloceanspaces.com
```
