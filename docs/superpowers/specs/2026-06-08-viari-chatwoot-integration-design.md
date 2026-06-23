# Integração Viari ↔ Chatwoot

**Data:** 2026-06-08
**Status:** Aprovado pelo usuário — pronto para implementação

---

## 1. Visão Geral

Integração nativa entre Chatwoot (atendimento) e Viari (gestão de turismo), seguindo o padrão da integração Shopify já existente no repositório. A atendente nunca precisa sair do Chatwoot para consultar dados do cliente, criar orçamentos ou enviar o texto de WhatsApp.

### Objetivos

1. **Sincronização automática de cliente** — ao abrir uma conversa, o sistema busca o cliente no Viari por telefone/e-mail. Se encontrar, vincula; se não, cria silenciosamente.
2. **Painel lateral com abas** — exibe reservas, orçamentos e pagamentos do cliente no painel lateral do Chatwoot, com a identidade visual do Viari.
3. **Jornada do cliente + labels CRM** — barra visual de progresso e labels automáticas aplicadas na conversa conforme o status do cliente no Viari.
4. **Modal de criação de orçamento** — fluxo completo em 3 etapas dentro de um modal, sem sair do Chatwoot.
5. **Texto WhatsApp automático** — ao confirmar o orçamento, o texto formatado é colado na caixa de mensagem da conversa, pronto para enviar.

---

## 2. Arquitetura

### Abordagem: Plugin Nativo (padrão Shopify)

```
Chatwoot (Vue + Rails)          Viari (Next.js)
─────────────────────           ──────────────────────────────
ContactPanel.vue                /api/viari/clientes/buscar
  └── ViariPanel.vue            /api/viari/clientes (POST)
       ├── ViariReservas.vue    /api/viari/clientes/[id]/reservas
       ├── ViariOrcamentos.vue  /api/viari/clientes/[id]/orcamentos
       └── ViariPagamentos.vue  /api/viari/clientes/[id]/pagamentos
                                /api/viari/orcamentos (POST)
ViariOrcamentoModal.vue         /api/viari/orcamentos/[id]/texto-whatsapp
                                /api/viari/produtos
                                /api/viari/agendas
                                /api/viari/tarifas/vigentes
                                /api/viari/canais-venda

Rails proxy controller          API Key auth (header X-Viari-Api-Key)
/api/v1/accounts/:id/           Armazenado como Integrations::Hook
  integrations/viari/           no banco do Chatwoot
```

### Princípio de segurança

A API key do Viari **nunca vai ao browser**. O Vue chama o Rails; o Rails chama o Viari com a key. Mesmo padrão do Shopify.

---

## 3. API REST a criar no Viari

Todos os endpoints ficam em `src/app/api/viari/` e exigem o header `X-Viari-Api-Key`. A key é gerada por tenant e armazenada no Viari como configuração do tenant.

