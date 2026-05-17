# HANDOFF → Agente do fork **Chatwit**: endpoint `jusmonitoria_cobranca_template`

> **Para uma IA fria, sem contexto prévio, trabalhando no repositório do fork Chatwit
> (Rails — Chatwoot fork "Chatwit").** Leia tudo. Não assuma; o que você precisa saber
> está aqui. Esta é a ÚNICA pendência da feature "Parcelas + Cobrança automática" da
> plataforma JusMonitorIA — todo o lado `platform-core` (FastAPI) já está pronto,
> testado e em `main`. Falta só o endpoint Chatwit que provisiona/aprova o template
> WhatsApp de cobrança na Meta.

> **Princípio-chave (o usuário foi explícito):** *"já existe notificação que faz isso,
> é só mais um parecido"*. NÃO invente arquitetura. Localize o endpoint **existente e
> funcionando** `jusmonitoria_alert_template` no fork e **clone o padrão dele**,
> trocando apenas: o slug da rota, o nome do template, o corpo (texto) e as variáveis.
> O `alerta_movimentacao_processual_v1/v2` já foi **aprovado pela Meta como UTILITY** —
> espelhe a mesma pipeline e o mesmo tom de texto para que este também seja aprovado.

---

## 1. Por que este endpoint é necessário

A plataforma JusMonitorIA (repo `witdev-platform-core`, backend FastAPI) ganhou um
sistema de **cobrança automática de parcelas**: um job diário consolida as
parcelas a vencer/vencidas de cada cliente e envia **um lembrete/cobrança via
Chatwit** na inbox configurada pelo tenant.

- Inbox **NÃO WhatsApp Cloud** (Evolution/EG, web): a plataforma manda **texto livre**
  — funciona hoje, sem depender de você.
- Inbox **WhatsApp Cloud**: a Meta exige **template pré-aprovado**. A plataforma
  chama o Chatwit para (a) consultar o status do template `cobranca_parcela_v1` e
  (b) criá-lo/submetê-lo à Meta. **Esse endpoint ainda não existe no fork** → enquanto
  não existir, a plataforma degrada graciosamente (grava a cobrança como `PENDENTE` e
  avisa o dono do tenant). Sua tarefa é criar esse endpoint, espelhando o de alerta.

---

## 2. O contrato HTTP que a plataforma JÁ chama (você precisa satisfazer EXATAMENTE isto)

Fonte de verdade (lado plataforma, já em produção): arquivo
`backend/domains/jusmonitoria/services/parcela_cobranca/template.py` no repo
`witdev-platform-core`. Resumo do que ele chama:

### 2.1 GET — status do template
```
GET  {chatwit_base_url}/api/v1/accounts/{account_id}/inboxes/{inbox_id}/jusmonitoria_cobranca_template
     ?template_name=cobranca_parcela_v1
Headers:
  api_access_token: <agent_bot_token do tenant>
  Content-Type: application/json
```
Resposta: **JSON object**. A plataforma lê estes campos (mesmos do endpoint de
alerta — espelhe a resposta do `jusmonitoria_alert_template` 1:1):

| campo | tipo | uso na plataforma |
|---|---|---|
| `template_required` | bool | se `true` → plataforma exige template aprovado antes de enviar |
| `provider` | string | se `== "whatsapp_cloud"` → idem (exige template) |
| `template_status` | string | `"approved"` \| `"pending"` \| `"rejected"` \| `"missing"` \| ... (lowercase). Plataforma só envia se `approved`. |
| `delivery_locked` | bool | se `true` → plataforma NÃO envia mesmo aprovado |
| `rejected_reason` | string? | exibido na UI quando rejeitado |
| `template_category` / `requested_category` | string? | exibido na UI ("UTILITY") |
| `service_error` | string? | erros transientes da Meta |

> A UI da plataforma (`ParcelaTemplateStatusPanel.tsx`) trata todos esses campos como
> **opcionais** e tolera campos extras — mas eles devem existir quando aplicável,
> **idênticos** ao que `jusmonitoria_alert_template` já retorna. Reaproveite o mesmo
> serializer/serviço de status.

### 2.2 POST — garantir/criar+submeter o template
```
POST {chatwit_base_url}/api/v1/accounts/{account_id}/inboxes/{inbox_id}/jusmonitoria_cobranca_template
     ?template_name=cobranca_parcela_v1
Headers: api_access_token: <token>, Content-Type: application/json
Body: (vazio — sem corpo, exatamente como o POST do jusmonitoria_alert_template)
```
Comportamento esperado (espelhe o do alerta): se o template `cobranca_parcela_v1`
não existe nessa WABA/inbox, **cria a definição e submete à Meta** (categoria
UTILITY); se já existe, é idempotente; retorna o **mesmo JSON de status** do GET.

