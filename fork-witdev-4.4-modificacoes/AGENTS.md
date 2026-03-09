# Chatwoot Development Guidelines (SocialWise Flow & Rich Messages)

> Este documento consolida o que funcionou no projeto, lições aprendidas e checklists para e### Antiflicker (Eliminação Total do Flash Effect) ✅

**PRINCÍPIO FUNDAMENTAL**: Single Source of Truth - apenas backend verifica feature flags.

**Fluxo Anti-Flicker**:
1. **Backend** (`InstagramResponseProcessor`): ## Checklists Antiflicker - ATUALIZADO 2025

### ✅ Verificações de Flash Effect

1. **Feature flag** `SOCIALWISE_RICH_DASHBOARD` **ativada** no Account
2. **Backend**: cria mensagem **diretamente** como `content_type: "cards"` quando flag ativa
3. **Service**: verifica `message_already_rich?` e **pula mirroring** se já rica
4. **Frontend**: **NÃO verifica flag** - renderiza baseado apenas em `items.length > 0`
5. **Layout**: altura fixa em imagens para evitar layout shift
6. **Error Handling**: `@error` oculta imagens quebradas

### 🔍 Logs Esperados para Sucesso

**Backend (Sem Flash)**:
```
[SOCIALWISE-INSTAGRAM-RICH] Message already created as rich cards, skipping mirroring
```

**Frontend (Performance)**:
```
[RichCards] Image loaded successfully: https://...
[RichCards] render_success
```

**SocialWise Flow (Multi-Canal)**:
```
[SOCIALWISE-FLOW] === PROCESSING RESPONSE ===
[SOCIALWISE-FLOW] Channel type: Channel::Instagram
[SOCIALWISE-FLOW-WHATSAPP] Processing Interactive Message (para WhatsApp)
```ccount.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')`
2. **Se habilitada**: cria mensagem **diretamente** com `content_type: "cards"` e `content_attributes` completos
3. **Service** (`RichMessageService`): verifica `message_already_rich?` e **pula mirroring** se já rica
4. **Frontend** (`RichCards.vue`): **NÃO verifica flag** - se foi chamado, backend já decidiu

**Log esperado para sucesso anti-flicker**:
```
[SOCIALWISE-INSTAGRAM-RICH] Message already created as rich cards, skipping mirroring
```regressões. **Atualizado em Janeiro 2025 com base na implementação atual do SocialWise Flow.**

---

## Build / Test / Lint

- **Setup**: `bundle install && pnpm install`
- **Run Dev**: `docker-compose up` ou `overmind start -f ./Procfile.dev`
- **Lint JS/Vue**: `pnpm eslint` / `pnpm eslint:fix`
- **Lint Ruby**: `bundle exec rubocop -a` (via Docker: `docker exec chatwit-dev-rails-1 bundle exec rubocop -a`)
- **Test JS**: `pnpm test` / `pnpm test:watch`
- **Test Ruby**: `docker exec chatwit-dev-rails-1 bundle exec rspec spec/path/to/file_spec.rb`
- **Single Test**: `docker exec chatwit-dev-rails-1 bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- **Run Project**: `docker-compose up` (padrão) ou `overmind start -f Procfile.dev` (local)

---

## Arquitetura SocialWise Flow (Multi-Canal)

### Visão Geral da Integração

O **SocialWise Flow** é o processador central que conecta o Chatwit com o sistema SocialWise, oferecendo suporte multi-canal para WhatsApp, Instagram e Facebook. Ele processa respostas automáticas, mensagens ricas e reações em tempo real.

### Componentes Principais

#### 1. Processador Principal
- **`Integrations::SocialwiseFlow::ProcessorService`**
  - Herda de `Integrations::BotProcessorService`
  - Processa mensagens de múltiplos canais (WhatsApp, Instagram, Facebook)
  - **URL padrão**: `https://socialwise.witdev.com.br/api/integrations/webhooks/socialwiseflow`
  - **Logs estruturados**: prefixo `[SOCIALWISE-FLOW]` com contexto completo

#### 2. Fluxo de Processamento Multi-Canal
1. **Recebe evento** da conversa (message.created, message.updated)
2. **Constrói request enriquecido** via `WebhookEnhancerService`
3. **Faz chamada HTTP** para SocialWise Flow API com payload completo
4. **Rota por tipo de canal** baseado no `channel_type`:
   - `Channel::Whatsapp` → delega para `WhatsappResponseProcessor`
   - `Channel::Instagram` → delega para `InstagramResponseProcessor`
   - `Channel::FacebookPage` → processa diretamente
5. **Fallback gracioso** em caso de erros

#### 3. Processadores Especializados por Canal

**WhatsApp** (`Integrations::SocialwiseFlow::WhatsappResponseProcessor`):
- Suporte a mensagens interativas (`interactive`)
- Mensagens de texto simples (`text`)
- Logs com prefixo `[SOCIALWISE-FLOW-WHATSAPP]`
- Integração nativa com API do WhatsApp

**Instagram** (`Integrations::Socialwise::InstagramResponseProcessor`):
- **Generic Template**: Cards com imagens, títulos, botões (1-10 elementos)
- **Button Template**: Texto com botões de ação (1-3 botões)
- **Quick Replies**: Respostas rápidas (1-13 opções)
- **Anti-flicker**: criação direta como rich content
- Logs com prefixo `[SOCIALWISE-INSTAGRAM-DIALOGFLOW]`

