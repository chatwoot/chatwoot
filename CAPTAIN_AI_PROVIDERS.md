# Integração de Múltiplos Provedores de IA no Captain

## Visão Geral

O Captain foi estendido para suportar múltiplos provedores de IA via **RubyLLM**, permitindo alternar entre OpenAI, DeepSeek e Google Gemini através da interface administrativa.

## Arquitetura

Na versão v4.10.1+, o Captain usa a gem **RubyLLM** como camada de abstração. Isso significa que a troca de provider é feita por configuração, sem precisar de services separados para cada provider.

### Componentes Chave

- `lib/llm/config.rb` - Configuração do RubyLLM com suporte multi-provider
- `enterprise/app/services/llm/base_ai_service.rb` - Serviço base que seleciona modelo por provider
- `config/installation_config.yml` - Definição das configurações administrativas

## Provedores Suportados

| Provider | Modelo Padrão | Config Key |
|----------|--------------|------------|
| **OpenAI** | `gpt-4o-mini` | `CAPTAIN_OPEN_AI_API_KEY` |
| **Google Gemini** | `gemini-2.0-flash` | `CAPTAIN_GEMINI_API_KEY` |
| **DeepSeek** | `deepseek-chat` | `CAPTAIN_DEEPSEEK_API_KEY` |

## Configuração

### Via Interface Web (Super Admin)

1. Acesse `/super_admin/app_config?config=captain`
2. Selecione o provedor no dropdown **AI Provider**
3. Configure a API key do provedor escolhido
4. Opcionalmente, configure o modelo
5. Salve

### Via Variáveis de Ambiente

```bash
# Provedor (openai, gemini, deepseek)
CAPTAIN_AI_PROVIDER=gemini

# OpenAI
CAPTAIN_OPEN_AI_API_KEY=sk-...
CAPTAIN_OPEN_AI_MODEL=gpt-4o-mini

# Google Gemini
CAPTAIN_GEMINI_API_KEY=AIzaSy...
CAPTAIN_GEMINI_MODEL=gemini-2.0-flash

# DeepSeek
CAPTAIN_DEEPSEEK_API_KEY=sk-...
CAPTAIN_DEEPSEEK_MODEL=deepseek-chat
```

## Como Funciona

O `Llm::Config` configura todas as API keys disponíveis no RubyLLM. O `BaseAiService` seleciona automaticamente o modelo correto baseado no provider configurado:

```ruby
# Llm::Config configura o RubyLLM com todas as chaves
RubyLLM.configure do |config|
  config.openai_api_key = openai_key
  config.gemini_api_key = gemini_key
  # DeepSeek usa endpoint OpenAI-compatible
end

# BaseAiService seleciona o modelo do provider ativo
provider = Llm::Config.provider  # => "gemini"
model = "gemini-2.0-flash"       # modelo padrão do Gemini
RubyLLM.chat(model: model)       # RubyLLM roteia automaticamente
```

## Adicionando Novos Provedores

Como o RubyLLM já suporta vários providers, adicionar um novo é simples:

1. Adicionar a API key em `Llm::Config#configure_ruby_llm`
2. Adicionar o modelo padrão em `Llm::Config::DEFAULT_MODELS`
3. Adicionar a config key em `Llm::BaseAiService::MODEL_CONFIG_KEYS`
4. Adicionar as entradas em `config/installation_config.yml`
5. Adicionar ao `captain_config_options` no controller

## Comparação de Provedores

- **OpenAI**: Alta qualidade, custo moderado, ecossistema maduro
- **Gemini**: Tier gratuito generoso, bom para texto, modelos avançados
- **DeepSeek**: Custo baixo, bom para código, API compatível com OpenAI