### 2.3 Envio (JÁ FUNCIONA — não mexer)
No momento do envio a plataforma manda a mensagem template pela rota genérica de
mensagens que o Chatwit já tem (roteada por `TemplateProcessorService →
channel.send_template()`). O payload de envio que a plataforma produz
(`build_template_payload`) é:
```json
{
  "name": "cobranca_parcela_v1",
  "language": "pt_BR",
  "category": "UTILITY",
  "processed_params": {
    "body":   { "nome": "<Nome do cliente>",
                "lista_parcelas": "<linhas consolidadas>",
                "valor_total": "<R$ X.XXX,XX>" },
    "header": { "media_type": "image",
                "media_url": "https://jusmonitoria.witdev.com.br/jusmonitorialogo.png" }
  }
}
```
→ A definição do template que você submeter à Meta **tem que casar com isto**:
header IMAGE + body com 3 variáveis na ordem `nome`, `lista_parcelas`,
`valor_total`. Use o **mesmo mapeamento named→posicional** que o
`jusmonitoria_alert_template` já usa (ele mapeia `processed_params.body.lista_processos`
para `{{1}}`; aqui são 3 variáveis → `{{1}}={{nome}}`, `{{2}}={{lista_parcelas}}`,
`{{3}}={{valor_total}}`). Copie a lógica de mapeamento do controller de alerta.

---

## 3. A definição do template Meta a criar — `cobranca_parcela_v1`

**Requisito do usuário:** UM único template que cobre os 3 momentos
(**3 dias antes**, **no dia**, **depois de vencido**). O texto que muda por caso
**vai dentro da variável `{{lista_parcelas}}`** (a plataforma já monta a frase
certa: "vence dd/mm" para lembrete, "venceu dd/mm" para atraso). O **scaffolding
hardcoded** do template é genérico e transacional o suficiente para valer para os 3
casos E para a Meta aprovar como **UTILITY** (não MARKETING).

- **name:** `cobranca_parcela_v1`
- **language:** `pt_BR`
- **category:** `UTILITY` (obrigatório; mesma categoria do alerta aprovado)
- **header:** tipo **IMAGE** (logo JusMonitorIA; a media_url vem no envio)
- **body** (texto hardcoded + 3 variáveis posicionais; tom transacional/conta,
  sem nada promocional — espelhe o tom do `alerta_movimentacao_processual` aprovado):

```
Olá {{1}}! 👋

Passando para lembrar sobre o(s) seguinte(s) pagamento(s) referente(s) aos seus serviços jurídicos:

{{2}}

Valor total em aberto: {{3}}

Caso já tenha efetuado o pagamento, por favor desconsidere esta mensagem. Em caso de dúvida, é só responder por aqui. Obrigado!
```

- **footer** (opcional, recomendado — espelhe o do alerta): `JusMonitorIA`
- **example/sample values** (a Meta exige amostras para aprovar): `{{1}}`="Maria
  Silva", `{{2}}`="Parcela 3: R$ 500,00 (vence 10/06/2026)\nParcela 4: R$ 500,00
  (vence 10/07/2026)", `{{3}}`="R$ 1.000,00". Forneça exemplos realistas como o
  controller de alerta já faz (sem isso a Meta rejeita).

**Por que isso passa como UTILITY (igual ao alerta):** é uma notificação
transacional sobre um pagamento de um serviço já contratado/prestado — não é
promoção/oferta. O texto fixo deixa claro o propósito (lembrete de pagamento de
serviço jurídico), o "desconsidere se já pagou" reforça caráter utilitário. Não
adicionar linguagem de venda, desconto, urgência agressiva ou CTA de marketing.