### 3.1 Clientes

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/api/viari/clientes/buscar?telefone=&email=` | Busca cliente por telefone ou e-mail |
| `POST` | `/api/viari/clientes` | Cria cliente |
| `GET` | `/api/viari/clientes/[id]` | Dados completos do cliente |
| `GET` | `/api/viari/clientes/[id]/reservas` | Reservas do cliente |
| `GET` | `/api/viari/clientes/[id]/orcamentos` | Orçamentos do cliente |
| `GET` | `/api/viari/clientes/[id]/pagamentos` | Pagamentos do cliente |

**Body de criação de cliente:**
```json
{
  "nome": "Emilce Ramirez",
  "telefone": "+55 21 99772-4635",
  "email": "emilce@exemplo.com"
}
```

**Resposta de busca:**
```json
{
  "encontrado": true,
  "cliente": {
    "id": "uuid",
    "nome": "Emilce Ramirez",
    "telefone": "+55 21 99772-4635",
    "email": "emilce@exemplo.com",
    "hotelHospedado": "Hotel Pitinga",
    "dataChegada": "2025-06-14",
    "dataPartida": "2025-06-18",
    "statusJornada": "aguardando-sinal"
  }
}
```

### 3.2 Reservas

Resposta de `/api/viari/clientes/[id]/reservas`:
```json
{
  "reservas": [
    {
      "id": "uuid",
      "codigo": "RES-2025-0042",
      "produto": "Descoberta Dupla",
      "dataAgenda": "2025-06-15",
      "horario": "09:00",
      "pax": { "adt": 3, "chd": 0, "inf": 1, "sen": 0, "free": 0 },
      "status": "confirmada",
      "valorTotal": 540.00,
      "urlViari": "https://viari.portoseguroroteiros.com.br/reservas/uuid"
    }
  ]
}
```

### 3.3 Orçamentos

Resposta de `/api/viari/clientes/[id]/orcamentos`:
```json
{
  "orcamentos": [
    {
      "id": "uuid",
      "codigo": "ORC-2025-0043",
      "status": "enviado",
      "totalCartao": 1440.00,
      "totalPix": 1380.00,
      "dataValidade": "2025-06-12",
      "itens": 3,
      "urlViari": "https://viari.portoseguroroteiros.com.br/orcamentos/uuid"
    }
  ]
}
```

### 3.4 Criação de orçamento

`POST /api/viari/orcamentos`

```json
{
  "clienteId": "uuid",
  "canalVendaId": "uuid",
  "periodoInicio": "2025-06-15",
  "periodoFim": "2025-06-17",
  "dataValidade": "2025-06-12",
  "percentualSinal": 35,
  "descontoManual": 0,
  "obsInternas": "",
  "msgCliente": "",
  "itens": [
    {
      "produtoId": "uuid",
      "agendaId": "uuid",
      "qtdAdt": 3,
      "qtdChd": 0,
      "qtdInf": 1,
      "qtdSen": 0,
      "qtdFree": 0
    }
  ]
}
```

Resposta:
```json
{
  "id": "uuid",
  "codigo": "ORC-2025-0043",
  "textoWhatsapp": "🏠 Orçamento dos passeios:\n...",
  "urlViari": "https://viari.portoseguroroteiros.com.br/orcamentos/uuid"
}
```

### 3.5 Texto WhatsApp

`GET /api/viari/orcamentos/[id]/texto-whatsapp`

Retorna o texto formatado pronto para enviar via WhatsApp. O template é configurável no Viari por tenant.

**Formato gerado:**
```
🏠 Orçamento dos passeios:
Nome: {nome}
📞 Telefone: {telefone}

1° - {produto} {tipoPax} | R$ {valor} | Pax: {qtd}
...

💳 Cartão em até 6x s/ juros
Preço Total no Cartão: R$ {totalCartao}
Sinal para reserva de vagas (PIX): R$ {valorSinal}
Valor a acertar no dia do 1° passeio: R$ {restante}

✅ PIX
Preço Total no Pix: R$ {totalPix}
Sinal para reserva de vagas (PIX): R$ {valorSinalPix}
Valor a acertar no dia do 1° passeio: R$ {restantePix}
```

### 3.6 Produtos e agendas (para o modal)

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/api/viari/produtos?tipo=passeio` | Lista produtos ativos |
| `GET` | `/api/viari/agendas?produtoId=&dataInicio=&dataFim=` | Agendas com vagas disponíveis no período |
| `GET` | `/api/viari/tarifas/vigentes?produtoId=&data=` | Tarifas vigentes por produto e data |
| `GET` | `/api/viari/canais-venda` | Lista canais de venda disponíveis |

### 3.7 Autenticação da API

Cada tenant do Viari tem uma `apiKey` gerada aleatoriamente. O header obrigatório é:

```
X-Viari-Api-Key: <key>
X-Viari-Tenant-Id: <tenantId>
```

O middleware valida a key e injeta o `tenantId` no contexto antes de qualquer query.

---

## 4. Mudanças no Chatwoot

### 4.1 Configuração da integração

**Settings page:** `app/javascript/dashboard/routes/dashboard/settings/integrations/Viari.vue`

Campos:
- URL do Viari (ex: `https://viari.portoseguroroteiros.com.br`)
- API Key

Armazenado como `Integrations::Hook` com `app_id: 'viari'`, igual ao Shopify.

**Rails controller:** `app/controllers/api/v1/accounts/integrations/viari_controller.rb`

### 4.2 Proxy controller — ações