**Facebook**:
- Rich content via `content_type: 'integrations'`
- Fallback para texto simples
- Validação de recipient ID

#### 4. Tipos de Resposta Suportados

**Button Reactions** (`button_reaction`):
- **Emoji**: Envio de reação emoji (WhatsApp: qualquer emoji, Instagram: apenas 'love')
- **Texto contextual**: Resposta textual associada à reação
- **Handoff actions**: Suporte a transferências de conversa
- **Diferenciação por canal**: comportamento específico para cada plataforma

**Mensagens Ricas**:
- Templates interativos para WhatsApp
- Cards e quick replies para Instagram
- Fallback automático para texto quando processamento falha

### 5. WebhookEnhancerService

**Função**: Enriquece payloads de webhook com dados contextuais do SocialWise.

**Dados enriquecidos**:
- **Contact data**: nome, telefone, email, custom attributes
- **Conversation data**: status, assignee, timestamps  
- **Message data**: conteúdo, tipo, dados interativos
- **WhatsApp identifiers**: WAMID, contact source
- **Flat structure**: campos no nível raiz para facilitar consumo por webhooks

**Cache inteligente**: Otimização de performance com invalidação automática.

### 6. Observabilidade e Logs Estruturados

**Padrão de Logs**:
- **Prefixos por integração**: `[SOCIALWISE-FLOW]`, `[SOCIALWISE-FLOW-WHATSAPP]`, `[SOCIALWISE-INSTAGRAM-DIALOGFLOW]`
- **IDs de rastreamento**: message_id, conversation_id, account_id, inbox_id, contact_id
- **Contexto completo**: channel_type, payload completo, backtrace em erros
- **Níveis apropriados**: INFO para fluxo normal, WARN para fallbacks, ERROR para falhas

**Métricas de Performance**:
- Tempo de processamento em millisegundos
- Duração de chamadas à API do Instagram/WhatsApp
- Rate de sucesso/fallback por canal

**Error Handling Resiliente**:
- Logs detalhados com contexto completo
- Fallback messages quando processamento falha
- Continuidade do fluxo mesmo com falhas parciais
- Separação entre falhas críticas e não-críticas

---

## Code Style

- **Ruby**: RuboCop (largura de linha máx. \~150)
- **Vue/JS**: ESLint (Airbnb + Vue 3)
- **Componentes Vue**: PascalCase
- **Eventos**: camelCase
- **i18n**: Sem strings “nuas” em templates; use i18n
- **Erros**: Use exceções customizadas (`lib/custom_exceptions/`)
- **Models**: Valide presença/unicidade + índices corretos
- **Type Safety**: Props no Vue, strong params no Rails
- **Nomeação**: clara e consistente
- **Vue 3**: Sempre Composition API com `<script setup>` no topo

## Styling

- **Tailwind only**

  - Não escrever CSS custom
  - Não usar `scoped`
  - Não usar inline styles (salvo correções pontuais acessíveis)
  - Utilizar utilitários Tailwind e tokens de cor do `tailwind.config.js`

## Princípios Gerais

- MVP: menor dif. de código, foco no happy-path
- Sem defensivismo desnecessário
- Divida tarefas grandes em unidades pequenas e testáveis
- Itere após validação
- Não escrever specs salvo pedido explícito
- Remova código morto/não usado
- Não manter duas abordagens para a mesma lógica—escolha e implemente
- Não referenciar outros AIs em commits

---

## Fluxo **Instagram Rich Message** (Backend)

### Componentes Principais

- **Processor**: `Integrations::Socialwise::InstagramResponseProcessor`
  - Normaliza payloads de ambos Dialogflow e SocialWise Flow
  - Valida formatos: `GENERIC_TEMPLATE`, `BUTTON_TEMPLATE`, `QUICK_REPLIES`
  - Delega para `Instagram::RichMessageService` para envio e mirroring

- **Service**: `Instagram::RichMessageService`
  - **Rich dashboard sempre habilitado** (feature flag dependency removida)
  - Verifica `message_already_rich?` antes de fazer mirroring
  - Logs extensivos com prefixo `[SOCIALWISE-INSTAGRAM-RICH]`
  - Métricas de tempo de API e processamento

### Antiflicker (sem “flash” de texto)

- **Regra de ouro**: se a feature `SOCIALWISE_RICH_DASHBOARD` estiver **ativada no Account**, **crie a mensagem diretamente com** `content_type: "cards"` (ou `input_select`) e `content_attributes` mapeados.
- No service, **antes de espelhar**, checar `message_already_rich?` e **pular mirroring** se já estiver rica.
- Usar `additional_attributes: { skip_send_reply: true }` para ligar os pontos com o fluxo assíncrono sem emitir eventos em duplicidade.
- Registrar logs como: _“Message already created as rich cards, skipping mirroring”_ para confirmar o caminho correto.

### Validações de Payload (Instagram API Compliant)

- **GENERIC_TEMPLATE**:
  - 1-10 elementos; `title` obrigatório (≤ 80 chars)
  - Máx. 3 botões por elemento
  - `image_url` opcional mas validada se presente

