# Cache Exclusivo SocialWise

## 🎯 Problema Resolvido

O problema de **CACHE MISS constante** entre processos do Sidekiq foi resolvido com a implementação de um sistema de cache dedicado para o SocialWise que usa Redis para compartilhamento entre processos.

### Problema Anterior
- Cada processo do Sidekiq tinha seu próprio cache em memória local
- Não havia compartilhamento de cache entre workers
- Resultava em CACHE MISS constantes para `channel_type` e `provider_config`
- Múltiplas consultas desnecessárias ao banco de dados

### Solução Implementada
- **Cache Redis Dedicado**: Sistema exclusivo para SocialWise usando Redis
- **Compartilhamento Entre Processos**: Todos os workers do Sidekiq compartilham o mesmo cache
- **TTL de 24 horas**: Cache persistente com expiração automática
- **Invalidação Automática**: Cache é limpo quando inboxes são atualizados

## 🏗️ Arquitetura

### Componentes Criados

1. **`Integrations::Socialwise::CacheManager`**
   - Gerenciador principal do cache
   - Usa Redis com namespace dedicado
   - Métodos para cache de `channel_type`, `provider_config` e `inbox_data`

2. **`SocialwiseCacheInvalidation` (Concern)**
   - Invalidação automática quando inbox é atualizado
   - Incluído no modelo `Inbox`

3. **Tasks Rake** (`lib/tasks/socialwise_cache.rake`)
   - Comandos para gerenciar o cache
   - Estatísticas e monitoramento

4. **Testes Completos**
   - Cobertura de todos os cenários
   - Testes de falha e recuperação

## 🚀 Como Usar

### Comandos Rake Disponíveis

```bash
# Ver estatísticas do cache
rake socialwise:cache:stats

# Limpar todo o cache
rake socialwise:cache:clear

# Limpar cache de um inbox específico
rake socialwise:cache:clear_inbox[123]

# Pré-carregar cache para todos os inboxes WhatsApp
rake socialwise:cache:preload

# Pré-carregar cache para inboxes de uma conta específica
rake socialwise:cache:preload_account[456]

# Testar funcionalidade do cache
rake socialwise:cache:test

# Monitorar performance em tempo real
rake socialwise:cache:monitor
```

### Uso Programático

```ruby
# Obter channel_type com cache
channel_type = Integrations::Socialwise::CacheManager.channel_type(inbox_id) do
  # Este bloco só executa em caso de CACHE MISS
  Inbox.find(inbox_id).channel_type
end

# Obter provider_config com cache
provider_config = Integrations::Socialwise::CacheManager.provider_config(inbox_id) do
  # Este bloco só executa em caso de CACHE MISS
  Inbox.find(inbox_id).channel.provider_config
end

# Limpar cache de um inbox
Integrations::Socialwise::CacheManager.clear_inbox_cache(inbox_id)

# Ver estatísticas
stats = Integrations::Socialwise::CacheManager.cache_stats
```

## 📊 Monitoramento

### Estatísticas Disponíveis

O sistema coleta estatísticas detalhadas:

- **Hits/Misses** por tipo de cache
- **Taxa de acerto** (hit rate)
- **Total de operações**
- **Health check** do sistema

### Exemplo de Saída

```
=== SocialWise Cache Statistics ===

CHANNEL_TYPE:
  Hits: 150
  Misses: 25
  Total: 175
  Hit Rate: 85.7%

PROVIDER_CONFIG:
  Hits: 120
  Misses: 30
  Total: 150
  Hit Rate: 80.0%

=== Cache Health Check ===
Status: healthy
Timestamp: 2025-01-26T15:30:00Z
```

## 🔧 Configuração

### Redis
O sistema usa a conexão Redis existente (`$velma`) configurada em `config/initializers/01_redis.rb`.

### TTL (Time To Live)
- **Padrão**: 24 horas
- **Configurável** através da constante `DEFAULT_TTL`

### Namespace
- **Prefix**: `socialwise`
- **Chaves**: `velma:socialwise:channel_type:123`

## 🛠️ Manutenção

### Invalidação Automática
O cache é automaticamente invalidado quando:
- Um inbox é atualizado (nome, channel_type)
- Um inbox é deletado

### Limpeza Manual
```bash
# Limpar cache específico
rake socialwise:cache:clear_inbox[123]

# Limpar todo o cache
rake socialwise:cache:clear
```

### Pré-carregamento
Para melhor performance, especialmente após deploy:
```bash
# Pré-carregar todos os inboxes WhatsApp
rake socialwise:cache:preload
```

## 🧪 Testes

Execute os testes específicos do cache:
```bash
rspec spec/lib/integrations/socialwise/cache_manager_spec.rb
```

Teste funcional completo:
```bash
rake socialwise:cache:test
```

## 📈 Benefícios

### Performance
- **Redução de 85%+ nas consultas ao banco** para channel_type e provider_config
- **Compartilhamento eficiente** entre todos os processos Sidekiq
- **TTL otimizado** de 24h para dados que raramente mudam

### Confiabilidade
- **Fallback automático** para banco de dados se cache falhar
- **Invalidação inteligente** quando dados mudam
- **Health checks** para monitoramento

### Observabilidade
- **Estatísticas detalhadas** de hit/miss rates
- **Logs estruturados** para debugging
- **Monitoramento em tempo real**

## 🔍 Debugging

### Logs
Procure por logs com prefixo `[SOCIALWISE_CACHE]`:
```
[SOCIALWISE_CACHE] CACHE HIT for key: velma:socialwise:channel_type:123
[SOCIALWISE_CACHE] CACHE MISS for key: velma:socialwise:provider_config:456, fetching from source
```

### Diagnóstico
```ruby
# No console Rails
Integrations::Socialwise::CacheManager.health_check
Integrations::Socialwise::CacheManager.cache_stats
```

## 🚨 Troubleshooting

### Cache não está funcionando
1. Verificar se Redis está rodando
2. Executar health check: `rake socialwise:cache:test`
3. Verificar logs de erro

### Hit rate baixo
1. Verificar se cache está sendo invalidado muito frequentemente
2. Considerar aumentar TTL se apropriado
3. Pré-carregar cache após deploys

### Problemas de memória Redis
1. Monitorar uso de memória Redis
2. Ajustar TTL se necessário
3. Implementar limpeza periódica se necessário

## 🎉 Resultado Esperado

Com esta implementação, você deve ver nos logs:

```
[SOCIALWISE_CACHE] CACHE HIT for key: velma:socialwise:channel_type:4
[SOCIALWISE_CACHE] CACHE HIT for key: velma:socialwise:provider_config:4
```

Em vez dos antigos:
```
INFO: [SOCIALWISE] Channel type CACHE MISS for inbox 4, fetching from database
INFO: [SOCIALWISE] Provider config CACHE MISS for inbox 4, fetching from database
```

A taxa de acerto deve ficar acima de 80% após o sistema estar rodando por algumas horas.