```ruby
# Rotas que o Rails expõe para o frontend Vue
GET  /api/v1/accounts/:id/integrations/viari/customer      # busca/cria cliente
GET  /api/v1/accounts/:id/integrations/viari/reservas      # reservas do cliente
GET  /api/v1/accounts/:id/integrations/viari/orcamentos    # orçamentos do cliente
GET  /api/v1/accounts/:id/integrations/viari/pagamentos    # pagamentos do cliente
GET  /api/v1/accounts/:id/integrations/viari/produtos      # lista produtos (para modal)
GET  /api/v1/accounts/:id/integrations/viari/agendas       # agendas disponíveis
GET  /api/v1/accounts/:id/integrations/viari/tarifas       # tarifas vigentes
GET  /api/v1/accounts/:id/integrations/viari/canais-venda  # canais de venda
POST /api/v1/accounts/:id/integrations/viari/orcamentos    # cria orçamento
GET  /api/v1/accounts/:id/integrations/viari/orcamentos/:id/texto-whatsapp
```

O controller lê a hook, monta a chamada HTTP para o Viari com a API key e repassa a resposta.

### 4.3 API JS client

`app/javascript/dashboard/api/integrations/viari.js`

```js
class ViariAPI extends ApiClient {
  constructor() { super('integrations/viari', { accountScoped: true }); }
  getCustomer(contactId) { ... }
  getReservas(contactId) { ... }
  getOrcamentos(contactId) { ... }
  getPagamentos(contactId) { ... }
  getProdutos() { ... }
  getAgendas(produtoId, dataInicio, dataFim) { ... }
  getTarifas(produtoId, data) { ... }
  getCanaisVenda() { ... }
  criarOrcamento(payload) { ... }
  getTextoWhatsapp(orcamentoId) { ... }
}
```

### 4.4 Componentes Vue

#### `ContactPanel.vue` — adição

```js
// Adicionar ao ContactPanel.vue junto com ShopifyOrdersList/LinearIssuesList
import ViariPanel from 'dashboard/components/widgets/conversation/viari/ViariPanel.vue';

const viariIntegration = useFunctionGetter('integrations/getIntegration', 'viari');
const isViariEnabled = computed(() => viariIntegration.value.enabled);
```

#### Estrutura de componentes

```
dashboard/components/widgets/conversation/viari/
├── ViariPanel.vue              # container principal — accordion no ContactPanel
├── ViariJourneyBar.vue         # barra de progresso da jornada
├── ViariCrmLabels.vue          # exibe e gerencia labels automáticas
├── ViariTabs.vue               # abas Reservas / Orçamentos / Pagamentos
├── ViariReservaCard.vue        # card de reserva individual (com link para Viari)
├── ViariOrcamentoCard.vue      # card de orçamento individual (com link para Viari)
├── ViariPagamentoCard.vue      # card de pagamento individual
└── ViariOrcamentoModal.vue     # modal de criação em 3 etapas
    ├── ViariModalStep1.vue     # dados gerais
    ├── ViariModalStep2.vue     # produtos / PAX / datas
    └── ViariModalStep3.vue     # revisão + texto WhatsApp
```

### 4.5 Paleta de cores Viari no Chatwoot

Os componentes usam classes Tailwind arbitrárias para manter a identidade visual do Viari:

| Token Viari | Hex | Uso |
|-------------|-----|-----|
| verde-noite | `#0D2B2A` | Header do painel, fundo do modal header |
| floresta | `#0F6E56` | Textos secundários, labels de campo |
| teal-aventura | `#1D9E75` | Elementos ativos, botão primário, border-left de cards |
| agua-clara | `#5DCAA5` | Títulos no header escuro, ícones |
| nevoa | `#E1F5EE` | Fundo da journey bar, fundo de totais |
| sol-poente | `#EF9F27` | Estados de atenção (pendente, aguardando sinal) |

---

## 5. Jornada do Cliente e Labels CRM

### 5.1 Etapas da jornada

```
Contato → Orçamento → Sinal → Reserva → Embarque
```

O `statusJornada` é derivado pelo Viari na resposta do endpoint de cliente, baseado nos dados reais:

| Condição no Viari | statusJornada |
|-------------------|---------------|
| Cliente criado, sem orçamento | `contato` |
| Orçamento em rascunho/enviado/visualizado | `orcamento` |
| Orçamento aprovado, sinal pendente | `sinal` |
| Reserva confirmada, pagamento pendente | `reserva` |
| Todos os pagamentos quitados | `pago` |
| Data do passeio passou | `embarque` |