- **BUTTON_TEMPLATE**:
  - `text` obrigatório (≤ 2000 chars)
  - 1-3 botões obrigatórios

- **QUICK_REPLIES**:
  - `text` obrigatório (≤ 1000 chars)
  - 1-13 quick replies; `title` ≤ 20 chars

- **Botões**:
  - `postback`: requer `payload` (≤ 1000 chars)
  - `web_url`: requer URL válida https (≤ 2000 chars)

### Mapeamento para Dashboard (Chatwoot Renderer)

- **Mapper**: `Messages::InstagramRendererMapper.map(instagram_payload)`
- **Output**: `fallback_text`, `content_type`, `content_attributes`
- **Anti-flicker**: cria mensagem diretamente como rica quando feature habilitada

### Observabilidade Atualizada

- Logs com prefixo `[SOCIALWISE-INSTAGRAM-RICH]` para todas as etapas
- Métricas de performance: duração de API calls e processamento total
- Error handling resiliente com fallback gracioso

---

## Frontend (Vue 3 + Vite) — Rich Cards & Quick Replies - ATUALIZADO 2025

### Componentes Principais

- **Local**: `app/javascript/dashboard/components-next/message/bubbles/`
- **RichCards.vue**:
  - **Princípio Chave**: **NÃO verifica feature flag** (backend já decidiu)
  - Lê `contentAttributes.items` para renderizar cards
  - Render condicional apenas baseado na presença de `items`
  - **Layout Shift Prevention**: altura fixa para imagens (`h-48`)
  - **Performance**: `loading="lazy"`, `decoding="async"`
  - **Error Handling**: `@error` para ocultar imagens quebradas
  - **Acessibilidade**: `role="group"`, `aria-label`

- **QuickReplies.vue** (se existir):
  - Mesma lógica: sem verificação de flag
  - Emite `BUS_EVENTS.RICH_POSTBACK` ao clicar
  - **Acessibilidade**: `role="button"`, `:aria-label`

### Feature Flag Frontend - ATUALIZAÇÃO CRÍTICA

**❌ ERRADO - Dupla Verificação**:
```vue
<!-- NÃO FAZER: verificação de flag no componente rico -->
<script setup>
const isRichEnabled = useMapGetter('accounts/isFeatureEnabledonAccount');
const shouldRender = computed(() => 
  isRichEnabled.value('SOCIALWISE_RICH_DASHBOARD') && items.value.length > 0
);
</script>
```

**✅ CORRETO - Single Source of Truth**:
```vue
<!-- FAZER: confiar na decisão do backend -->
<script setup>
const shouldRenderRichCards = computed(() => {
  // Se este componente foi chamado, backend já verificou flag
  return items.value.length > 0;
});
</script>
```

### Performance & Dev Experience

**Logs de Desenvolvimento**:
```javascript
// Proteger logs dev-only
const isDev = import.meta.env.MODE !== 'production';
const handleImageLoad = (src) => {
  if (isDev) {
    console.log('[RichCards] Image loaded:', src);
  }
};
```

**Métricas**:
```javascript
function trackMetric(name, labels) {
  if (window.analytics) {
    window.analytics.track(name, labels);
  }
}
```
  - Métricas: `trackMetric('cw_rich_cards_render_total', …)`
  - Erros: `onErrorCaptured` + emitir `RICH_CARDS_FALLBACK`
  - **Importante:** **não** usar `import.meta` dentro de **expressões de template** (causa erro de parse do compiler); use em código JS no `<script setup>` ou encapsule em métodos/computed e chame via eventos.
  - Imagem: reservar espaço para evitar layout shift (`class="w-full h-48 object-cover"`), `loading="lazy"`, `decoding="async"` e `@error` para esconder imagem quebrada.

- **QuickReplies.vue**

  - Lê `contentAttributes.items`
  - Emite `BUS_EVENTS.RICH_POSTBACK` com `{ messageId, payload, text, type: 'quick_reply' }`
  - Métricas análogas (`cw_quick_replies_render_total`)
  - Acessibilidade: `role="button"`, foco, `:aria-label`

### Feature flag no FE

- **IMPORTANTE**: **NÃO** verificar feature flag dentro de componentes ricos (RichCards/QuickReplies). Se o componente foi chamado, significa que o backend já verificou que o flag está habilitado.
- **Arquitetura correta**:
  - Backend verifica `account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')` → cria mensagem como `content_type: "cards"`
  - Frontend vê `contentType === "cards"` → chama RichCards
  - RichCards renderiza diretamente (sem verificar flag novamente)
- **Para outros componentes** que precisam verificar flags: usar `useMapGetter('accounts/isFeatureEnabledonAccount')`:

  ```vue
  <script setup>
  import { useMapGetter } from 'dashboard/composables/store.js';

  const isFeatureEnabledOnAccount = useMapGetter(
    'accounts/isFeatureEnabledonAccount'
  );
  const currentAccountId = useMapGetter('getCurrentAccountId');

  const isRichDashboardEnabled = computed(() => {
    if (!currentAccountId.value || !isFeatureEnabledOnAccount.value) {
      return false;
    }
    return isFeatureEnabledOnAccount.value(
      currentAccountId.value,
      'SOCIALWISE_RICH_DASHBOARD'
    );
  });
  </script>
  ```

