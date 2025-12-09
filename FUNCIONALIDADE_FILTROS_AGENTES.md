# Funcionalidade: Filtros de Conversação para Agentes

## 📋 Visão Geral

Esta funcionalidade permite que administradores configurem filtros de visualização de conversas para cada agente individualmente. Com isso, é possível controlar quais conversas cada agente pode ver, proporcionando maior segurança e organização no atendimento.

## 🎯 Problema Resolvido

**Situação Anterior:**
- Para um agente ver conversas, ele precisava ser adicionado à caixa de entrada (inbox)
- Isso dava acesso a TODAS as conversas daquela inbox
- Não havia controle granular sobre quais conversas cada agente poderia visualizar

**Situação Atual:**
- Agentes podem ter filtros personalizados
- Permite restringir visualização apenas para conversas do seu time
- Permite visualizar apenas conversas não atribuídas
- Permite combinações específicas (ex: conversas do time que estão livres ou já são do agente)

## 🛠️ Arquitetura da Solução

### 1. Camada de Banco de Dados

#### Migration
**Arquivo:** `db/migrate/20251205120000_add_conversation_filter_mode_to_account_users.rb`

```ruby
class AddConversationFilterModeToAccountUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :account_users, :conversation_filter_mode, :integer, default: 0, null: false
  end
end
```

**O que faz:**
- Adiciona coluna `conversation_filter_mode` do tipo `integer` na tabela `account_users`
- Valor padrão: `0` (all_conversations)
- Não permite valores nulos

### 2. Camada de Modelo (Model)

#### AccountUser Model
**Arquivo:** `app/models/account_user.rb`

```ruby
enum conversation_filter_mode: {
  all_conversations: 0,              # Ver todas conversas (padrão atual)
  team_conversations_only: 1,        # Ver apenas conversas do time
  assigned_conversations_only: 2,    # Ver apenas conversas atribuídas a mim
  unassigned_conversations_only: 3,  # Ver apenas conversas sem agente atribuído
  team_unassigned_or_mine: 4         # Ver conversas do time que estão sem agente OU atribuídas a mim
}
```

**O que faz:**
- Define um enum (enumeração) para os modos de filtro
- Cada modo tem um valor numérico associado
- Rails automaticamente cria métodos helper (ex: `user.all_conversations?`, `user.team_conversations_only!`)

### 3. Camada de Serviço (Service)

#### Permission Filter Service
**Arquivo:** `app/services/conversations/permission_filter_service.rb`

Esta é a camada mais importante - onde a lógica de filtro é aplicada.

```ruby
def perform
  return conversations if user_role == 'administrator'
  
  apply_conversation_filters
end

private

def apply_conversation_filters
  base_conversations = accessible_conversations

  case account_user&.conversation_filter_mode
  when 'team_conversations_only'
    filter_by_team(base_conversations)
  when 'assigned_conversations_only'
    filter_by_assigned(base_conversations)
  when 'unassigned_conversations_only'
    filter_by_unassigned(base_conversations)
  when 'team_unassigned_or_mine'
    filter_by_team_unassigned_or_mine(base_conversations)
  else
    base_conversations
  end
end

def accessible_conversations
  # Conversas das inboxes às quais o agente tem acesso
  conversations.where(inbox: user.inboxes.where(account_id: account.id))
end

def filter_by_team(base_conversations)
  team_ids = user.teams.where(account_id: account.id).pluck(:id)
  return base_conversations.none if team_ids.empty?
  
  base_conversations.where(team_id: team_ids)
end

def filter_by_assigned(base_conversations)
  base_conversations.where(assignee_id: user.id)
end

def filter_by_unassigned(base_conversations)
  base_conversations.where(assignee_id: nil)
end

def filter_by_team_unassigned_or_mine(base_conversations)
  team_ids = user.teams.where(account_id: account.id).pluck(:id)
  return base_conversations.none if team_ids.empty?

  # Conversas do time que estão sem agente OU atribuídas ao usuário atual
  base_conversations.where(team_id: team_ids)
                    .where('assignee_id IS NULL OR assignee_id = ?', user.id)
end
```

