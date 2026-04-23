# Synapse OS — Próximos Passos

**Data do snapshot:** 2026-04-23
**Branch:** `custom/initial-cleanup` (sincronizada com `synapseos/main` no Railway)
**Última release pushada:** `e0ef88442` — PR 7 (Avisa mídia inbound/outbound)

---

## 1. Estado atual

### O que já está em produção (Railway)

**Overnights 04-21 e 04-22 (Sprints S1–S8):**
- Debloat + branding PT-BR (S1)
- CRM Pipeline com 5 stages default + webhooks N8N (S2) — Kanban CRUD completo em `/synapseos/pipeline`
- Painel lateral "Dados do Sistema Legado" + 3 custom attrs (S3)
- Notas privadas IA estilizadas (bubbles amber + "Nota da IA") (S4)
- Backend `AgentMetrics` + `LiveChannel` (ActionCable) (S5)
- `LiveDashboard` tempo real (S6)
- `AgentMetrics` C-Level dashboard (S7)
- Home redirect role-based (admin → AgentMetrics) (S8)

**Refactor de navegação (PRs 1–4):**
- Sidebar flat top-level (5 itens Synapse OS)
- `DashboardPage` com tabs (Visão geral / Relatórios ao vivo — embute `LiveReports`)
- `LiveAgents` drilldown server-side de conversas por agente (endpoint + painel split)
- N+1 de `last_message` corrigido (3 queries constantes)

**PR 5 v1 — Avisa transport direto:**
- `AvisaClient` (`POST /actions/sendMessage`, `POST /user/parselid`, `POST /webhook`) — sem N8N no transporte
- Inbound webhook autenticado por `token` do body (não mais HMAC)
- `IncomingMessageAvisaService` reescrito pra parsear whatsmeow bruto + resolve LID
- Wizard simplificado: `AvisaWhatsapp.vue` com 2 campos (phone + api_key)
- Auto-registro do webhook na Avisa via `after_commit`

**PR 7 — Avisa mídia (NOVO):**
- `AvisaClient#send_media` → `POST /actions/sendMedia` com `fileUrl` público (ActiveStorage `download_url`)
- `AvisaService#send_attachment_message` mapeia `attachment.file_type` → Avisa type (image/audio/video/document), envia caption quando aplicável, preserva `fileName` em documento
- `IncomingMessageAvisaService` detecta `*Message` keys no jsonData, anexa `params[:file]` (já descriptografado pela Avisa) via ActiveStorage e usa caption como `content`

### Pendências imediatas (faça primeiro quando voltar)

1. **Verificar que o build do PR 5 subiu no Railway** (commit `192f1bf6e`).
2. **Deletar a inbox Avisa antiga** (que foi criada com `n8n_url` no wizard anterior e nunca funcionou). Rails console:
   ```ruby
   Inbox.joins(:channel_whatsapp).where(channel_whatsapp: { provider: 'avisa' }).destroy_all
   ```
3. **Recriar inbox Avisa pelo wizard novo:** Settings → Inboxes → + → WhatsApp → Avisa. Só phone + token da instância. Aceite o checkbox de risco.
4. **Validar no painel da Avisa** que o webhook foi auto-registrado com URL `https://web-production-20688.up.railway.app/webhooks/avisa`.
5. **Teste inbound:** envie mensagem de texto pro WhatsApp da inbox. Deve aparecer em segundos no Chatwoot.
6. **Teste outbound:** responda pelo Chatwoot, deve chegar no WhatsApp.

Se 5 ou 6 falhar → `railway logs --service web` → procurar `[AVISA]`.

### Débitos técnicos conhecidos

- **Commit ruim `967362d71 "commit3"`**: mensagem inutilizável (só "commit3"). Landed via plumbing porque `git commit` estava travando. Não é crítico — o diff fala por si. Pode reescrever via `git rebase -i HEAD~N` depois, mas não antes de reiniciar.
- **Spec `whatsapp360_dialog_service_spec.rb` com read-error intermitente**: causou os travamentos de `git commit`. Reinício deve resolver. Se persistir, tentar `xattr -c spec/services/whatsapp/providers/whatsapp360_dialog_service_spec.rb` ou recheckout do arquivo.
- **Disco a 96%**: cleanup feito liberou pouco. Se voltar a apertar, matar mais `node_modules` de worktrees + caches Homebrew.

---

## 2. Validar PR 7 no Railway

Depois que o build subir, testes manuais:

1. **Outbound:** na conversa Avisa, anexe foto + texto → chega no WhatsApp com caption. Repetir com PDF (vira document, com nome do arquivo) e áudio (sem caption — o campo é ignorado).
2. **Inbound:** mande imagem + legenda pelo WhatsApp → aparece inline no Chatwoot, caption como conteúdo da mensagem.
3. **Inbound áudio/video/documento:** repetir; confirmar que arquivo abre / baixa pelo painel.
4. **Storage:** ir no Rails console e conferir que o `attachment.file` persistiu (`Attachment.last.file.attached?`). No Railway o ActiveStorage usa storage local do container se não houver S3 — se um restart apagar, é sinal de que precisa configurar S3/bucket externo.

Se algo quebrar → `railway logs --service web` → procurar `[AVISA]`.

### Ponto de atenção

`attachment.download_url` é uma URL pública (signed blob) gerada pelo próprio Railway. Se o domínio não estiver acessível publicamente (ex: preview environment atrás de auth), a Avisa vai falhar ao baixar. Confirmar que o `FRONTEND_URL` / `default_url_options` apontam pra domínio público resolvível.

---

## 3. Próximo PR recomendado: PR 8 — Reações, edições, quoted messages

### Escopo

- **reactionMessage**: mapear pro equivalente Chatwoot (atributo em `content_attributes` da msg original). O `reactionMessage.key.id` aponta pra `source_id` da mensagem citada — achar no banco e atualizar.
- **protocolMessage.editedMessage**: substituir `content` da mensagem original (source_id vem em `protocolMessage.key.id`).
- **quoted messages**: `extendedTextMessage.contextInfo.quotedMessage` → popular `in_reply_to_external_id` na criação da nova msg.

### Arquivos

| Arquivo | O quê |
|---|---|
| `app/services/whatsapp/incoming_message_avisa_service.rb` | Ramos novos antes de `persist_message` — reação/edição não criam msg nova |
| `app/services/whatsapp/providers/avisa_client.rb` | `react_message`, `edit_message` para outbound (opcional v1) |

---

## 4. PRs alternativos (se decidir priorizar outra coisa)

### PR 6 — Desacoplar AgentBot da criação de inbox
**Escopo:** hoje a inbox é criada e o AgentBot precisa ser associado manualmente. Proposta: botão "Adicionar agente de IA" separado, que permite plugar qualquer backend (N8N flow URL, LangChain FastAPI, etc.) em qualquer inbox.

**Por que não priorizei:** não bloqueia uso. Pode ser feito depois do PR 7.

**Arquivos:** novo componente `AgentBotConnector.vue` em `routes/dashboard/settings/inbox/`, novo endpoint pra criar/editar AgentBot + associação com inbox (provavelmente já existe nativo do Chatwoot — apenas expor na UI).

### PR 8 — Reações, edições, mensagens citadas, grupos
Mensagens especiais que hoje são descartadas. Complexidade média — cada uma tem lógica própria (reactionMessage referencia msg original, editedMessage substitui conteúdo, grupos precisam mapear participantes).

---

## 4. Como retomar depois de reiniciar o Mac

1. Abra chat novo no Claude Code nessa pasta.
2. A memória já tem tudo:
   - `project_avisa_api.md` — specs completas da API Avisa
   - `project_overnight_2026_04_22.md` — o que os overnights entregaram
   - Este doc (`docs/synapseos/next_steps.md`) — plano presente
3. Peça: "lê `docs/synapseos/next_steps.md` e continua o PR 7"
4. Antes de começar, confirmar estado git:
   ```
   git log --oneline -5
   ```
   Deve mostrar `e0ef88442` como HEAD.
5. Se git travar de novo, usar workaround de plumbing:
   ```bash
   rm -f .git/index.lock
   tree=$(git write-tree)
   commit=$(echo "msg" | git commit-tree "$tree" -p HEAD)
   git update-ref HEAD "$commit"
   ```

---

## 5. Referência rápida — Avisa API

- **Base URL:** `https://www.avisaapi.com.br/api`
- **Auth:** `Authorization: Bearer <token_instancia>` (token por instância, não por conta)
- **Send text:** `POST /actions/sendMessage` body `{number, message}`
- **Send media:** `POST /actions/sendMedia` body `{number, fileUrl, type, message?, fileName?}` — `type` ∈ `image|video|audio|document`
- **Register webhook:** `POST /webhook` body `{webhook}`
- **Resolve LID:** `POST /user/parselid` body `{lid}`
- **Inbound content-types:**
  - Texto: `application/x-www-form-urlencoded` (fields: `token`, `jsonData`)
  - Mídia: `multipart/form-data` (fields: `token`, `jsonData`, `file`)

Detalhes em `memory/project_avisa_api.md`.