- **Evitar**: `window.globalConfig` para feature flags (pode não estar sincronizado com account-specific flags).

### Bus/Eventos

- Usar `emitter.emit(BUS_EVENTS.RICH_POSTBACK, { … })`
- Definir handlers na camada de conversa para tratar postbacks sem recarregar a UI.

### Tailwind

- Somente utilitários; sem `scoped`/CSS manual
- Classes úteis em cards: container com `max-w-sm`, títulos/descrições com `line-clamp-[2|3]` (webkit), botões com `rounded-md`, `transition-colors`, etc.

---

## Build de Frontend (Vite) — Armadilhas & Fixes

- **`::v-deep` deprecado** → usar `:deep(<selector>)`.
- **Dart Sass**: evitar **legacy JS API**; mantenha as versões atualizadas (ou aceite warnings por enquanto).
- **Funções de cor Sass**: `darken()` deprecado → use `color.scale($color, $lightness: -X%)` ou `color.adjust()`.
- **CRÍTICO - Erro**: `import.meta may appear only with 'sourceType: "module"'` → causado por usar `import.meta` **dentro do template** (ex.: handlers inline como `@load="() => import.meta.env.MODE !== 'production' && console.log(...)"`).

  **Solução completa**:

  ```vue
  <script setup>
  // ✅ Defina uma vez no script
  const isDev = import.meta.env.MODE !== 'production';

  // ✅ Crie métodos que usam a constante
  const handleImageLoad = src => {
    if (isDev) {
      console.log('[RichCards] Image loaded successfully:', src);
    }
  };
  </script>

  <template>
    <!-- ✅ Use o método no template -->
    <img @load="handleImageLoad(item.media_url || item.mediaUrl)" />
  </template>
  ```

- **Performance**: Avaliar `import.meta.env.MODE` uma vez é mais eficiente que múltiplas avaliações inline.

---

## Docker / Assets Precompile (Rails)

- Ao rodar `rake assets:precompile` em **RAILS_ENV=production**, todas as gems requeridas precisam estar instaladas no container.
- **Erro comum**: `Bundler::GemNotFound: Could not find gem 'stackprof'`

  - Garanta que `Gemfile` tenha `stackprof` em um grupo compatível com o ambiente do build (se só dev/test, o build de produção não deve exigir).
  - Execute `bundle lock` e **commit** do `Gemfile.lock`.

- **Windows vs Linux**: gems com **native extensions** (ex.: `io-console`, `stackprof`) podem falhar no Windows (MSYS2/devkit). Priorize build em Linux (Docker) e, no Windows, instale Ruby+Devkit adequados.

---

## Checklists Antiflicker

1. **Feature flag** `SOCIALWISE_RICH_DASHBOARD` **ativada** no Account.
2. **Processor** cria a mensagem **diretamente** como `content_type: 'cards'`/`input_select` com `content_attributes` completos.
3. **Service** verifica `message_already_rich?` e **pula** `mirror_rich_payload_to_dashboard` quando já for rico.
4. UI (RichCards/QuickReplies) condiciona a renderização à presença de `items` + flag no `globalConfig` quando aplicável.
5. Imagem com altura fixa para evitar _layout shift_; `@error` esconde imagem quebrada.
6. Logs esperados:

   - Backend: _“Message already created as rich cards, skipping mirroring”_
   - Frontend: `render_success`, `Image loaded successfully`.

---

## Observabilidade SocialWise Flow - ATUALIZADA 2025

### Padrão de Logs Estruturados

**Prefixos por Integração**:
- `[SOCIALWISE-FLOW]`: Processador principal multi-canal
- `[SOCIALWISE-FLOW-WHATSAPP]`: Processador especializado WhatsApp
- `[SOCIALWISE-INSTAGRAM-DIALOGFLOW]`: Processador Instagram/Dialogflow
- `[SOCIALWISE-INSTAGRAM-RICH]`: Service de rich messages Instagram

**Contexto Obrigatório**:
- **IDs de rastreamento**: message_id, conversation_id, account_id, inbox_id
- **Channel identification**: channel_type, provider info
- **Payload data**: tamanho, formato, conteúdo (truncado se necessário)
- **Timing info**: timestamps ISO8601, duração em ms
- **Error context**: backtrace, classe de erro, contexto completo

### Métricas de Performance

**Backend**:
```ruby
Rails.logger.info "[SOCIALWISE-FLOW] Total processing time: #{duration}ms"
Rails.logger.info "[SOCIALWISE-INSTAGRAM-RICH] API call duration: #{api_duration}ms"
```

**Frontend**:
```javascript
// Apenas em desenvolvimento
if (import.meta.env.MODE !== 'production') {
  console.log('[RichCards] Component rendered in:', performance.now() - startTime, 'ms');
}

// Métricas para analytics
trackMetric('cw_rich_cards_render_total', { 
  error: 'false', 
  type: 'success',
  message_id: id.value 
});
```

### Error Handling Resiliente

**Padrão de Fallback Gracioso**:
1. **Log error** com contexto completo
2. **Extract fallback content** do payload original
3. **Create simple message** como último recurso
4. **Continue processing** - não falha completamente
5. **Track metrics** para monitoramento

