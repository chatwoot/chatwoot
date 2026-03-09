# CLAUDE.md

Este arquivo é a fonte única da verdade para o desenvolvimento no repositório **Chatwit**, um fork do Chatwoot. Ele orienta o desenvolvimento, detalha a arquitetura, consolida diretrizes de código e registra as lições aprendidas.

## 1\. Visão Geral do Produto

Chatwit é uma plataforma de suporte ao cliente de código aberto, alternativa a serviços como Intercom e Zendesk. Ela centraliza conversas de múltiplos canais (live chat, email, redes sociais, WhatsApp, etc.) em uma única interface, projetada para implantações auto-hospedadas (self-hosted) e em nuvem.

-----

## 2\. Arquitetura e Estrutura do Projeto

O projeto segue uma arquitetura modular orientada a serviços, com uma clara separação entre a lógica de negócios, canais de comunicação e integrações.

### Stack de Tecnologia

  - **Backend**: Ruby 3.4.4, Rails 7.1+
  - **Frontend**: Vue 3, Vite, TypeScript, pnpm
  - **Banco de Dados**: PostgreSQL com extensão `pgvector`
  - **Cache & Filas**: Redis e Sidekiq
  - **Testes**: RSpec (Ruby) e Vitest (JavaScript/Vue)
  - **Estilização**: Tailwind CSS

### Estrutura de Diretórios

  - `app/controllers/`: Endpoints de API e webhooks.
  - `app/models/`: Lógica de negócios principal com ActiveRecord.
  - `app/services/`: Camada de serviços onde a lógica de negócios complexa reside.
  - `app/jobs/`: Tarefas assíncronas processadas pelo Sidekiq.
  - `app/javascript/`: Código do frontend.
      - `dashboard/`: Interface principal do agente (Vue).
      - `widget/`: Widget de chat para o cliente.
      - `portal/`: Portal do Help Center.
  - `lib/integrations/`: Código para integrações com serviços de terceiros.
  - `enterprise/`: Funcionalidades específicas da versão Enterprise.

-----

## 3\. Ambiente de Desenvolvimento e Comandos

O uso de Docker é o padrão para garantir consistência entre desenvolvimento e produção.

### Configuração e Execução

```bash
# Instalar todas as dependências
bundle install && pnpm install

# Configurar o banco de dados
bundle exec rails db:create db:migrate db:seed

# Iniciar o ambiente de desenvolvimento com Docker
docker-compose up

# Iniciar localmente com Overmind (alternativa)
overmind start -f Procfile.dev
```

### Testes

#### Testes JavaScript/Vue

```bash
pnpm test          # Executar uma vez
pnpm run test:watch    # Modo de observação (watch)
```

#### Testes Ruby (RSpec)

```bash
# Executando via Docker a partir do seu terminal host (padrão)
docker exec chatwit-dev-rails-1 bundle exec rspec
docker exec chatwit-dev-rails-1 bundle exec rspec spec/models/user_spec.rb # Arquivo específico
docker exec chatwit-dev-rails-1 bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER # Teste específico
```

### Linting e Qualidade de Código

```bash
# JavaScript/Vue
pnpm run eslint      # Verificar
pnpm run eslint:fix  # Corrigir automaticamente

# Ruby (via Docker)
docker exec chatwit-dev-rails-1 bundle exec rubocop -a # Corrigir automaticamente
```

-----

## 4\. Padrões e Diretrizes de Desenvolvimento

### Princípios Gerais

  - **MVP Primeiro**: Foque na menor diferença de código para entregar valor e itere após validação.
  - **Simplicidade**: Sem defensivismo desnecessário.
  - **Código Limpo**: Remova código morto/não utilizado. Não mantenha duas abordagens para a mesma lógica.
  - **Tarefas Granulares**: Divida tarefas grandes em unidades pequenas e testáveis.
  - **Specs**: Não escrever specs salvo pedido explícito.
  - **Commits**: Não referenciar outros AIs em mensagens de commit.

### Estilo de Código

  - **Ruby**: Siga o RuboCop (largura de linha máx. \~150).
  - **Vue/JS**: Siga o ESLint (padrão Airbnb + Vue 3).
  - **Nomenclatura**:
      - Componentes Vue: `PascalCase`
      - Eventos: `camelCase`
  - **Vue 3**: Sempre use a Composition API com `<script setup>`.
  - **Internacionalização (i18n)**: **Sem strings "nuas"** em templates; use sempre as funções de i18n.
  - **Segurança e Validações**:
      - **Models**: Valide presença/unicidade e garanta os índices corretos no DB.
      - **Type Safety**: Use Props tipadas no Vue e `strong_params` no Rails.
  - **Erros**: Use exceções customizadas de `lib/custom_exceptions/`.

