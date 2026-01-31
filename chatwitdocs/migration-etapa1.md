# Migration Etapa 1 - SocialWise Flow Integration

**Data:** 2026-01-30
**Versão Base:** Chatwoot 4.10.1
**Objetivo:** Integrar o SocialWise Flow (motor de fluxo com debounce e concatenação de mensagens)

---

## Resumo da Etapa 1

Esta etapa focou exclusivamente na **integração do SocialWise Flow** para o envio/recebimento de mensagens via webhook, com suporte a debounce e concatenação de mensagens.

### Escopo Realizado

- [x] Integração do fluxo de envio/recebimento de mensagens (WhatsApp/Instagram/Messenger)
- [x] Debounce de mensagens com Redis
- [x] Enriquecimento de payload de webhook
- [x] Suporte a mensagens ricas (cards, botões, quick replies)

### Escopo Pendente (Etapa 2)

- [ ] Configuração de rotas e frontend de Stickers
- [ ] Melhorias de UI no dashboard

---

## Arquivos Modificados

### 1. Gemfile
**Caminho:** `Gemfile`
**Alteração:** Adicionada gem `httparty` para requisições HTTP

```ruby
gem 'httparty'
```

### 2. Redis Keys
**Caminho:** `lib/redis/redis_keys.rb`
**Alteração:** Adicionadas constantes para debounce do SocialWise

```ruby
## SocialWise Flow Debounce Keys
SOCIALWISE_DEBOUNCE_MESSAGES = 'SOCIALWISE_DEBOUNCE::%<conversation_id>d::MESSAGES'.freeze
SOCIALWISE_DEBOUNCE_FIRST_AT = 'SOCIALWISE_DEBOUNCE::%<conversation_id>d::FIRST_AT'.freeze
SOCIALWISE_DEBOUNCE_LAST_AT = 'SOCIALWISE_DEBOUNCE::%<conversation_id>d::LAST_AT'.freeze
SOCIALWISE_DEBOUNCE_LOCK = 'SOCIALWISE_DEBOUNCE::%<conversation_id>d::LOCK'.freeze
```

### 3. Hook Listener
**Caminho:** `app/listeners/hook_listener.rb`
**Alteração:** Adicionado `socialwise_chatwit` ao mapa de eventos suportados

```ruby
'socialwise_chatwit' => ['message.created', 'message.updated']
```

### 4. Hook Job
**Caminho:** `app/jobs/hook_job.rb`
**Alteração:** Adicionado processamento do SocialWise Flow

```ruby
when 'socialwise_chatwit'
  process_socialwise_flow_integration(hook, event_name, event_data)
```

### 5. Routes
**Caminho:** `config/routes.rb`
**Alteração:** Adicionada rota do SocialWise no namespace integrations

```ruby
resource :socialwise_chatwit, controller: 'socialwise_chatwit', only: [:create, :update, :destroy]
```

### 6. Integration Apps Config
**Caminho:** `config/integration/apps.yml`
**Alteração:** Adicionada configuração completa do app socialwise_chatwit

### 7. Locales
**Caminho:** `config/locales/en.yml`
**Alteração:** Adicionadas traduções do SocialWise Flow

### 8. Inbox Model
**Caminho:** `app/models/inbox.rb`
**Alteração:** Incluído concern `SocialwiseCacheInvalidation`

### 9. Account Model
**Caminho:** `app/models/account.rb`
**Alteração:** Adicionada associação `has_many :account_feature_flags`

---

## Arquivos Criados

### Jobs
| Arquivo | Descrição |
|---------|-----------|
| `app/jobs/socialwise_debounce_job.rb` | Job para processar mensagens com debounce |

### Controllers
| Arquivo | Descrição |
|---------|-----------|
| `app/controllers/api/v1/accounts/integrations/socialwise_chatwit_controller.rb` | Controller da integração |

### Services - SocialWise Flow
| Arquivo | Descrição |
|---------|-----------|
| `lib/integrations/socialwise_flow/processor_service.rb` | Serviço principal do SocialWise Flow |
| `lib/integrations/socialwise_flow/debounce_processor_service.rb` | Serviço de processamento de debounce |
| `lib/integrations/socialwise_flow/whatsapp_response_processor.rb` | Processador de respostas WhatsApp |

### Services - SocialWise Core
| Arquivo | Descrição |
|---------|-----------|
| `lib/integrations/socialwise/webhook_enhancer_service.rb` | Enriquecedor de payload de webhook |
| `lib/integrations/socialwise/cache_manager.rb` | Gerenciador de cache |
| `lib/integrations/socialwise/instagram_response_processor.rb` | Processador de respostas Instagram |