**Fluxo de Execução:**
1. Verifica se o usuário é administrador (admins veem tudo)
2. Obtém as conversas base (inbox members)
3. Aplica o filtro configurado para o agente
4. Retorna apenas as conversas permitidas

**Observação Importante:**
- Este serviço é chamado automaticamente em `ConversationFinder` e `Conversations::FilterService`
- Existe extensão Enterprise em `enterprise/app/services/enterprise/conversations/permission_filter_service.rb` que adiciona suporte para custom roles
- O `prepend_mod_with` garante compatibilidade com a versão Enterprise

### 4. Camada de Controller (API)

#### Agents Controller
**Arquivo:** `app/controllers/api/v1/accounts/agents_controller.rb`

```ruby
def account_user_attributes
  [:role, :availability, :auto_offline, :conversation_filter_mode]
end

def allowed_agent_params
  [:name, :email, :role, :availability, :auto_offline, :conversation_filter_mode]
end
```

**O que faz:**
- Adiciona `conversation_filter_mode` aos parâmetros permitidos
- Permite que o campo seja atualizado via API
- Garante validação através do Strong Parameters do Rails

### 5. Camada de View (Serialização)

#### Agent Partial
**Arquivo:** `app/views/api/v1/models/_agent.json.jbuilder`

```ruby
json.conversation_filter_mode resource.current_account_user&.conversation_filter_mode
```

**O que faz:**
- Adiciona o campo `conversation_filter_mode` na resposta JSON da API
- Usa safe navigation operator (`&.`) para evitar erros se não houver account_user
- Retorna o valor do enum como string (ex: "team_conversations_only")

### 6. Camada de Frontend (Vue.js)

#### EditAgent Component
**Arquivo:** `app/javascript/dashboard/routes/dashboard/settings/agents/EditAgent.vue`

**Props:**
```vue
conversationFilterMode: {
  type: String,
  default: 'all_conversations',
}
```

**Reactive State:**
```vue
const conversationFilterMode = ref(props.conversationFilterMode);
```

**Computed Options:**
```vue
const conversationFilterOptions = computed(() => [
  {
    value: 'all_conversations',
    label: t('AGENT_MGMT.EDIT.FORM.CONVERSATION_FILTER.ALL'),
  },
  {
    value: 'team_conversations_only',
    label: t('AGENT_MGMT.EDIT.FORM.CONVERSATION_FILTER.TEAM_ONLY'),
  },
  {
    value: 'assigned_conversations_only',
    label: t('AGENT_MGMT.EDIT.FORM.CONVERSATION_FILTER.ASSIGNED_ONLY'),
  },
  {
    value: 'unassigned_conversations_only',
    label: t('AGENT_MGMT.EDIT.FORM.CONVERSATION_FILTER.UNASSIGNED_ONLY'),
  },
  {
    value: 'team_unassigned_or_mine',
    label: t('AGENT_MGMT.EDIT.FORM.CONVERSATION_FILTER.TEAM_UNASSIGNED_OR_MINE'),
  },
]);
```

**Template:**
```vue
<div class="w-full">
  <label>
    {{ $t('AGENT_MGMT.EDIT.FORM.CONVERSATION_FILTER.LABEL') }}
    <select v-model="conversationFilterMode">
      <option
        v-for="option in conversationFilterOptions"
        :key="option.value"
        :value="option.value"
      >
        {{ option.label }}
      </option>
    </select>
  </label>
</div>
```

**Submit:**
```vue
const editAgent = async () => {
  const payload = {
    id: props.id,
    name: agentName.value,
    availability: agentAvailability.value,
    conversation_filter_mode: conversationFilterMode.value, // ← Novo campo
  };
  
  await store.dispatch('agents/update', payload);
  // ...
};
```

#### Index Component
**Arquivo:** `app/javascript/dashboard/routes/dashboard/settings/agents/Index.vue`

```vue
<EditAgent
  v-if="showEditPopup"
  :id="currentAgent.id"
  :name="currentAgent.name"
  :provider="currentAgent.provider"
  :type="currentAgent.role"
  :email="currentAgent.email"
  :availability="currentAgent.availability_status"
  :custom-role-id="currentAgent.custom_role_id"
  :conversation-filter-mode="currentAgent.conversation_filter_mode"
  @close="hideEditPopup"
/>
```

