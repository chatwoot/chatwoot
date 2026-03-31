# Compose de producao

- O arquivo `compose-produção.yaml` foi alinhado com as envs declaradas em `.env.example` e com as envs customizadas do Chatwit usadas em producao.
- `compose-produção.yaml` e o unico manifest canonico de producao; o arquivo duplicado `chatwit-producao.yaml` foi removido para evitar drift entre configuracoes.
- `REDIS_PASSWORD` foi mantido como string vazia porque o Redis de producao atual roda apenas na rede Docker interna, sem `requirepass`.
- `SOCIALWISE_WEBHOOK_URL` foi fixado como `https://socialwise.witdev.com.br` e `CHATWIT_WEBHOOK_SECRET` foi declarado no compose para o bootstrap do bot global.
- `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` e `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` foram adicionadas para manter MFA/2FA funcional em producao.
- `build.sh` agora gera `latest` por padrao; use `--no-latest` para publicar apenas a tag versionada.
- O compose de producao nao monta mais `/app/public`; os assets passam a vir sempre da imagem publicada, evitando precisar apagar volume para o codigo novo entrar em vigor.
- `build.sh` agora pode fazer autodeploy via Portainer Docker Proxy API apos o push. Defina `PORTAINER_URL`, `PORTAINER_API_KEY` e opcionalmente `PORTAINER_ENDPOINT_ID`; use `--no-deploy` para pular essa etapa.
- O servico `evolution_go` nao usa mais interpolacao `${EVOLUTION_GO_*}` em producao; imagem, portas e conexoes ficam fixadas diretamente no `compose-produção.yaml`.
- `EVOLUTION_GO_GLOBAL_API_KEY` tambem foi fixada no compose de producao e deve permanecer identica entre o ambiente do Chatwit e o `GLOBAL_API_KEY` do servico `evolution_go`; no fork Chatwit ela continua sendo usada para autenticacao e derivacao dos tokens de instancia, nao para licenciamento remoto.
- `QRCODE_MAX_COUNT` deve permanecer em `20` no servico `evolution_go`; fechar a aba nao encerra a sessao no backend, entao esse limite funciona como guarda-corpo para evitar loop infinito de QR sem voltar ao timeout agressivo de 5 tentativas do upstream.
- `DISABLE_TELEMETRY` deve permanecer em `true` no fork Chatwit; isso desliga Hub/Amplitude/Sentry no app e a telemetria HTTP externa do `evolution-go`, sem afetar as features do produto.
- Env vars intencionalmente nao fixadas no compose:
  - `WHATSAPP_CLOUD_BASE_URL`: o codebase usa dois defaults diferentes e fixar um valor global pode quebrar chamadas legadas e do Socialwise Flow.
  - `VAPID_PUBLIC_KEY` e `VAPID_PRIVATE_KEY`: quando ausentes, o Chatwit gera e persiste o par automaticamente em `InstallationConfig`.
  - `ENABLE_SENTRY_TRANSACTIONS` e `DISABLE_SENTRY_PII`: o initializer usa checagem direta de truthiness em Ruby; declarar string nessas chaves muda o comportamento padrao.
  - `SMTP_SSL` e `SMTP_TLS`: o mailer tambem usa checagem direta de truthiness e um valor string no compose passaria a ativar esse caminho explicitamente.
  - `RAILS_MASTER_KEY`, `PORT`, `PIDFILE`, `BUNDLE_GEMFILE`, `CODESPACES`, `HEROKU_SLUG_COMMIT`: sao envs de runtime/plataforma, nao de configuracao do stack de producao.
