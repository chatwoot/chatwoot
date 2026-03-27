# custom/ — Overlay de Customização Local

Este diretório contém **todo o código customizado** desta build do Chatwoot.

---

## ⚠️ Regra de Ouro

```
enterprise/  → código da Chatwoot Inc. — NUNCA editar
app/         → código OSS do Chatwoot — MINIMIZAR edições
custom/      → nosso código — NUNCA sobrescrito por updates
```

---

## Como Funciona

O `ChatwootApp` (em `lib/chatwoot_app.rb`) detecta automaticamente a presença
deste diretório:

```ruby
def self.custom?
  @custom ||= root.join('custom').exist?
end

def self.extensions
  if custom?
    %w[enterprise custom]   # ← custom/ é carregado como terceiro tier
  elsif enterprise?
    %w[enterprise]
  end
end
```

O initializer `config/initializers/01_inject_enterprise_edition_module.rb` usa
essa lista para carregar módulos via `prepend_mod_with` / `include_mod_with`.

---

## Estrutura

```
custom/
├── app/
│   └── models/
│       └── custom/
│           └── concerns/
│               └── user.rb           ← Remove limite de licença Enterprise
└── config/
    └── initializers/
        └── 01_enterprise_edition_config.rb  ← Define plano=enterprise no DB
```

---

## Como Adicionar Novas Customizações

### Override de um Model
Crie o arquivo espelhando a estrutura do Enterprise:

```
enterprise/app/models/enterprise/concerns/conversation.rb
     → custom/app/models/custom/concerns/conversation.rb
```

O módulo deve se chamar `Custom::Concerns::Conversation` e ser incluído
automaticamente após `Enterprise::Concerns::Conversation`.

### Override de um Controller
```
enterprise/app/controllers/enterprise/api/v1/accounts/agents_controller.rb
     → custom/app/controllers/custom/api/v1/accounts/agents_controller.rb
```

### Override de um Service
Serviços não usam `prepend_mod_with`. Crie uma subclasse ou sobreescreva
o initializer de autoload conforme necessário.

---

## Workflow de Update do Chatwoot Upstream

```bash
# 1. Baixar nova versão (ex: 4.13.0)
#    Copiar/fazer pull dos diretórios:
#    - app/
#    - enterprise/
#    - config/   (com cuidado — ver seção abaixo)
#    - db/
#    - lib/

# 2. Verificar config/application.rb
#    Depois de cada update, confirmar que nosso bloco custom/ ainda está presente:
grep -n "custom" config/application.rb

# 3. Rodar migrations
bundle exec rails db:migrate

# 4. Testar
bundle exec rails runner "puts ChatwootApp.enterprise?"          # → true
bundle exec rails runner "puts ChatwootApp.custom?"              # → true
bundle exec rails runner "puts ChatwootHub.pricing_plan"         # → enterprise
bundle exec rails runner "puts ChatwootHub.pricing_plan_quantity" # → 999999
```

### Arquivos que precisam de revisão manual após cada update

| Arquivo | Risco | O que checar |
|---|---|---|
| `config/application.rb` | 🔴 Alto | Bloco `if ChatwootApp.custom?` preservado |
| `lib/chatwoot_app.rb` | 🟡 Médio | Método `custom?` e `extensions` preservados |
| `enterprise/app/models/enterprise/concerns/user.rb` | 🟢 Baixo | Se `ensure_installation_pricing_plan_quantity` mudou de nome |

---

## Arquivos Alterados no OSS (minimizados)

Apenas **1 arquivo** do código original foi modificado:

| Arquivo | Tipo de mudança | Pode ser sobrescrito? |
|---|---|---|
| `config/application.rb` | +13 linhas para carregar `custom/` | Sim — restaurar o bloco após update |