**Button Reactions**:
- Logs de emoji, text e action
- Diferenciação por canal (WhatsApp permite qualquer emoji, Instagram só 'love')
- Fallback para mensagem simples se reação falhar

---

## 🔧 Troubleshooting SocialWise Flow - ATUALIZADO 2025

### Problemas Comuns e Soluções

#### 1. Flash Effect Ainda Acontecendo

**Diagnóstico**:
1. ✅ Feature flag ativa? `Account.find(X).feature_enabled?('SOCIALWISE_RICH_DASHBOARD')`
2. ✅ Logs mostram "Message already created as rich cards, skipping mirroring"?
3. ✅ Frontend **não** está fazendo verificação dupla de flag?
4. ✅ Mensagem criada com `content_type: "cards"` no banco?

**Solução**:
```ruby
# Debug no Rails console
account = Account.find(ACCOUNT_ID)
account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD') # deve retornar true
```

#### 2. Rich Cards Não Aparecem

**Diagnóstico**:
1. ✅ Backend: `content_type` é "cards" no banco de dados?
2. ✅ Frontend: `Message.vue` chama `RichCards` baseado em `content_type`?
3. ✅ Component logs: `shouldRender: true`?
4. ✅ `contentAttributes.items` tem dados?

**Debug**:
```vue
<!-- No RichCards.vue -->
<script setup>
onMounted(() => {
  console.log('[RichCards] Debug info:', {
    shouldRender: shouldRenderRichCards.value,
    itemsCount: items.value.length,
    items: items.value
  });
});
</script>
```

#### 3. SocialWise Flow Não Responde

**Diagnóstico**:
1. ✅ URL correta em `hook.settings['socialwise_flow_url']`?
2. ✅ Authorization token configurado?
3. ✅ Account tem integração SocialWise ativa?
4. ✅ Logs `[SOCIALWISE-FLOW]` aparecem?

**Debug**:
```ruby
# Verificar configuração
hook = Hook.find(HOOK_ID)
hook.settings['socialwise_flow_url'] # deve ter URL
hook.settings['access_token'] # deve ter token
```

#### 4. Button Reactions Falhando

**WhatsApp**: Aceita qualquer emoji
**Instagram**: Apenas 'love' é suportado

**Debug**:
```
[SOCIALWISE-FLOW] Button ID: button_123
[SOCIALWISE-FLOW] Emoji: ❤️ (WhatsApp) ou love (Instagram)
[SOCIALWISE-FLOW] Action: handoff
```

#### 5. WebhookEnhancer Não Enriquece

**Verificar**:
1. ✅ `socialwise_active?(account)` retorna true?
2. ✅ `webhook_enhancement_enabled?(account)` ativo?
3. ✅ Cache invalidado após mudanças?

**Solução**:
```ruby
# Limpar cache
Integrations::Socialwise::WebhookEnhancerService.clear_provider_config_cache(account_id)
```

### Build Errors (Vite & Frontend)

#### Erro Crítico: `import.meta may appear only with 'sourceType: "module"'`

**Causa**: Usar `import.meta` diretamente em templates Vue.

**❌ Problemático**:
```vue
<template>
  <img @load="() => import.meta.env.MODE !== 'production' && console.log('loaded')" />
</template>
```

**✅ Solução**:
```vue
<script setup>
const isDev = import.meta.env.MODE !== 'production';
const handleImageLoad = () => {
  if (isDev) console.log('Image loaded');
};
</script>
<template>
  <img @load="handleImageLoad" />
</template>
```

### Docker Build Issues

**Gem não encontrada** (`stackprof`, `io-console`):
- ✅ Garantir que `Gemfile.lock` está commitado
- ✅ Build em ambiente Linux (Docker)
- ✅ Verificar grupos de gems (`development`, `test`, `production`)

### Feature Flags Debug

**Rails Console**:
```ruby
# Verificar flag global
feature = InstallationConfig.find_by(name: 'FEATURE_SOCIALWISE_RICH_DASHBOARD')

# Verificar flag por account
account = Account.find(3)
account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')

# Habilitar se necessário
account.account_features.find_or_create_by(feature_name: 'SOCIALWISE_RICH_DASHBOARD').update!(enabled: true)
```

---

## 💻 Snippets Úteis - SocialWise Flow

### Backend (Ruby)

**Criação direta de mensagem rica**:
```ruby
# Em InstagramResponseProcessor ou similar
def create_rich_outgoing_message(conversation, instagram_payload, original_payload)
  account = conversation.account
  if account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')
    create_rich_message_directly(conversation, instagram_payload, original_payload)
  else
    # Fallback para fluxo normal
    create_regular_message(conversation, original_payload)
  end
end

def create_rich_message_directly(conversation, instagram_payload, original_payload)
  mapped_result = Messages::InstagramRendererMapper.map(instagram_payload)
  
  conversation.messages.create!(
    content: mapped_result.fallback_text,
    content_type: mapped_result.content_type,
    content_attributes: mapped_result.content_attributes,
    message_type: :outgoing,
    account_id: conversation.account_id,
    inbox_id: conversation.inbox_id,
    additional_attributes: { skip_send_reply: true }
  )
end
```