**O que faz:**
- Passa o `conversation_filter_mode` do agente para o componente de edição
- Garante que o valor atual seja exibido no formulário

### 7. Internacionalização (i18n)

#### Inglês
**Arquivo:** `app/javascript/dashboard/i18n/locale/en/agentMgmt.json`

```json
"CONVERSATION_FILTER": {
  "LABEL": "Conversation Filter",
  "ALL": "All Conversations",
  "TEAM_ONLY": "Only Team Conversations",
  "ASSIGNED_ONLY": "Only Assigned Conversations",
  "UNASSIGNED_ONLY": "Only Unassigned Conversations",
  "TEAM_UNASSIGNED_OR_MINE": "Team Conversations (Unassigned or Mine)"
}
```

#### Português do Brasil
**Arquivo:** `app/javascript/dashboard/i18n/locale/pt_BR/agentMgmt.json`

```json
"CONVERSATION_FILTER": {
  "LABEL": "Filtro de Conversas",
  "ALL": "Todas as Conversas",
  "TEAM_ONLY": "Apenas Conversas do Time",
  "ASSIGNED_ONLY": "Apenas Conversas Atribuídas a Mim",
  "UNASSIGNED_ONLY": "Apenas Conversas Não Atribuídas",
  "TEAM_UNASSIGNED_OR_MINE": "Conversas do Time (Não Atribuídas ou Minhas)"
}
```

#### Português de Portugal
**Arquivo:** `app/javascript/dashboard/i18n/locale/pt/agentMgmt.json`

```json
"CONVERSATION_FILTER": {
  "LABEL": "Filtro de Conversas",
  "ALL": "Todas as Conversas",
  "TEAM_ONLY": "Apenas Conversas da Equipa",
  "ASSIGNED_ONLY": "Apenas Conversas Atribuídas a Mim",
  "UNASSIGNED_ONLY": "Apenas Conversas Não Atribuídas",
  "TEAM_UNASSIGNED_OR_MINE": "Conversas da Equipa (Não Atribuídas ou Minhas)"
}
```

## 📊 Detalhamento dos Filtros

### 1. All Conversations (Padrão)
```ruby
all_conversations: 0
```
**Comportamento:**
- Agente vê todas as conversas das inboxes às quais tem acesso
- Comportamento padrão do sistema (retrocompatível)
- Sem restrições adicionais

**Quando usar:**
- Agentes de nível sênior
- Supervisores
- Quando não há necessidade de restrição

### 2. Team Conversations Only
```ruby
team_conversations_only: 1
```
**Comportamento:**
- Filtra apenas conversas atribuídas aos times do agente
- SQL: `WHERE team_id IN (user_team_ids)`

**Quando usar:**
- Agentes especializados por departamento
- Organização por área de atuação
- Separação clara de responsabilidades

**Exemplo:**
- Agente está no time "Suporte Técnico"
- Só vê conversas marcadas com team = "Suporte Técnico"

### 3. Assigned Conversations Only
```ruby
assigned_conversations_only: 2
```
**Comportamento:**
- Mostra apenas conversas atribuídas diretamente ao agente
- SQL: `WHERE assignee_id = user.id`

**Quando usar:**
- Agentes que só devem ver suas próprias conversas
- Controle estrito de privacidade
- Trabalho individual sem compartilhamento

**Exemplo:**
- Agente João só vê conversas onde João é o assignee

### 4. Unassigned Conversations Only
```ruby
unassigned_conversations_only: 3
```
**Comportamento:**
- Mostra apenas conversas sem agente atribuído
- SQL: `WHERE assignee_id IS NULL`

**Quando usar:**
- Agentes responsáveis por triagem
- Sistema de "primeiro que pegar"
- Distribuição manual de demandas

**Exemplo:**
- Agente vê apenas conversas que ainda não foram atribuídas a ninguém

### 5. Team Unassigned or Mine
```ruby
team_unassigned_or_mine: 4
```
**Comportamento:**
- Filtra conversas do time do agente que estejam:
  - Sem agente atribuído (disponíveis) OU
  - Já atribuídas ao próprio agente