### Estilização (Styling)

  - **Tailwind CSS Apenas**:
      - Não escreva CSS customizado.
      - Não use o atributo `scoped` em componentes Vue.
      - Não use estilos inline (salvo correções pontuais de acessibilidade).
      - Utilize as classes utilitárias e os tokens de cor definidos em `tailwind.config.js`.

### Dicas Adicionais (Ruby)

  - **`pattr_initialize`**: Use para serviços com dependências explícitas.
  - **Callbacks**: Evite callbacks complexos em models para não duplicar broadcasts.
  - **`update_columns`**: Use com cuidado, pois ignora callbacks e validações. Apenas quando for intencional (ex: espelhamento de dados).

-----

## 5\. Integrações SocialWise

### SocialWise Flow Integration

**Processador Principal**: `Integrations::SocialwiseFlow::ProcessorService`
  - Herda de `Integrations::BotProcessorService` 
  - Processa mensagens de diferentes canais (WhatsApp, Instagram, Facebook)
  - Suporte a reações com botões (`button_reaction`) e handoff
  - **Logs estruturados**: prefixo `[SOCIALWISE-FLOW]` com contexto completo

**Fluxo Multi-Canal**:
1. Recebe payload do evento
2. Constrói request enriquecido via `WebhookEnhancerService`
3. Rota por tipo de canal (`Channel::Whatsapp`, `Channel::FacebookPage`)
4. Delega para processadores especializados:
   - WhatsApp → `WhatsappResponseProcessor`
   - Instagram → `InstagramResponseProcessor` 
   - Facebook → processamento direto
5. Fallback gracioso em caso de erros

**Tratamento de Erros Resiliente**:
  - Logs detalhados com IDs de rastreamento
  - Fallback messages quando processamento falha
  - Continuidade do fluxo mesmo com falhas parciais
  - Separação entre falhas de envio e criação de mensagem

### Configuração de Canais

**WhatsApp Setup** (`Whatsapp.vue`):
  - Suporte múltiplos provedores: Cloud, Twilio, 360Dialog
  - Componentes especializados por provedor
  - Seleção via dropdown com i18n

### Tipos de Mensagens Ricas Suportadas

**Button Reactions** (`button_reaction`):
  - Envio de emoji como reação
  - Texto contextual de resposta
  - Suporte a handoff actions
  - Diferenciação por canal (WhatsApp vs Instagram)

**WhatsApp Rich Messages**:
  - Templates interativos
  - Quick replies
  - Buttons com postback/web_url
  - Processado via `WhatsappResponseProcessor`

**Instagram Rich Messages**:
  - `GENERIC_TEMPLATE`: Cards com imagens, títulos, botões
  - `BUTTON_TEMPLATE`: Texto com botões de ação
  - `QUICK_REPLIES`: Respostas rápidas
  - Anti-flicker: criação direta como rich content

**Facebook Messages**:
  - Rich content via `content_type: 'integrations'`
  - Fallback para texto simples
  - Validação de recipient ID

-----

## 6\. Deep Dive: Instagram Rich Messages (Anti-Flicker)

Esta seção detalha a implementação da feature e as lições aprendidas para evitar o efeito de "flicker".

### Fluxo Backend

  - **Processor (`Integrations::Socialwise::InstagramResponseProcessor`)**:

    1.  Valida o payload do Dialogflow (`GENERIC_TEMPLATE`, `BUTTON_TEMPLATE`, etc.).
    2.  Se a feature flag `SOCIALWISE_RICH_DASHBOARD` estiver **ativa**, cria a mensagem no banco de dados **diretamente** com `content_type: "cards"` e os atributos já mapeados.
    3.  Chama o `Instagram::RichMessageService` para enviar a mensagem à API do Instagram.

  - **Service (`Instagram::RichMessageService`)**:

    1.  Envia o payload para a API do Instagram.
    2.  **Verifica se a mensagem já foi criada como rica (`message_already_rich?`)**. Se sim, **pula o espelhamento** para o dashboard para evitar duplicidade e logs: `“Message already created as rich cards, skipping mirroring”`.

### Validações de Payload (Resumo)

  - **GENERIC\_TEMPLATE**: 1 a 10 `elements`; `title` obrigatório (≤ 80 chars); máx. 3 botões por elemento.
  - **BUTTON\_TEMPLATE**: `text` obrigatório (≤ 2000 chars); 1 a 3 botões.
  - **QUICK\_REPLIES**: `text` obrigatório (≤ 1000 chars); 1 a 13 opções; `title` (≤ 20 chars).
  - **Botões**: `postback` requer `payload`; `web_url` requer uma URL válida.