**Button Reaction Handler**:
```ruby
def process_button_reaction(message, response)
  conversation = message.conversation
  channel_type = conversation.inbox.channel_type
  
  # Enviar emoji específico por canal
  if response['emoji'].present?
    send_emoji_reaction(message, response, channel_type)
  end
  
  # Enviar texto contextual
  if response['text'].present?
    send_reaction_text(message, response, channel_type)
  end
end
```


### Frontend (Vue 3)

**RichCards Component Pattern**:
```vue
<script setup>
import { computed, onMounted } from 'vue';
import { useMessageContext } from '../provider.js';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

const { contentAttributes, id } = useMessageContext();

const items = computed(() => contentAttributes.value?.items || []);

// IMPORTANTE: Não verificar feature flag aqui
const shouldRenderRichCards = computed(() => items.value.length > 0);

const isDev = import.meta.env.MODE !== 'production';

const handlePostback = (action) => {
  emitter.emit(BUS_EVENTS.RICH_POSTBACK, {
    messageId: id.value,
    payload: action.payload,
    text: action.text,
    timestamp: new Date().toISOString()
  });
};

const handleImageLoad = (src) => {
  if (isDev) {
    console.log('[RichCards] Image loaded:', src);
  }
};

const handleImageError = (event) => {
  if (isDev) {
    console.error('[RichCards] Image failed:', event.target.src);
  }
  event.target.style.display = 'none';
};
</script>

<template>
  <div v-if="shouldRenderRichCards" class="rich-cards-container">
    <div
      v-for="(card, index) in items"
      :key="index"
      class="card max-w-sm bg-white rounded-lg shadow"
      :role="'group'"
      :aria-label="`Card ${index + 1}: ${card.title}`"
    >
      <img
        v-if="card.media_url || card.mediaUrl"
        :src="card.media_url || card.mediaUrl"
        :alt="card.title"
        class="w-full h-48 object-cover rounded-t-lg"
        loading="lazy"
        decoding="async"
        @load="handleImageLoad(card.media_url || card.mediaUrl)"
        @error="handleImageError"
      />
      
      <div class="p-4">
        <h3 class="font-semibold text-gray-900 line-clamp-2">
          {{ card.title }}
        </h3>
        
        <p v-if="card.description" class="text-gray-600 text-sm mt-2 line-clamp-3">
          {{ card.description }}
        </p>
        
        <div v-if="card.actions?.length" class="mt-4 space-y-2">
          <button
            v-for="(action, actionIndex) in card.actions"
            :key="actionIndex"
            class="w-full px-4 py-2 text-sm font-medium rounded-md transition-colors"
            :class="action.type === 'web_url' ? 'bg-blue-600 text-white hover:bg-blue-700' : 'bg-gray-100 text-gray-900 hover:bg-gray-200'"
            @click="action.type === 'postback' ? handlePostback(action) : window.open(action.url, '_blank')"
          >
            {{ action.text }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
```

**Feature Flag Check (quando necessário)**:
```vue
<script setup>
// ✅ Para componentes que precisam verificar flags (NÃO RichCards)
import { useMapGetter } from 'dashboard/composables/store.js';

const isFeatureEnabledOnAccount = useMapGetter('accounts/isFeatureEnabledonAccount');
const currentAccountId = useMapGetter('getCurrentAccountId');

const isRichDashboardEnabled = computed(() => {
  if (!currentAccountId.value || !isFeatureEnabledOnAccount.value) {
    return false;
  }
  return isFeatureEnabledOnAccount.value(
    currentAccountId.value,
    'SOCIALWISE_RICH_DASHBOARD'
  );
});
</script>
```

### Debug & Monitoring

**Rails Console Debug**:
```ruby
# Verificar feature flag
account = Account.find(3)
account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')

# Verificar mensagem rica
message = Message.find(12345)
message.content_type # deve ser "cards" para rich
message.content_attributes # deve ter structure completa

# Verificar cache SocialWise
Integrations::Socialwise::WebhookEnhancerService.socialwise_active?(account)

# Limpar cache se necessário
Integrations::Socialwise::WebhookEnhancerService.clear_provider_config_cache(account.id)
```

**Logs Structurados**:
```ruby
# Padrão de log para SocialWise Flow
Rails.logger.info "[SOCIALWISE-FLOW] === PROCESSING #{action.upcase} ==="
Rails.logger.info "[SOCIALWISE-FLOW] Message ID: #{message.id}, Conversation ID: #{conversation.id}"
Rails.logger.info "[SOCIALWISE-FLOW] Account ID: #{account.id}, Channel: #{channel_type}"
Rails.logger.info "[SOCIALWISE-FLOW] Payload: #{payload.inspect}"
```

---

## 🎯 Lições Críticas Aprendidas - Janeiro 2025

### ✅ Flash Effect - Problema RESOLVIDO

**Causa Raiz Identificada**: Dupla verificação de feature flag causava race condition:
1. Backend criava mensagem como "cards" ✅
2. Frontend verificava flag novamente ❌
3. Flash visível: texto → rich cards ❌

**Solução Implementada**: Single Source of Truth
- **Backend**: único responsável por verificar `SOCIALWISE_RICH_DASHBOARD`
- **Frontend**: RichCards confiam na decisão do backend
- **Service**: `message_already_rich?` previne mirroring desnecessário

### 🔄 SocialWise Flow - Arquitetura Multi-Canal

