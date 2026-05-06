# Evolution Go no Chatwit

## Resumo

O Chatwit agora suporta **Evolution Go** como provider de `Channel::Whatsapp`, sem criar um novo `channel_type`.

O repositório do serviço foi adicionado como submodule em:

```text
evolution-go/
```

Origem do submodule:

```text
https://github.com/Witroch4/evolution-go.git
```

## Decisão arquitetural

- Mantém `Channel::Whatsapp`
- Usa `provider: "evolution_go"`
- `phone_number` passa a ser `nullable` até o pareamento do QR
- O token da instância é derivado no Chatwit via HMAC com `EVOLUTION_GO_GLOBAL_API_KEY`
- O Chatwit guarda só `instance_name` e estado da conexão em `provider_config`
- O fork Chatwit remove o gate de licença do upstream e inicializa o runtime como ativo no boot
- O fork Chatwit tambem remove a telemetria HTTP externa do upstream

Isso evita quebrar os pontos do produto que dependem de `channel_type == 'Channel::Whatsapp'`.

## Backend

Arquivos principais:

- `app/models/channel/whatsapp.rb`
- `app/services/evolution_go/client.rb`
- `app/services/evolution_go/provision_service.rb`
- `app/services/evolution_go/sync_state_service.rb`
- `app/services/evolution_go/webhook_service.rb`
- `app/services/whatsapp/providers/evolution_go_service.rb`
- `app/services/whatsapp/incoming_message_evolution_go_service.rb`
- `app/controllers/webhooks/evolution_go_controller.rb`
- `app/jobs/webhooks/evolution_go_job.rb`

Fluxo:

1. O usuário cria a inbox WhatsApp com `provider: evolution_go`
2. O Chatwit gera `instance_name` automaticamente
3. Após `create`, o Chatwit provisiona a instância no Evolution Go
4. O dashboard consulta `/api/v1/accounts/:account_id/inboxes/:inbox_id/evolution_go`
5. O usuário escaneia o QR
6. O webhook `/webhooks/evolution_go` recebe eventos de mensagem, receipt e conexão
7. Quando a instância conecta, o `phone_number` da inbox é preenchido com base no `jid`
8. O usuário pode cancelar explicitamente o pareamento no wizard; isso apaga a sessão remota, rota o `instance_name` local e exige um novo `Start pairing` para gerar outro QR

Compatibilidade importante de payload:

- O webhook do `evolution-go` chega com chaves minúsculas como `qrcode` e `code`
- Os endpoints REST `/instance/status` e `/instance/qr` podem responder com chaves Go-style como `Connected`, `LoggedIn`, `Qrcode` e `Code`
- `EvolutionGo::SyncStateService` precisa aceitar os dois formatos para não sobrescrever `provider_config['qr_code']` com `nil` durante o polling

## Frontend

O provider aparece como terceira opção no wizard de WhatsApp, ao lado de Cloud e Twilio.

Componente novo:

- `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/EvolutionWhatsapp.vue`

Fluxo do wizard:

1. Criar inbox
2. Mostrar `instance_name`, webhook e QR code
3. Polling automático do estado
4. Redirecionar para adicionar agentes apenas quando a sessão estiver realmente pronta: `connection_status == connected`, sem `qr_code` ativo e sem `reauthorization_required`

Reconexão de sessão desconectada pelo celular:

- O botão `Reconnect` na configuração da inbox abre o wizard com `reconnect=true`
- O wizard inicia uma nova tentativa de pareamento automaticamente para a inbox existente
- Se a Evolution Go retornar um QR junto de estado antigo `connected`, o QR tem precedência e o estado exibido deve ficar em `awaiting_qr`
- O frontend também normaliza esse caso para `awaiting_qr` antes de decidir labels, polling e avanço de etapa
- Enquanto existir QR ativo ou `reauthorization_required`, o wizard não pode pular para a etapa de agentes

## Compose e ENV

Variáveis novas:

- `EVOLUTION_GO_BASE_URL`
- `EVOLUTION_GO_GLOBAL_API_KEY`
- `EVOLUTION_GO_IMAGE`
- `EVOLUTION_GO_POSTGRES_AUTH_DB`
- `EVOLUTION_GO_POSTGRES_USERS_DB`
- `EVOLUTION_GO_DATABASE_SAVE_MESSAGES`
- `EVOLUTION_GO_WEBHOOK_URL`
- `EVOLUTION_GO_QRCODE_MAX_COUNT`

Arquivos atualizados:

- `.env.example`
- `docker-compose.yaml`
- `docker-compose.dev.yaml`
- `compose-produção.yaml`

Em desenvolvimento, o serviço builda diretamente do submodule.

Em producao, o `compose-produção.yaml` fixa a imagem e os parametros do servico `evolution_go` diretamente no manifest; o `build.sh` continua publicando o provider separadamente para deploy do Swarm.

## Scripts operacionais

### `dev.sh`

- Garante defaults locais para `EVOLUTION_GO_*` no `.env`
- Falha cedo se o submodule `evolution-go/` não estiver inicializado
- Reaplica automaticamente o patch Chatwit em `evolution-go/pkg/core/c0.go`
- Exibe URLs do Manager e Swagger da Evolution Go
- Permite abrir shell no serviço com `./dev.sh shell evolution-go`

### `build.sh`

- Builda a imagem principal do Chatwit e a imagem `evolution-go` no mesmo tag
- Faz push das duas imagens quando `--no-push` não é usado
- Faz autodeploy do serviço `evolution_go` no Swarm junto com `chatwoot_app` e `chatwoot_sidekiq`
- Reaplica automaticamente o patch Chatwit antes do build da imagem `evolution-go`
- Aceita `--skip-evolution` para pular o build/deploy do provider

## Observações operacionais

- No fork Chatwit, o runtime do Evolution Go sobe ativo sem exigir `/manager/login`
- `EVOLUTION_GO_GLOBAL_API_KEY` continua obrigatório para autenticação administrativa e derivação dos tokens de instância
- O fork Chatwit não envia telemetria de rotas para a infraestrutura externa da Evolution Go
- Fechar a aba do navegador não encerra a sessão de pareamento no backend; a instância continua ativa até conectar, ser encerrada explicitamente ou atingir o limite de QR
- O fork Chatwit usa `QRCODE_MAX_COUNT=20` por padrão para permitir regeneração suficiente do QR sem deixar a sessão em loop infinito
- O wizard agora tem ações explícitas de `Cancel pairing` e `Start pairing`; fechar a aba não encerra a sessão no backend
- Durante a geração do QR, sinais transitórios ou estado antigo do provider não devem avançar o wizard; a UI só pode pular para agentes quando o backend expõe `connection_status=connected` sem QR e sem reautorização pendente
- O callback configurado pelo Chatwit é `/webhooks/evolution_go`
- Templates oficiais do WhatsApp não são suportados nesse provider
- O Chatwit não aplica a janela de 24 horas para `evolution_go`
- Para envio de mídia, o Evolution Go consome a URL pública do blob gerada pelo Chatwit

## Patch local do fork

- Patch canônico: `patches/evolution-go/0001-disable-license-gate.patch`
- Patch de telemetria: `patches/evolution-go/0002-disable-external-telemetry.patch`
- Script de reaplicação: `scripts/evolution-go/apply-chatwit-patches.sh`
- Documento de manutenção: `chatwitdocs/evolution-go-upstream-sync.md`

## Limitações atuais

- Não há suporte a campanhas/template oficiais do Cloud API
- A aba de health continua exclusiva do WhatsApp Cloud
- O provider foi desenhado para happy path de inbox, QR, envio/recebimento de texto, mídia e receipts