### 5.2 Mapeamento de labels automáticas

| Evento/Status no Viari | Label aplicada no Chatwoot |
|------------------------|---------------------------|
| Cliente vinculado | `viari-vinculado` |
| Orçamento enviado | `orcamento-enviado` |
| Orçamento aprovado | `orcamento-aprovado` |
| Aguardando sinal | `aguardando-sinal` |
| Reserva confirmada | `reserva-confirmada` |
| Pagamento completo | `pago-completo` |
| Orçamento expirado ou recusado | `orcamento-perdido` |
| Passeio concluído | `concluido` |

**Comportamento:** Ao carregar o `ViariPanel`, o sistema lê o `statusJornada` e o status dos orçamentos/reservas, chama a API de labels do Chatwoot para remover labels cujo nome começa com `viari-` e aplicar as novas correspondentes. Labels sem esse prefixo (manuais da atendente) não são tocadas. As labels do grupo Viari devem ser pré-criadas na conta do Chatwoot durante a configuração da integração.

---

## 6. Modal de Criação de Orçamento — Fluxo Detalhado

### Etapa 1 — Dados gerais

Campos:
- **Cliente** — auto-preenchido com o contato da conversa (readonly)
- **Período** — data início / data fim
- **Canal de venda** — dropdown carregado de `/api/viari/canais-venda`
- **Validade do orçamento** — date picker
- **% de sinal** — número (ex: 35)
- **Desconto manual** — valor em R$ (opcional)
- **Observações internas** — textarea (não vai para o cliente)
- **Mensagem para o cliente** — textarea (vai no PDF)

### Etapa 2 — Produtos

**Adicionar item:**
1. Dropdown de produto — carregado de `/api/viari/produtos`
2. Ao selecionar produto → carrega agendas com vagas de `/api/viari/agendas?produtoId=&dataInicio=&dataFim=`
3. Dropdown de agenda mostra: data, horário, vagas disponíveis
4. Ao selecionar agenda → carrega tarifas de `/api/viari/tarifas/vigentes?produtoId=&data=`
5. Grid de PAX: ADT / CHD / INF / SEN / FREE — cada célula mostra o preço unitário carregado
6. Subtotal calculado em tempo real

**Totais (calculados no frontend):**
- Total cartão = soma de (qtd × valorUnit por faixa) de todos os itens
- Total PIX = Total cartão − desconto PIX (configurado no Viari por canal)
- Valor do sinal = Total PIX × (% sinal / 100)
- Valor a acertar = Total PIX − sinal

### Etapa 3 — Revisão

- Exibe resumo dos dados gerais e lista de itens
- Gera preview do texto WhatsApp (calculado localmente com os mesmos dados)
- Botão **"Confirmar e colar na conversa"**:
  1. POST para o Rails → Rails cria o orçamento no Viari
  2. Viari retorna `{ textoWhatsapp, urlViari, codigo }`
  3. O texto é inserido no input de mensagem da conversa via evento do store
  4. O modal fecha
  5. Labels e painel são atualizados

---

## 7. Sincronização Automática do Cliente

### Fluxo ao abrir a conversa

```
ContactPanel monta
  → ViariPanel.vue watch(contactId)
  → chama GET /api/v1/accounts/:id/integrations/viari/customer?contact_id=:cid
  → Rails busca contato (telefone + email)
  → Rails chama GET /api/viari/clientes/buscar no Viari
  → Se encontrado: retorna dados + statusJornada
  → Se não encontrado: Rails chama POST /api/viari/clientes com nome/telefone/email
  → Retorna cliente recém-criado
  → ViariPanel exibe dados e aplica labels
```

### Persistência do vínculo

O `viariClienteId` é armazenado como atributo customizado do contato no Chatwoot (`contact.additional_attributes['viari_cliente_id']`). Nas próximas aberturas, o painel usa o ID diretamente sem nova busca por telefone/email.

---

## 8. Link para o Viari

Todo card (reserva, orçamento, pagamento) exibe um ícone de link externo (↗) no canto superior direito. Ao clicar, abre a URL correspondente no Viari em nova aba:

- Reserva: `{VIARI_URL}/reservas/{id}`
- Orçamento: `{VIARI_URL}/orcamentos/{id}`
- Pagamento: `{VIARI_URL}/financeiro/pagamentos/{id}`

A `VIARI_URL` vem da hook configurada na integração.

---

## 9. Arquivos a Criar/Modificar

### Viari (`/Users/alexandre/Code/viari`)

**Novos:**
- `src/app/api/viari/clientes/buscar/route.ts`
- `src/app/api/viari/clientes/route.ts`
- `src/app/api/viari/clientes/[id]/route.ts`
- `src/app/api/viari/clientes/[id]/reservas/route.ts`
- `src/app/api/viari/clientes/[id]/orcamentos/route.ts`
- `src/app/api/viari/clientes/[id]/pagamentos/route.ts`
- `src/app/api/viari/orcamentos/route.ts`
- `src/app/api/viari/orcamentos/[id]/texto-whatsapp/route.ts`
- `src/app/api/viari/produtos/route.ts`
- `src/app/api/viari/agendas/route.ts`
- `src/app/api/viari/tarifas/vigentes/route.ts`
- `src/app/api/viari/canais-venda/route.ts`
- `src/lib/auth/viari-api-key.ts` — função `requireViariApiKey(request)` que valida o header e retorna `{ tenantId }` ou lança 401. Chamada no topo de cada route handler (Next.js App Router não suporta middleware por subpasta).

**Modificados:**
- `prisma/schema.prisma` — adicionar campo `apiKey` ao model `Tenant`
- `src/app/actions/configuracoes.ts` — gerar/regenerar API key

### Chatwoot (`/Users/alexandre/Code/chatwoot-roteiros`)

**Novos:**
- `app/controllers/api/v1/accounts/integrations/viari_controller.rb`
- `app/javascript/dashboard/api/integrations/viari.js`
- `app/javascript/dashboard/routes/dashboard/settings/integrations/Viari.vue`
- `app/javascript/dashboard/components/widgets/conversation/viari/ViariPanel.vue`
- `app/javascript/dashboard/components/widgets/conversation/viari/ViariJourneyBar.vue`
- `app/javascript/dashboard/components/widgets/conversation/viari/ViariCrmLabels.vue`
- `app/javascript/dashboard/components/widgets/conversation/viari/ViariTabs.vue`
- `app/javascript/dashboard/components/widgets/conversation/viari/ViariReservaCard.vue`
- `app/javascript/dashboard/components/widgets/conversation/viari/ViariOrcamentoCard.vue`
- `app/javascript/dashboard/components/widgets/conversation/viari/ViariPagamentoCard.vue`
- `app/javascript/dashboard/components/widgets/conversation/viari/ViariOrcamentoModal.vue`
- `app/javascript/dashboard/components/widgets/conversation/viari/ViariModalStep1.vue`
- `app/javascript/dashboard/components/widgets/conversation/viari/ViariModalStep2.vue`
- `app/javascript/dashboard/components/widgets/conversation/viari/ViariModalStep3.vue`

**Modificados:**
- `config/routes.rb` — adicionar rotas do Viari controller
- `app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue` — montar ViariPanel
- `app/javascript/dashboard/routes/dashboard/settings/integrations/` — adicionar entrada Viari

---

## 10. Decisões de Arquitetura

| Decisão | Motivo |
|---------|--------|
| Rails como proxy (nunca chama Viari diretamente do browser) | API key nunca exposta ao cliente; sem CORS |
| `viariClienteId` em `contact.additional_attributes` | Evita nova busca por telefone/email a cada abertura |
| Labels aplicadas por grupo — só remove labels do grupo Viari | Não interfere em labels manuais da atendente |
| Texto WhatsApp gerado pelo Viari (não pelo Chatwoot) | Template configurável por tenant no Viari |
| Modal em 3 etapas separadas | Isola responsabilidades; cada etapa valida antes de avançar |
| Preços carregados sob demanda (por produto/data) | Garante tarifas sempre vigentes; não cacheia valores |
| `statusJornada` calculado pelo Viari, não pelo Chatwoot | Regras de negócio do turismo ficam no sistema de origem |
</content>