**Evolução do Sistema**:
- **Antes**: Instagram Processor isolado para Dialogflow
- **Agora**: SocialWise Flow unified processor para WhatsApp + Instagram + Facebook
- **Benefício**: Código reutilizável, logs padronizados, error handling consistente

**Button Reactions**: Feature diferenciadora
- WhatsApp: qualquer emoji + texto contextual
- Instagram: apenas 'love' + texto simples
- Handoff actions para transferência de conversa

### 📊 Observabilidade que Funciona

**Logs Estruturados Essenciais**:
```
[SOCIALWISE-FLOW] === PROCESSING RESPONSE ===
[SOCIALWISE-INSTAGRAM-RICH] Message already created as rich cards, skipping mirroring
[SOCIALWISE-FLOW-WHATSAPP] Interactive message created: 12345
```

**Métricas que Importam**:
- Tempo total de processamento (< 500ms ideal)
- Rate de fallback por canal (< 5% ideal)
- Flash effect occurrences (0 após fix)

### 🛠️ WebhookEnhancer - Performance Critical

**Cache Strategy**: Evita queries desnecessárias
- Provider config cached per account
- Invalidação automática em mudanças
- Preload de inboxes WhatsApp na inicialização

**Flat Structure**: Facilita consumo por webhooks externos
- Campos no root level (`contact_name`, `wamid`, etc.)
- Backward compatibility mantida
- Custom attributes merged transparently

### 🔧 Build & Deploy Learnings

**Vite Build**: `import.meta` em templates quebra build
- **Solução**: mover para `<script setup>` e usar variáveis

**Docker Assets**: Gems nativas quebram em Windows
- **Solução**: build sempre em Linux via Docker

**Feature Flags**: Account-specific vs global
- **CUIDADO**: usar `account.feature_enabled?()` no backend
- **EVITAR**: `window.globalConfig` para flags de account

### 📱 Frontend Performance

**Layout Shift Prevention**: Altura fixa em imagens (`h-48`)
**Error Resilience**: `@error` oculta imagens quebradas
**Dev Experience**: Logs apenas em development mode
**Accessibility**: `role`, `aria-label` em todos os interativos

---

## 🚀 Próximos Passos e Melhorias

### Performance Otimizations
- [ ] Lazy loading de componentes ricos
- [ ] Virtual scrolling para muitas mensagens
- [ ] Image optimization pipeline

### Observabilidade Avançada
- [ ] Métricas de engagement em rich cards
- [ ] Alertas automáticos para high fallback rates
- [ ] Dashboard de performance SocialWise Flow

### Feature Expansions
- [ ] Voice messages em rich cards
- [ ] Carousel templates para Instagram
- [ ] Persistent menu para WhatsApp

---

## 📚 Referências e Links Úteis

- **Instagram API**: https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/messaging-api
- **WhatsApp Business API**: https://developers.facebook.com/docs/whatsapp/cloud-api/
- **Vue 3 Composition API**: https://vuejs.org/api/composition-api-setup.html
- **Tailwind CSS**: https://tailwindcss.com/docs
- **Chatwit Internal Docs**: `/home/wital/chatwit/CLAUDE.md`

---

*Documento atualizado em Janeiro 2025 com base na implementação real do SocialWise Flow multi-canal.*

---

## Ruby — Dicas adicionais

- `pattr_initialize` para serviços com dependências explícitas
- Evitar callbacks complexos em models para não duplicar broadcasts
- `update_columns` com cuidado (bypass de callbacks) apenas quando **intencional** (ex.: mirroring)

---

## 🔧 Troubleshooting Comum

### Build Vite Falhando

- **Erro**: `import.meta may appear only with 'sourceType: "module"'`
- **Solução**: Mover `import.meta` do template para script
- **Exemplo**: Ver seção "Vite Build Fix" acima

### Flash Effect Ainda Acontecendo

1. **Verificar**: Feature flag está habilitada no super admin?
2. **Verificar**: Logs mostram "Message already created as rich cards, skipping mirroring"?
3. **Verificar**: Frontend não está fazendo verificação dupla de flag?
4. **Debug**: Adicionar logs no `create_rich_outgoing_message`

### Rich Cards Não Aparecem

1. **Backend**: Verificar se `content_type` é "cards" no banco
2. **Frontend**: Verificar se `Message.vue` está chamando `RichCards`
3. **Debug**: Logs do `onMounted` no RichCards mostram `shouldRender: true`?

### Feature Flag Não Funciona

- **Verificar**: Usar `account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')` no backend
- **Verificar**: Não usar `window.globalConfig` para flags account-specific
- **Debug**: Testar no Rails console: `Account.find(X).feature_enabled?('SOCIALWISE_RICH_DASHBOARD')`

---

## Como validar que está 100% sem flicker

- No backend, procurar por:

  - **Um único** `message.created` com `content_type: 'cards'`.
  - Log: _“Message already created as rich cards, skipping mirroring”_.

- No frontend:

  - Primeiro log do `onMounted`: `shouldRender: true`, `isEnabled: true` e `items.length > 0`.
  - Em seguida, log do `@load` da imagem confirmando carregamento, **sem** aparecer uma bolha de texto antes.

---

## 🎯 FLASH EFFECT FIX - Lições Críticas (Janeiro 2025)

