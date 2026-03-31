# Evolution Go: Notas de Sync com Upstream

## Objetivo

O fork Chatwit do `evolution-go` remove a dependência de licença do upstream para que o provider interno suba operacional sem registro externo.

O comportamento é aplicado em:

- `evolution-go/pkg/core/c0.go`

E é mantido de forma reproduzível por:

- `patches/evolution-go/0001-disable-license-gate.patch`
- `patches/evolution-go/0002-disable-external-telemetry.patch`
- `scripts/evolution-go/apply-chatwit-patches.sh`

## O que o patch faz

- Inicializa o runtime como ativo no boot
- Usa `GLOBAL_API_KEY` apenas como chave de autenticação da API local
- Remove chamadas remotas de ativação, heartbeat e deactivate do fluxo Chatwit
- Remove a telemetria HTTP enviada para `log.evolution-api.com`
- Mantém intactas as rotas de instância, QR code, webhook e envio/recebimento
- Mantém o stack Chatwit com `QRCODE_MAX_COUNT=20` para permitir regeneração estável de QR sem deixar a sessão em loop infinito

## Regra importante

`EVOLUTION_GO_GLOBAL_API_KEY` continua obrigatória.

Ela não serve mais para licenciamento no fork Chatwit, mas continua sendo a fonte de verdade para:

- autenticação administrativa do `evolution-go`
- derivação do token de instância usada pelo Chatwit

## Workflow após sync com upstream

1. Atualize o submodule ou a branch do fork `Witroch4/evolution-go`.
2. Rode `scripts/evolution-go/apply-chatwit-patches.sh`.
3. Se o script falhar, o upstream alterou `pkg/core/c0.go` e o patch precisa ser refeito manualmente.
4. Depois de ajustar o patch, atualize este documento e `chatwitdocs/evolution-go-whatsapp.md`.
5. Rebuild a imagem com `./build.sh` ou suba localmente com `./dev.sh`.

## Validação mínima após sync

1. `wget -qO- http://localhost:8080/license/status`
2. Confirmar retorno `{"status":"active", ...}`
3. `wget -qO- --header=\"apikey: $EVOLUTION_GO_GLOBAL_API_KEY\" http://localhost:8080/instance/all`
4. Confirmar que a API não responde mais `503 service not activated`
5. Criar uma inbox `provider: evolution_go` e validar geração de QR
6. Confirmar que o polling do Chatwit continua lendo tanto payload REST Go-style (`Connected`, `LoggedIn`, `Qrcode`, `Code`) quanto webhook payload (`connected`, `loggedIn`, `qrcode`, `code`)

## Motivo de manter patch + script

O submodule ainda acompanha upstream. Sem um patch versionado no repositório principal, um sync futuro pode reintroduzir o gate de licença silenciosamente.

O script foi ligado em:

- `dev.sh`
- `build.sh`

Assim, quando o patch deixar de aplicar, o processo falha cedo em vez de quebrar só em runtime.