- SQL: `WHERE team_id IN (user_team_ids) AND (assignee_id IS NULL OR assignee_id = user.id)`

**Quando usar:**
- Agentes que pegam conversas do próprio time
- Permite ver o que está disponível para pegar
- Mantém visibilidade das próprias conversas
- Ideal para equipes que trabalham com auto-atribuição

**Exemplo:**
- Agente está no time "Vendas"
- Vê conversas do time "Vendas" que:
  - Ninguém pegou ainda (pode pegar)
  - Já estão com ele (continuar atendendo)
- Não vê conversas de outros times
- Não vê conversas do seu time que estão com outros agentes

## 🔄 Fluxo Completo da Requisição

```
1. Frontend: Usuário acessa lista de conversas
   ↓
2. API Request: GET /api/v1/accounts/:account_id/conversations
   ↓
3. ConversationFinder: Busca conversas
   ↓
4. PermissionFilterService.perform
   ├─ Verifica se é admin (bypass filtros)
   ├─ Obtém conversas base (inbox access)
   └─ Aplica conversation_filter_mode
      ├─ all_conversations → Retorna base
      ├─ team_conversations_only → Filtra por team_id
      ├─ assigned_conversations_only → Filtra por assignee_id = user
      ├─ unassigned_conversations_only → Filtra por assignee_id IS NULL
      └─ team_unassigned_or_mine → Filtra por team AND (unassigned OR mine)
   ↓
5. Query SQL: Executada com filtros aplicados
   ↓
6. Serialização: JSON Builder monta resposta
   ↓
7. Frontend: Recebe e exibe conversas filtradas
```

## 🔒 Considerações de Segurança

### 1. Filtros não são Bypassáveis
- Aplicados no backend (não apenas UI)
- Validados em cada requisição
- Administradores sempre têm acesso completo

### 2. Isolation
- Agente nunca vê conversas de inboxes que não tem acesso
- Filtro adiciona restrições, nunca remove

### 3. Audit Trail
- Mudanças de filtro podem ser rastreadas via audit logs
- Account_user.updated_at registra alterações

## 📦 Arquivos Modificados

### Backend (Ruby)
```
db/migrate/20251205120000_add_conversation_filter_mode_to_account_users.rb
app/models/account_user.rb
app/services/conversations/permission_filter_service.rb
app/controllers/api/v1/accounts/agents_controller.rb
app/views/api/v1/models/_agent.json.jbuilder
```

### Frontend (JavaScript/Vue)
```
app/javascript/dashboard/routes/dashboard/settings/agents/EditAgent.vue
app/javascript/dashboard/routes/dashboard/settings/agents/Index.vue
```

### Traduções
```
app/javascript/dashboard/i18n/locale/en/agentMgmt.json
app/javascript/dashboard/i18n/locale/pt_BR/agentMgmt.json
app/javascript/dashboard/i18n/locale/pt/agentMgmt.json
```

## 🚀 Como Instalar/Ativar

### 1. Executar Migration
```bash
cd ~/chatwoot-src
eval "$(rbenv init -)"
bundle exec rails db:migrate
```

### 2. Reiniciar Servidor
```bash
# Se usando overmind
overmind restart

# Ou reiniciar manualmente
Ctrl+C no terminal do servidor
pnpm dev
```

### 3. Configurar Agente
1. Acesse: Settings → Agents
2. Clique em "Edit" no agente desejado
3. Selecione o filtro desejado no dropdown "Filtro de Conversas"
4. Clique em "Editar agente"

## 🧪 Como Testar

### Teste 1: Filtro de Time
```
1. Crie dois times: "Vendas" e "Suporte"
2. Adicione agente ao time "Vendas"
3. Configure filtro: "Apenas Conversas do Time"
4. Crie conversas com team="Vendas" e team="Suporte"
5. Agente só deve ver conversas de "Vendas"
```

### Teste 2: Filtro de Atribuição
```
1. Configure filtro: "Apenas Conversas Atribuídas a Mim"
2. Crie conversas:
   - Atribuída ao agente A
   - Atribuída ao agente B
   - Sem atribuição
3. Agente A só deve ver sua própria conversa
```

