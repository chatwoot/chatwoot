 # Chatwoot

[Chatwoot](https://chatwoot.app.br) is a customer engagement suite. an open-source alternative to Intercom, Zendesk, Salesforce Service Cloud, etc. 🔥💬

## TL;DR

```
helm repo add chatwoot https://chatwoot-br.github.io/charts
helm install chatwoot chatwoot/chatwoot
```

## Prerequisites

- Kubernetes 1.16+
- Helm 3.1.0+
- PV provisioner support in the underlying infrastructure


## Installing the chart

To install the chart with the release name `chatwoot`:

```console
$ helm install chatwoot chatwoot/chatwoot
```

The command deploys Chatwoot on the Kubernetes cluster in the default configuration. The [parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the chart

To uninstall/delete the `chatwoot` deployment:

```console
helm delete chatwoot
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

> **Note**: Persistent volumes are not deleted automatically. They need to be removed manually.


## Parameters


### Chatwoot Image parameters

| Name                | Description                                          | Value                 |
| ------------------- | ---------------------------------------------------- | --------------------- |
| `image.repository`  | Chatwoot image repository                           | `chatwoot/chatwoot`    |
| `image.tag`         | Chatwoot image tag (immutable tags are recommended) | `v4.1.0`              |
| `image.pullPolicy`  | Chatwoot image pull policy                          | `IfNotPresent`         |


### Chatwoot Environment Variables

| Name                                 | Type                                                                | Default Value                                              |
| ------------------------------------ | ------------------------------------------------------------------- | ---------------------------------------------------------- |
| `env.ACTIVE_STORAGE_SERVICE`         | Storage service. `local` for disk. `amazon` for s3.                 | `"local"`                                                  |
| `env.ASSET_CDN_HOST`                 | Set if CDN is used for asset delivery.                              | `""`                                                       |
| `env.INSTALLATION_ENV`               | Sets chatwoot installation method.                                  | `"helm"`                                                   |
| `env.ENABLE_ACCOUNT_SIGNUP`          | `true` : default option, allows sign ups, `false` : disables all the end points related to sign ups, `api_only`: disables the UI for signup but you can create sign ups via the account apis.  | `"false"`                                                  |
| `env.FORCE_SSL`                      | Force all access to the app over SSL, default is set to false.                  | `"false"`                                                  |
| `env.FRONTEND_URL`                   | Replace with the URL you are planning to use for your app.                      | `"http://0.0.0.0:3000/"`                                   |
| `env.IOS_APP_ID`                     | Change this variable only if you are using a custom build for mobile app.       | `"6C953F3RX2.com.chatwoot.app"`                            |
| `env.ANDROID_BUNDLE_ID`              | Change this variable only if you are using a custom build for mobile app.       | `"com.chatwoot.app"`                                       |
| `env.ANDROID_SHA256_CERT_FINGERPRINT`| Change this variable only if you are using a custom build for mobile app.       | `"AC:73:8E:DE:EB:5............"`                           |
| `env.MAILER_SENDER_EMAIL`            | The email from which all outgoing emails are sent.                              | `""`                                                       |
| `env.RAILS_ENV`                      | Sets rails environment.                                                         | `"production"`                                             |
| `env.RAILS_MAX_THREADS`              | Number of threads each worker will use.                                         | `"5"`                                                      |
| `env.SECRET_KEY_BASE`                | Used to verify the integrity of signed cookies. Ensure a secure value is set.   | `replace_with_your_super_duper_secret_key_base`            |
| `env.SENTRY_DSN`                     | Sentry data source name.                                                        | `""`                                                       |
| `env.SMTP_ADDRESS`                   | Set your smtp address.                                                          |`""`                                                        |
| `env.SMTP_AUTHENTICATION`            | Allowed values: `plain`,`login`,`cram_md5`                                      | `"plain"`                                                  |
| `env.SMTP_ENABLE_STARTTLS_AUTO`      | Defaults to true.                                                               | `"true"`                                                   |
| `env.SMTP_OPENSSL_VERIFY_MODE`       | Can be: `none`, `peer`, `client_once`, `fail_if_no_peer_cert`                   | `"none"`                                                   |
| `env.SMTP_PASSWORD`                  | SMTP password                                                                   | `""`                                                       |
| `env.SMTP_PORT`                      | SMTP port                                                                       | `"587"`                                                    |
| `env.SMTP_USERNAME`                  | SMTP username                                                                   | `""`                                                       |
| `env.USE_INBOX_AVATAR_FOR_BOT`       | Bot customizations                                                              | `"true"`                                                   |

### Email setup for conversation continuity (Incoming emails)

| Name                                | Type                                                                                                                                                    | Default Value |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- |
| `env.MAILER_INBOUND_EMAIL_DOMAIN`   | This is the domain set for the reply emails when conversation continuity is enabled.                                                                    | `""`          |
| `env.RAILS_INBOUND_EMAIL_SERVICE`   | Set this to appropriate ingress channel with regards to incoming emails. Possible values are `relay`, `mailgun`, `mandrill`, `postmark` and `sendgrid`. | `""`          |
| `env.RAILS_INBOUND_EMAIL_PASSWORD`  | Password for the email service.                                                                                                                         | `""`          |
| `env.MAILGUN_INGRESS_SIGNING_KEY`   | Set if using mailgun for incoming conversations.                                                                                                        | `""`          |
| `env.MANDRILL_INGRESS_API_KEY`      | Set if using mandrill for incoming conversations.                                                                                                       | `""`          |

### Postgres variables

| Name                                | Type                                                                          | Default Value                                    |
| ----------------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------ |
| `postgresql.enabled`                | Set to `false` if using external postgres and modify the below variables.     | `true`                                           |
| `postgresql.auth.database`| Chatwoot database name                                                        | `chatwoot_production`                            |
| `postgresql.postgresqlHost`         | Postgres host. Edit if using external postgres.                               | `""`                                             |
| `postgresql.auth.postgresPassword`| Postgres password. Edit if using external postgres.                           | `postgres`                                       |
| `postgresql.postgresqlPort`         | Postgres port                                                                 | `5432`                                           |
| `postgresql.auth.username`| Postgres username.                                                            | `postgres`                                       |

### Redis variables

| Name                                | Type                                                                       | Default Value                                       |
| ----------------------------------- | -------------------------------------------------------------------------  | --------------------------------------------------- |
| `redis.auth.password`               | Password used for internal redis cluster                                   | `redis`                                             |
| `redis.enabled`                     | Set to `false` if using external redis and modify the below variables.     | `true`                                              |
| `redis.host`                        | Redis host name                                                            | `""`                                                |
| `redis.port`                        | Redis port                                                                 | `""`                                                |
| `redis.password`                    | Redis password                                                             | `""`                                                |
| `env.REDIS_TLS`                     | Set to `true` if TLS(`rediss://`) is required                              | `false`                                             |
| `env.REDIS_SENTINELS`               | Redis Sentinel can be used by passing list of sentinel host and ports.     | `""`                                                |
| `env.REDIS_SENTINEL_MASTER_NAME`    | Redis sentinel master name is required when using sentinel.                | `""`                                                |


### Logging variables

| Name                                | Type                                                                | Default Value                                              |
| ----------------------------------- | ------------------------------------------------------------------- | ---------------------------------------------------------- |
| `env.RAILS_LOG_TO_STDOUT`           | string                                                              | `"true"`                                                   |
| `env.LOG_LEVEL`                     | string                                                              | `"info"`                                                   |
| `env.LOG_SIZE`                      | string                                                              | `"500"`                                                    |

### Third party credentials

| Name                                | Type                                                                 | Default Value                                              |
| ----------------------------------- | -------------------------------------------------------------------- | ---------------------------------------------------------- |
| `env.S3_BUCKET_NAME`                | S3 bucket name                                                       | `""`                                                       |
| `env.AWS_ACCESS_KEY_ID`             | Amazon access key ID                                                 | `""`                                                       |
| `env.AWS_REGION`                    | Amazon region                                                        | `""`                                                       |
| `env.AWS_SECRET_ACCESS_KEY`         | Amazon secret key ID                                                 | `""`                                                       |
| `env.FB_APP_ID`                     | For facebook channel https://www.chatwoot.app.br/docs/facebook-setup    | `""`                                                       |
| `env.FB_APP_SECRET`                 | For facebook channel                                                 | `""`                                                       |
| `env.FB_VERIFY_TOKEN`               | For facebook channel                                                 | `""`                                                       |
| `env.SLACK_CLIENT_ID`               | For slack integration                                                | `""`                                                       |
| `env.SLACK_CLIENT_SECRET`           | For slack integration                                                | `""`                                                       |
| `env.TWITTER_APP_ID`                | For twitter channel                                                  | `""`                                                       |
| `env.TWITTER_CONSUMER_KEY`          | For twitter channel                                                  | `""`                                                       |
| `env.TWITTER_CONSUMER_SECRET`       | For twitter channel                                                  | `""`                                                       |
| `env.TWITTER_ENVIRONMENT`           | For twitter channel                                                  | `""`                                                       |

### Autoscaling

| Name                                | Type                                                                 | Default Value                                              |
| ----------------------------------- | -------------------------------------------------------------------- | ---------------------------------------------------------- |
| `web.hpa.enabled`                   | Horizontal Pod Autoscaling for Chatwoot web                          | `false`                                                    |
| `web.hpa.cputhreshold`              | CPU threshold for Chatwoot web                                       | `80`                                                       |
| `web.hpa.minpods`                   | Minimum number of pods for Chatwoot web                              | `1`                                                        |
| `web.hpa.maxpods`                   | Maximum number of pods for Chatwoot web                              | `10`                                                       |
| `web.replicaCount`                  | No of web pods if hpa is not enabled                                 | `1`                                                        |
| `worker.hpa.enabled`                | Horizontal Pod Autoscaling for Chatwoot worker                       | `false`                                                    |
| `worker.hpa.cputhreshold`           | CPU threshold for Chatwoot worker                                    | `80`                                                       |
| `worker.hpa.minpods`                | Minimum number of pods for Chatwoot worker                           | `2`                                                        |
| `worker.hpa.maxpods`                | Maximum number of pods for Chatwoot worker                           | `10`                                                       |
| `worker.replicaCount`               | No of worker pods if hpa is not enabled                              | `1`                                                        |
| `autoscaling.apiVersion`            | Autoscaling API version                                              | `autoscaling/v2`                                           |

### Other Parameters

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| existingEnvSecret | string | "" | Allows the use of an existing secret to set env variables |
| fullnameOverride | string | `""` |  |
| hooks.affinity | object | `{}` |  |
| hooks.migrate.env | list | `[]` |  |
| hooks.migrate.hookAnnotation | string | `"post-install,post-upgrade"` |  |
| hooks.migrate.resources.limits.memory | string | `"1000Mi"` |  |
| hooks.migrate.resources.requests.memory | string | `"1000Mi"` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `""` |  |
| ingress.hosts[0].paths[0].backend.service.name | string | `"chatwoot"` |  |
| ingress.hosts[0].paths[0].backend.service.port.number | int | `3000` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| ingress.tls | list | `[]` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| redis.master.persistence.enabled | bool | `true` |  |
| redis.nameOverride | string | `"chatwoot-redis"` |  |
| resources | object | `{}` |  |
| securityContext | object | `{}` |  |
| service.port | int | `80` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| services.annotations | object | `{}` |  |
| services.internalPort | int | `3000` |  |
| services.name | string | `"chatwoot"` |  |
| services.targetPort | int | `3000` |  |
| services.type | string | `"LoadBalancer"` |  |
| tolerations | list | `[]` |  |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
$ helm install my-release \
  --set env.FRONTEND_URL="chat.yourdomain.com"\
    chatwoot/chatwoot
```

The above command sets the Chatwoot server frontend URL to `chat.yourdoamain.com`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
$ helm install my-release -f values.yaml chatwoot/chatwoot
```

> **Tip** You can use the default `values.yaml` file.

## Postgres

PostgreSQL is installed along with the chart if you choose the default setup. To use an external Postgres DB, please set `postgresql.enabled` to `false` and set the variables under the Postgres section above.

## Redis

Redis is installed along with the chart if you choose the default setup. To use an external Redis DB, please set `redis.enabled` to `false` and set the variables under the Redis section above.

# Autoscaling

To enable horizontal pod autoscaling, set `web.hpa.enabled` and `worker.hpa.enabled` to `true`. Also make sure to uncomment the values under, `resources.limits` and `resources.requests`. This assumes your k8s cluster is already having a metrics-server. If not, deploy metrics-server with the following command.

```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Upgrading

Do `helm repo update` and check the version of charts that is going to be installed. Helm charts follows semantic versioning and so if the MAJOR version is different from your installed version, there might be breaking changes. Please refer to the changelog before upgrading.

```
# update helm repositories
helm repo update
# list your current installed version
helm list
# show the latest version of charts that is going to be installed
helm search repo chatwoot
```

```
#if it is major version update, refer to the changelog before proceeding
helm upgrade chatwoot chatwoot/chatwoot -f <your-custom-values>.yaml
```
### To 1.x.x

Make sure you are on Chatwoot helm charts version `0.9.0` before upgrading to version `1.x.x`. If not, please upgrade to `0.9.0` before proceeding.

```
helm repo update
helm upgrade chatwoot chatwoot/chatwoot --version="0.9.0"  -f <your-custom-values>  --debug
```

This release changes the postgres and redis versions. This is a breaking change and requires manual data migration if you are not using external postgres and redis.

> **Note**: This release also changes the postgres and redis auth paramaters values under `.Values.redis` and `.Values.postgres`.
Make the necessary changes to your custom `values.yaml` file if any.
`Values.postgresqlDatabase` --> `Values.auth.postgresqlDatabase`
`Values.postgresqlUsername` --> `Values.auth.postgresqlUsername`
`Values.postgresqlPassword` --> `Values.auth.postgresqlPassword`

> **Note:** Append the kubectl commands with `-n chatwoot`, if you have deployed it under the chatwoot namespace.

Before updating,

1. Set the replica count to 0 for both Chatwoot web(`.Values.web.replicaCount`) and worker(`.Values.worker.replicaCount`) replica sets. Applying this change
will bring down the pods count to 0. This is to ensure the database will not be having any activity and is in a state to backup.
```
helm upgrade chatwoot chatwoot/chatwoot --version="0.9.0" --namespace ug3 -f values.ci.yaml --create-namespace --debug
```

2. Log into the postgres pod and take a backup of your database.
 ```
 kubectl exec -it chatwoot-chatwoot-postgresql-0 -- /bin/sh
 env | grep -i postgres_password #get postgres password to use in next step
 pg_dump -Fc --no-acl --no-owner  -U postgres chatwoot_production > /tmp/cw.dump
 exit
 ```

 3. Copy the backup to your local machine.
 ```
 kubectl cp pod/chatwoot-chatwoot-postgresql-0:/tmp/cw.dump ./cw.dump
 ```

 4. Delete the deployments.
 ```
 helm delete chatwoot
 kubectl get pvc
 # this will delete the database volumes
 # make sure you have backed up before proceeding
 kubectl delete pvc <data-postgres->
 kubectl delete pvc <redis>
 ```

5. Update and install new version of charts.
```
helm repo update
#reset web.replicaCount and worker.replicaCount to your previous values
helm install chatwoot chatwoot/chatwoot -f <your-values.yaml> #-n chatwoot
```

6. Copy the local db backup into postgres pod.
```
kubectl cp cw.dump chatwoot-chatwoot-postgresql-0:/tmp/cw.dump
```

7. Exec into the postgres pod and drop the database.
```
 kubectl exec -it chatwoot-chatwoot-postgresql-0 -- /bin/sh
 psql -u postgres -d postgres
 # this is a destructive action
 # remove -- to take effect
 -- DROP DATABASE chatwoot_production with (FORCE);
 exit
```

8. Restore the database from the backup. If you are seeing no errors, the databse has been restored and you
are good to go.
```
 pg_restore --verbose --clean --no-acl --no-owner --create -U postgres -d postgres /tmp/cw.dump
```

9. Exec into the web pod and remove the onboarding variable in redis.

```
kubectl exec -it chatwoot-web-xxxxxxxxxx -- /bin/sh
RAILS_ENV=production bundle exec rails c
::Redis::Alfred.delete(::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
```

10. Load the Chatwoot web url, log in using the old credentials and verify the contents. Voila! Thats it!!

### To 0.9.x

This release adds support for horizontal pod autoscaling(hpa) for chatwoot-web and chatwoot-worker deployments.
Also, this changes the default redis replica count to `1`. The `Values.web.replicas` and `Values.worker. replicas` parameters
where renamed to `Values.web.replicaCount` and `Values.worker.replicaCount` respectively. Also `services.internlPort` was renamed
to `services.internalPort`.

Please make the necessary changes in your custom values file if needed.

### To 0.8.x

Move from Kubernetes ConfigMap to Kubernetes Secrets for environment variables. This is not a breaking change.

### To 0.6.x

Existing labels were causing issues with `helm upgrade`. `0.6.x` introduces breaking changes related to selector
labels used for deployments. Please delete your helm release and recreate it. Deleting your helm release will
not delete your persistent volumes used for Redis, and Postgres and as such your data should be safe.

```
helm delete chatwoot
helm repo update
helm install chatwoot chatwoot/chatwoot
```