### Componentização Frontend (`RichCards.vue` e `QuickReplies.vue`)

  - **Local**: `app/javascript/dashboard/components-next/message/bubbles/`
  - **Princípio Chave**: **NÃO verifique a feature flag** dentro desses componentes. A decisão de renderizá-los já foi tomada pelo backend ao definir o `content_type`.
  - **`RichCards.vue`**:
      - Lê `contentAttributes.items` para renderizar os cards.
      - **Layout Shift**: Reserve espaço para a imagem para evitar que o layout "pule" (`class="w-full h-48 object-cover"`).
      - **Performance**: Use `loading="lazy"` e `decoding="async"` nas imagens.
      - **Acessibilidade**: Use `role="group"` e `aria-label` para cada card.
  - **`QuickReplies.vue`**:
      - Lê `contentAttributes.items` para renderizar os botões.
      - Emite o evento `BUS_EVENTS.RICH_POSTBACK` ao ser clicado.
      - **Acessibilidade**: Use `role="button"` e `:aria-label`.

### Observabilidade e Logs Centralizados

**Padrão de Logs Estruturados**:
  - **Prefixos por Integração**: `[SOCIALWISE-FLOW]`, `[SOCIALWISE-INSTAGRAM-…]`
  - **IDs de Rastreamento**: message_id, conversation_id, account_id, inbox_id
  - **Context Completo**: channel_type, payload, backtrace em erros
  - **Níveis Apropriados**: INFO para fluxo, WARN para fallbacks, ERROR para falhas

**Frontend**:
  - `console.log` **apenas em desenvolvimento**: `import.meta.env.MODE !== 'production'`
  - Métricas de renderização: `trackMetric('cw_rich_cards_render_total')`
  - Eventos de erro capturados via `onErrorCaptured`

**Debugging**:
  - Button reactions: logs de emoji, text e action
  - Fallback tracking: extração de conteúdo e criação de mensagens
  - Channel validation: verificação de compatibilidade

**Error Handling Pattern**:
  - Captura erros em cada etapa do processamento
  - Log detalhado com contexto completo
  - Fallback gracioso: create_conversation com texto extraído
  - Separação entre falhas críticas e não-críticas
  - Continue processamento mesmo com falhas parciais

-----

## 7\. Build, Deploy e Troubleshooting

### Armadilhas e Soluções (Vite & Frontend)

  - **`::v-deep` Deprecado**: Use a sintaxe `:deep(<seletor>)` em seu lugar.

  - **Funções de Cor Sass**: `darken()` está deprecado. Use `color.scale($color, $lightness: -X%)`.

  - **CRÍTICO - Erro de Build `import.meta`**:

      - **Erro**: `import.meta may appear only with 'sourceType: "module"'`.
      - **Causa**: Usar `import.meta` diretamente em templates Vue (ex: em um handler `@click`).
      - **Solução**: Mova a lógica para a seção `<script setup>`, armazene o valor em uma constante e use a constante ou uma função no template.

    <!-- end list -->

    ```vue
    <script setup>
      const isDev = import.meta.env.MODE !== 'production';
      const handleImageLoad = () => {
        if (isDev) { console.log('Imagem carregada'); }
      };
    </script>
    <template>
      <img @load="handleImageLoad" />
    </template>
    ```

### Docker e Assets (Rails)

  - **Erro de Gem Não Encontrada**: `Bundler::GemNotFound: Could not find gem 'stackprof'`.
      - **Causa**: A gem está em um grupo (ex: `development`, `test`) que não é instalado no ambiente de `production` onde `assets:precompile` é executado.
      - **Solução**: Garanta que o `Gemfile` esteja correto e o `Gemfile.lock` seja commitado. A build deve ocorrer em um ambiente Linux (Docker) para evitar problemas de compilação de extensões nativas no Windows.

### Checklist de Troubleshooting

  - **Flicker Effect Ainda Acontecendo?**
    1.  A feature flag `SOCIALWISE_RICH_DASHBOARD` está habilitada para a conta?
    2.  Os logs do backend mostram a mensagem `skipping mirroring`?
    3.  O componente Vue **não** está fazendo uma verificação dupla da flag?
  - **Rich Cards Não Aparecem?**
    1.  O `content_type` da mensagem no banco de dados é `cards`?
    2.  O componente `Message.vue` está corretamente chamando o `RichCards.vue` com base no `content_type`?
  - **Feature Flag Não Funciona?**
    1.  **Backend**: A verificação `account.feature_enabled?('...')` está sendo usada?
    2.  **Frontend**: O composable `useMapGetter` está sendo usado? **NÃO** use `window.globalConfig` para flags de conta.
    3.  **Debug**: Verifique no Rails console: `Account.find(ID).feature_enabled?('...')`.