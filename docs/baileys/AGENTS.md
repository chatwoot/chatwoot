# Baileys Sidecar ↔ Nexus (Docker) — Instruções para IA

Este documento descreve **como o Baileys sidecar deve ser executado e integrado ao Nexus** (Rails) para WhatsApp funcionar corretamente, especialmente via **Docker Compose**.

## Objetivo

- **Baileys sidecar** (Node.js) roda como um serviço interno (porta `3500`).
- **Nexus** (Rails) consome o sidecar via `BAILEYS_SIDECAR_URL` e recebe **webhooks** do sidecar em rotas `POST /webhooks/baileys/*`.
- Autenticação service-to-service via header **`X-Api-Key`** (mesma chave em ambos).

## Contrato de integração (não quebrar)

### Rede / URLs (Docker)

- Dentro do `docker-compose`, o Nexus deve acessar o sidecar por hostname de serviço:
  - `BAILEYS_SIDECAR_URL=http://baileys:3500`
- O sidecar deve postar webhooks no Nexus usando o hostname do serviço Rails:
  - `NEXUS_WEBHOOK_URL=http://rails:3000`

**Importante:** esses hostnames só funcionam **dentro da rede do Compose**.

### Autenticação (obrigatório)

- Ambos devem compartilhar a mesma variável:
  - `BAILEYS_SIDECAR_API_KEY=...`
- O sidecar deve incluir **sempre** o header:
  - `X-Api-Key: ${BAILEYS_SIDECAR_API_KEY}`
  - em **todos** os requests para webhooks do Nexus.

Se a chave não estiver configurada, o Nexus pode rejeitar os webhooks (política de segurança).

### Webhooks que o sidecar deve disparar

O Nexus expõe (pelo menos) as rotas:

- `POST /webhooks/baileys/message`
- `POST /webhooks/baileys/status`
- `POST /webhooks/baileys/qr`
- `POST /webhooks/baileys/connection`
- `POST /webhooks/baileys/contact`
- `POST /webhooks/baileys/group`

Requisitos:

- Sempre enviar `X-Api-Key`.
- Incluir um identificador de sessão (`session_id`) consistente no payload (o Nexus usa isso para mapear o canal).
- Em QR code, o payload deve conter o QR (string) em campo estável (ex.: `qr_code`, `qr`, `data` — mantenha consistente com o que o Nexus espera no endpoint).

## Persistência de sessão (essencial)

O sidecar deve persistir o estado/sessões fora do container.

- Variável padrão:
  - `SESSIONS_DIR=/data/sessions`
- Volume no docker-compose:
  - `baileys_sessions:/data/sessions`

Sem isso, a sessão desconecta ao recriar o container.

## Docker Compose (desenvolvimento) — formato esperado

O stack de dev do Nexus usa o profile `whatsapp` para subir o sidecar.

O serviço `baileys` deve ser compatível com algo como:

```yaml
baileys:
  profiles: [whatsapp]
  build:
    context: ../Baileys
    dockerfile: sidecar/Dockerfile
  image: baileys-sidecar:development
  restart: unless-stopped
  ports:
    - "3500:3500"
  volumes:
    - baileys_sessions:/data/sessions
  environment:
    - PORT=3500
    - NEXUS_WEBHOOK_URL=http://rails:3000
    - BAILEYS_SIDECAR_API_KEY=${BAILEYS_SIDECAR_API_KEY:-}
    - LOG_LEVEL=info
    - SESSIONS_DIR=/data/sessions
  depends_on:
    - rails
```

## Produção (imagem publicada)

Em produção, pode ser usado um `image: ghcr.io/<org>/baileys-sidecar:latest` (sem `build`), mantendo o mesmo contrato de variáveis, volume e portas.

## Checklists de funcionamento (IA deve validar)

### Checklist 1 — inicialização do sidecar

- O processo escuta em `0.0.0.0:${PORT}` (no container).
- Cria/usa `SESSIONS_DIR` com permissão de escrita.
- Loga claramente:
  - URL destino de webhooks (`NEXUS_WEBHOOK_URL`)
  - modo de autenticação (`X-Api-Key` habilitado/valor presente)
  - diretório de sessão

### Checklist 2 — Nexus consegue falar com o sidecar

O Nexus usa `BAILEYS_SIDECAR_URL` para:

- pedir QR code / iniciar sessão
- consultar status
- desconectar

O sidecar deve expor endpoints compatíveis com esse fluxo (rotas e payloads coerentes com o cliente do Nexus).

### Checklist 3 — sidecar consegue chamar webhooks no Nexus

Ao receber eventos (mensagem, status, conexão, etc.), o sidecar deve:

- fazer `POST` para a rota correta (`/webhooks/baileys/...`)
- com `X-Api-Key` correto
- com `session_id` correto
- com timeouts e retries razoáveis (não travar o loop principal)

## Regras de implementação (para IA)

- **Não expor o sidecar publicamente** por padrão. Ele é um serviço interno; o acesso deve ser pela rede do Docker (ou rede privada).
- **Não mudar nomes de variáveis** (`BAILEYS_SIDECAR_URL`, `BAILEYS_SIDECAR_API_KEY`, `NEXUS_WEBHOOK_URL`, `SESSIONS_DIR`, `PORT`) sem atualizar o Nexus.
- **Não mudar o formato de webhooks** sem alinhar com o Nexus (contrato de payload + `session_id`).
- Sempre manter a **persistência** de sessão via volume.

## Layout recomendado (monorepo “irmão”)

Para dev local com Compose do Nexus:

```
<pasta>/
  Nexus/      # este repo (Rails)
  Baileys/    # repo do sidecar
```

O Nexus referencia `../Baileys` no `docker-compose.yaml`.