### Services - Messages
| Arquivo | Descrição |
|---------|-----------|
| `app/services/messages/instagram_renderer_mapper.rb` | Mapper para mensagens ricas do Instagram |
| `app/services/instagram/rich_message_service.rb` | Serviço de mensagens ricas do Instagram |

### Models
| Arquivo | Descrição |
|---------|-----------|
| `app/models/account_feature_flag.rb` | Modelo para feature flags por conta |
| `app/models/concerns/socialwise_cache_invalidation.rb` | Concern de invalidação de cache |

### Initializers
| Arquivo | Descrição |
|---------|-----------|
| `config/initializers/socialwise_cache.rb` | Inicializador de preload de cache |

### Assets
| Arquivo | Descrição |
|---------|-----------|
| `public/dashboard/images/integrations/socialwise.png` | Logo do SocialWise |
| `public/dashboard/images/integrations/socialwise-dark.png` | Logo dark do SocialWise |

---

## Migrações Necessárias

### Migration Copiada
| Arquivo | Descrição |
|---------|-----------|
| `db/migrate/20250101000001_create_account_feature_flags.rb` | Cria tabela de feature flags por conta |

### Executar Migration
```bash
bundle exec rails db:migrate
```

---

## Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `SOCIALWISE_DEBOUNCE_MS` | Tempo de debounce em milissegundos | `0` (desabilitado) |
| `SOCIALWISE_DEBOUNCE_MAX_MS` | Timeout máximo do debounce em ms | `30000` |
| `SKIP_SOCIALWISE_CACHE` | Desabilita preload de cache | `false` |

---

## Comandos Pós-Instalação

```bash
# 1. Instalar dependências Ruby
bundle install

# 2. Instalar dependências Node
pnpm install

# 3. Executar migrações
bundle exec rails db:migrate

# 4. Reiniciar serviços
overmind restart
```

---

## Como Ativar a Integração

1. Acesse o painel do Chatwoot
2. Vá em **Settings > Integrations**
3. Encontre **SocialWise Flow**
4. Clique em **Connect**
5. Configure as opções:
   - **Enabled:** Ativar/desativar a integração
   - **Endpoint URL:** URL do webhook (deixe vazio para usar padrão)
   - **Access Token:** Token de autenticação (opcional)
   - **Language:** Código do idioma (ex: pt-BR)
   - **Webhook Enhancement:** Enriquecer payloads com dados SocialWise

---

## Fluxo de Funcionamento

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Mensagem       │────▶│  Hook Listener   │────▶│  Hook Job       │
│  Recebida       │     │  (message.created)│     │                 │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                          │
                                                          ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Webhook        │◀────│  Processor       │◀────│  Debounce       │
│  SocialWise     │     │  Service         │     │  (se habilitado)│
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                          │
                                                          ▼
                        ┌──────────────────┐     ┌─────────────────┐
                        │  Mensagem        │◀────│  Response       │
                        │  de Resposta     │     │  Processor      │
                        └──────────────────┘     └─────────────────┘
```

---

## Estrutura de Diretórios

```
lib/integrations/
├── socialwise/
│   ├── cache_manager.rb
│   ├── instagram_response_processor.rb
│   └── webhook_enhancer_service.rb
└── socialwise_flow/
    ├── debounce_processor_service.rb
    ├── processor_service.rb
    └── whatsapp_response_processor.rb

app/
├── controllers/api/v1/accounts/integrations/
│   └── socialwise_chatwit_controller.rb
├── jobs/
│   └── socialwise_debounce_job.rb
├── models/
│   ├── account_feature_flag.rb
│   └── concerns/
│       └── socialwise_cache_invalidation.rb
└── services/
    ├── instagram/
    │   └── rich_message_service.rb
    └── messages/
        └── instagram_renderer_mapper.rb
```

---

## Problemas Conhecidos e Soluções

### 1. Cache não atualiza após editar inbox
**Solução:** O concern `SocialwiseCacheInvalidation` foi adicionado ao modelo Inbox para limpar o cache automaticamente.

### 2. HTTParty não encontrado
**Solução:** Execute `bundle install` para instalar a gem.

### 3. Migration falha
**Solução:** Verifique se a versão do Rails é compatível (7.0+) e execute `bundle exec rails db:migrate:status` para verificar o status.

---

## Próximos Passos (Etapa 2)

1. **Stickers**
   - Adicionar rotas de stickers
   - Configurar frontend
   - Implementar upload e envio

2. **UI/UX**
   - Melhorar interface de configuração
   - Adicionar logs visuais
   - Dashboard de métricas

---

## Contato

Para dúvidas ou problemas, abra uma issue no repositório ou entre em contato com a equipe de desenvolvimento.