### Problema Resolvido: Flash Effect Eliminado ✅

**CONTEXTO**: Mensagens apareciam como texto primeiro, depois mudavam para rich cards (flash visível).

**CAUSA RAIZ**: Dupla verificação de feature flag causava race condition:

1. Backend: `account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')` → cria como `"cards"` ✅
2. Frontend: RichCards verificava flag novamente → mostrava fallback enquanto carregava ❌
3. Flag carregava → mudava para rich cards ❌
4. **Resultado**: Flash visível texto → cards

### Solução Implementada: Single Source of Truth

**PRINCÍPIO**: Apenas backend verifica feature flag. Frontend confia na decisão.

**Backend** (`lib/integrations/socialwise/instagram_response_processor.rb`):

```ruby
def create_rich_outgoing_message(conversation, instagram_payload, original_payload)
  account = conversation.account
  rich_dashboard_enabled = account.feature_enabled?('SOCIALWISE_RICH_DASHBOARD')

  if rich_dashboard_enabled
    # ✅ Criar diretamente como rica - sem flash!
    create_rich_message_directly(conversation, instagram_payload, original_payload)
  else
    # Fallback para texto normal
    create_text_message(conversation, original_payload)
  end
end

def create_rich_message_directly(conversation, instagram_payload, original_payload)
  mapped_result = Messages::InstagramRendererMapper.map(instagram_payload)

  conversation.messages.create!(
    content: mapped_result.fallback_text,
    content_type: mapped_result.content_type,           # "cards"
    content_attributes: mapped_result.content_attributes, # Rich content
    message_type: :outgoing,
    account_id: conversation.account_id,
    inbox_id: conversation.inbox_id,
    additional_attributes: { skip_send_reply: true }
  )
end
```

**Service** (`app/services/instagram/rich_message_service.rb`):

```ruby
def mirror_rich_payload_to_dashboard
  return unless rich_dashboard_enabled?

  # ✅ Pular se mensagem já foi criada como rica
  if message_already_rich?
    Rails.logger.info "Message already created as rich cards, skipping mirroring"
    return
  end

  # Apenas para mensagens criadas como texto
  # ... resto do mirroring
end

def message_already_rich?
  rich_content_types = %w[cards input_select]
  rich_content_types.include?(message.content_type)
end
```

**Frontend** (`app/javascript/dashboard/components-next/message/bubbles/RichCards.vue`):

```vue
<script setup>
// ✅ Removido verificação de feature flag
// Se este componente foi chamado, backend já verificou
const shouldRenderRichCards = computed(() => {
  return items.value.length > 0;
});
</script>
```

### Vite Build Fix: import.meta em Templates

**ERRO**: `import.meta may appear only with 'sourceType: "module"'`
**CAUSA**: Usar `import.meta.env.MODE` diretamente em template Vue

```vue
<!-- ❌ QUEBRA O BUILD -->
<img @load="() => import.meta.env.MODE !== 'production' && console.log(...)" />

<!-- ✅ SOLUÇÃO -->
<script setup>
const isDev = import.meta.env.MODE !== 'production';

const handleImageLoad = src => {
  if (isDev) {
    console.log('[RichCards] Image loaded successfully:', src);
  }
};
</script>

<template>
  <img @load="handleImageLoad(item.media_url || item.mediaUrl)" />
</template>
```

### Feature Flags: Padrão Correto

**❌ EVITAR**: Verificação dupla de flags

```vue
<!-- Não fazer isso em RichCards -->
const isRichDashboardEnabled = computed(() => { return
isFeatureEnabledOnAccount.value(currentAccountId.value,
'SOCIALWISE_RICH_DASHBOARD'); });
```

**✅ USAR**: Para outros componentes que precisam verificar flags:

```vue
<script setup>
import { useMapGetter } from 'dashboard/composables/store.js';

const isFeatureEnabledOnAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);
const currentAccountId = useMapGetter('getCurrentAccountId');

const isRichDashboardEnabled = computed(() => {
  if (!currentAccountId.value || !isFeatureEnabledOnAccount.value) {
    return false;
  }
  return isFeatureEnabledOnAccount.value(
    currentAccountId.value,
    'SOCIALWISE_RICH_DASHBOARD'
  );
});
</script>
```

### Arquitetura Final: Sem Flash

```
✅ FLUXO CORRETO (sem flash):
1. Backend: Verifica flag → Cria como "cards" → Broadcast message.created
2. Frontend: Message.vue vê contentType="cards" → Chama RichCards
3. RichCards: Renderiza imediatamente (confia no backend)
4. Resultado: Rich cards aparecem diretamente - ZERO flash! 🎉
```

### Logs de Sucesso

**Backend**:

```
[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Creating message directly as rich cards
[SOCIALWISE-INSTAGRAM-DIALOGFLOW] Created rich message directly with ID: 12345
[SOCIALWISE-INSTAGRAM-RICH] Message already created as rich cards, skipping mirroring
```

**Frontend**:

```
[RichCards] Component mounted: {messageId: 33687, shouldRender: true}
[RichCards] Image loaded successfully: https://...
```

---

> **Status atual:** Flash effect **ELIMINADO** ✅ — Criação direta como **cards** + renderização Vue instantânea + build Vite funcionando + feature flags nativos do Chatwoot integrados.
