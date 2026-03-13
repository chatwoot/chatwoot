# Compose de producao

- O arquivo `compose-produção.yaml` foi alinhado com as envs declaradas em `.env.example` e com as envs customizadas do Chatwit usadas em producao.
- `REDIS_PASSWORD` foi mantido como string vazia porque o Redis de producao atual roda apenas na rede Docker interna, sem `requirepass`.
- `SOCIALWISE_WEBHOOK_URL` foi fixado como `https://socialwise.witdev.com.br` e `CHATWIT_WEBHOOK_SECRET` foi declarado no compose para o bootstrap do bot global.
- `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` e `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` foram adicionadas para manter MFA/2FA funcional em producao.
- `build.sh` agora gera `latest` por padrao; use `--no-latest` para publicar apenas a tag versionada.
- Env vars intencionalmente nao fixadas no compose:
  - `WHATSAPP_CLOUD_BASE_URL`: o codebase usa dois defaults diferentes e fixar um valor global pode quebrar chamadas legadas e do Socialwise Flow.
  - `VAPID_PUBLIC_KEY` e `VAPID_PRIVATE_KEY`: quando ausentes, o Chatwit gera e persiste o par automaticamente em `InstallationConfig`.
  - `ENABLE_SENTRY_TRANSACTIONS` e `DISABLE_SENTRY_PII`: o initializer usa checagem direta de truthiness em Ruby; declarar string nessas chaves muda o comportamento padrao.
  - `SMTP_SSL` e `SMTP_TLS`: o mailer tambem usa checagem direta de truthiness e um valor string no compose passaria a ativar esse caminho explicitamente.
  - `RAILS_MASTER_KEY`, `PORT`, `PIDFILE`, `BUNDLE_GEMFILE`, `CODESPACES`, `HEROKU_SLUG_COMMIT`: sao envs de runtime/plataforma, nao de configuracao do stack de producao.