> Se a Meta rejeitar como MARKETING, ajuste o texto fixo para soar ainda mais
> "fatura/recibo" (ex.: "Referente ao contrato de prestação de serviços
> jurídicos…") — mesma estratégia que foi usada para aprovar o alerta. NÃO mude
> o nome/variáveis/contrato HTTP; só o texto fixo do body.

---

## 4. Onde mexer no fork Chatwit (descobrir e clonar o de alerta)

Você está num fork do Chatwoot (Rails). O endpoint de alerta análogo já existe e
funciona. Localize-o e clone:

1. Encontre o controller/rota do **`jusmonitoria_alert_template`**:
   `grep -rn "jusmonitoria_alert_template" app/ config/routes.rb` (procure a rota
   aninhada em `accounts/:account_id/inboxes/:inbox_id/jusmonitoria_alert_template`,
   o controller que a serve, e o serviço que define+submete o template à Meta e que
   monta o JSON de status).
2. Crie o equivalente `jusmonitoria_cobranca_template` **espelhando exatamente**:
   mesma rota aninhada (só muda o segmento final do path), mesmo controller pattern
   (GET=status, POST=ensure), mesmo serviço de submissão à Meta / leitura de status
   (parametrize por `template_name`/definição em vez de duplicar a lógica, se o
   código do alerta permitir; senão, duplique de forma isolada — não regressar o
   alerta). A única diferença de dados é a **definição do template** da §3
   (nome/categoria/header/body/variáveis/exemplos).
3. Reaproveite o pipeline já existente de aprovação Meta (submit + polling de
   status + cache do status) — é o que faz o alerta retornar `template_status`.
4. NÃO altere o endpoint/serviço de alerta nem o envio genérico
   (`TemplateProcessorService`). Mudança aditiva e isolada.

Docs Chatwit-side existentes para contexto: `/home/wital/chatwit/chatwitdocs/`
(ver `JusmonitorIA-contrato.md`, `chatwit-contrato-async-30s.md`,
`menssgem Interativas do WP.md`). O contrato plataforma↔Chatwit canônico no repo
platform-core: `docs/contrato-plataforma-unificada.md`.

---

## 5. Critérios de aceite (como saber que está pronto)

1. `GET .../inboxes/{id}/jusmonitoria_cobranca_template?template_name=cobranca_parcela_v1`
   numa inbox WhatsApp Cloud retorna JSON com `template_required`/`provider`/
   `template_status`/`delivery_locked` (e `rejected_reason` quando aplicável) —
   **mesma forma** que o `jusmonitoria_alert_template`.
2. `POST` na mesma rota cria o template `cobranca_parcela_v1` (UTILITY, pt_BR,
   header IMAGE, body §3, exemplos) e o **submete à Meta**; idempotente; retorna o
   status. Após aprovação Meta, o GET passa a retornar `template_status: "approved"`.
3. Numa inbox não-WhatsApp-Cloud, o endpoint responde coerentemente (ex.:
   `template_required: false`) — a plataforma então usa texto livre.
4. Não há regressão no `jusmonitoria_alert_template` nem no envio de templates.
5. Fim-a-fim: na plataforma JusMonitorIA, com inbox WhatsApp Cloud + template
   aprovado, o job diário `jm_parcela_cobranca_tick` envia a cobrança consolidada
   (variável `lista_parcelas` com as parcelas do cliente) e o cliente recebe a
   mensagem no WhatsApp com header de imagem + corpo §3 preenchido.

## 6. Teste manual sugerido

- Tenant de teste / inbox WhatsApp Cloud (sandbox Meta se disponível).
- `POST` o ensure → conferir no Business Manager que o template `cobranca_parcela_v1`
  foi submetido como UTILITY com 3 variáveis + header image.
- Após aprovação, do lado plataforma: aba *Configurações → Cobrança de parcelas*
  deve mostrar "Aprovado pela Meta"; criar um plano de parcelas com data de
  vencimento em D-3 e rodar o tick → cliente recebe a mensagem.

---

## 7. Resumo do que NÃO fazer

- Não criar 3 templates (um por caso). É **1** template; o caso varia via
  `{{lista_parcelas}}`.
- Não mudar o nome (`cobranca_parcela_v1`), as 3 variáveis, a ordem, o slug da
  rota, o header key (`api_access_token`) nem o formato de resposta — a plataforma
  já está codada contra isso (`template.py`).
- Não tornar o texto promocional/marketing (a Meta rejeita; tem que ser UTILITY).
- Não modificar/regredir o `jusmonitoria_alert_template` nem o envio genérico.
- Não adicionar dependência nova; reusar a pipeline Meta já existente do alerta.

---

### Apêndice — contrato exato do lado plataforma (referência imutável)

`witdev-platform-core/backend/domains/jusmonitoria/services/parcela_cobranca/template.py`:
- `COBRANCA_TEMPLATE_NAME = "cobranca_parcela_v1"`, `LANGUAGE = "pt_BR"`,
  `CATEGORY = "UTILITY"`, `HEADER_IMAGE_URL =
  "https://jusmonitoria.witdev.com.br/jusmonitorialogo.png"`.
- `_ENDPOINT_SLUG = "jusmonitoria_cobranca_template"`; header `api_access_token`;
  query `template_name`.
- `requires_template(s)` = `s.get("template_required") or s.get("provider")=="whatsapp_cloud"`.
- `template_is_ready(s)` = `str(s.get("template_status")).lower()=="approved" and not s.get("delivery_locked")`.
Espelhe a resposta do `jusmonitoria_alert_template` para que essas duas funções
funcionem sem alteração no lado plataforma.