### Teste 3: Filtro Combinado
```
1. Agente no time "Suporte"
2. Configure: "Conversas do Time (Não Atribuídas ou Minhas)"
3. Crie conversas:
   - Time "Suporte", sem agente → DEVE VER
   - Time "Suporte", com agente A → DEVE VER
   - Time "Suporte", com agente B → NÃO DEVE VER
   - Time "Vendas", sem agente → NÃO DEVE VER
```

### Teste 4: Admin Bypass
```
1. Configure filtro restritivo para um admin
2. Admin deve continuar vendo todas as conversas
3. Filtros não se aplicam a administradores
```

## 🔧 Troubleshooting

### Problema: Agente não vê nenhuma conversa
**Possíveis causas:**
1. Agente não está adicionado a nenhuma inbox
2. Filtro muito restritivo (ex: team_only mas sem time)
3. Migration não foi executada

**Solução:**
```ruby
# Console Rails
user = User.find_by(email: 'agente@email.com')
account = Account.find(X)
account_user = user.account_users.find_by(account: account)

# Verificar filtro atual
account_user.conversation_filter_mode

# Resetar para padrão
account_user.update(conversation_filter_mode: 'all_conversations')
```

### Problema: Frontend não mostra o campo
**Solução:**
1. Limpar cache do navegador
2. Verificar se o backend retorna o campo:
```bash
curl http://localhost:3000/api/v1/accounts/1/agents \
  -H "api_access_token: SEU_TOKEN"
```
3. Rebuild frontend: `pnpm build`

### Problema: Migration falha
**Erro:** `PG::DuplicateColumn: ERROR: column "conversation_filter_mode" already exists`

**Solução:**
```bash
# Reverter migration
bundle exec rails db:rollback

# Re-executar
bundle exec rails db:migrate
```

## 📈 Possíveis Melhorias Futuras

### 1. Filtros Múltiplos
- Permitir combinar múltiplos filtros
- Ex: "Team A OR Team B"
- Requer mudança de enum para array/jsonb

### 2. Filtros por Inbox
- Adicionar filtro específico por inbox
- Útil para agentes que atendem múltiplas inboxes

### 3. Filtros Temporários
- Permitir agente trocar filtro temporariamente
- Útil para "modo supervisor"

### 4. Analytics
- Dashboard mostrando quantas conversas cada filtro retorna
- Ajuda a otimizar configurações

### 5. Filtros por Custom Attributes
- Filtrar por atributos customizados da conversa
- Integração com a versão Enterprise

## 📚 Referências

### Código Base
- `app/finders/conversation_finder.rb` - Onde o service é chamado
- `app/policies/conversation_policy.rb` - Políticas de permissão
- `enterprise/app/services/enterprise/conversations/permission_filter_service.rb` - Extensão Enterprise

### Documentação
- [Rails Enum](https://api.rubyonrails.org/classes/ActiveRecord/Enum.html)
- [Chatwoot Architecture](https://www.chatwoot.com/docs/contributing-guide/architecture)
- [Vue 3 Composition API](https://vuejs.org/guide/introduction.html)

## ✅ Checklist de Implementação

- [x] Migration criada
- [x] Enum definido no modelo
- [x] Service de filtro implementado
- [x] Controller atualizado
- [x] Serialização JSON configurada
- [x] Componente Vue criado/atualizado
- [x] Traduções adicionadas (EN, PT, PT_BR)
- [x] Compatibilidade Enterprise mantida
- [x] Documentação criada

## 🎓 Conceitos Aprendidos

### 1. Rails Enums
- Como definir e usar enums
- Métodos automáticos gerados
- Conversão entre integer e string

### 2. Service Objects
- Pattern para encapsular lógica de negócio
- Separação de responsabilidades
- Testabilidade

### 3. Vue 3 Composition API
- Refs e reactive state
- Computed properties
- Props e emits

### 4. Internacionalização
- Sistema i18n do Vue
- Múltiplos idiomas
- Organização de traduções

### 5. ActiveRecord Queries
- Where com condições OR
- Pluck para obter arrays de IDs
- Safe navigation operator

---

**Documento criado em:** 04/12/2024  
**Autor:** Implementação de Filtros de Conversação para Agentes  
**Versão:** 1.0

