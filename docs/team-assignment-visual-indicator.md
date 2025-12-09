# Implementação: Indicador Visual de Time nas Conversas

## Visão Geral

Esta implementação adiciona um indicador visual mostrando qual time está atribuído a uma conversa na lista de conversas, e também adiciona a opção "Nenhum" nos seletores de times para permitir remover a atribuição.

## Funcionalidades Implementadas

### 1. Badge Visual do Time na Lista de Conversas

Quando uma conversa está atribuída a um time, um badge com o nome do time aparece acima do horário da última mensagem.

**Características do Badge:**
- Fundo cinza claro (`bg-n-slate-3`)
- Texto em tamanho pequeno mas legível (`text-xs`)
- Cantos totalmente arredondados (`rounded-full`)
- Truncamento automático com tooltip ao passar o mouse
- Aparece apenas quando há um time atribuído
- Largura máxima de 120px

### 2. Opção "Nenhum" nos Seletores de Times

Adicionada a opção "Nenhum" em todos os seletores de times, permitindo remover a atribuição de time de uma conversa (similar ao comportamento dos agentes).

**Disponível em:**
- Sidebar da conversa (dropdown de times)
- Menu de contexto (botão direito nas conversas)
- Atalhos de teclado (command bar)
- Ações em massa

## Arquivos Modificados

### Frontend - Componentes de Conversação

#### 1. `app/javascript/dashboard/components/widgets/conversation/ConversationCard.vue`

**Mudanças:**
- Adicionada computed property `assignedTeam` que busca o time dos metadados da conversa
- Adicionado badge visual do time acima do timestamp
- Badge usa classes Tailwind para estilização

```javascript
const assignedTeam = computed(() => chatMetadata.value.team || null);
```

```html
<span
  v-if="assignedTeam"
  class="ml-auto mb-1 px-2 py-0.5 rounded-full bg-n-slate-3 text-xs font-medium text-n-slate-12 truncate max-w-[120px]"
  :title="`${$t('CHAT_LIST.ASSIGNED_TEAM')}: ${assignedTeam.name}`"
>
  {{ assignedTeam.name }}
</span>
```

#### 2. `app/javascript/dashboard/components-next/Conversation/ConversationCard/ConversationCard.vue`

**Mudanças:**
- Mesmas mudanças aplicadas ao novo componente de card de conversa
- Mantém consistência entre os dois componentes
- Badge posicionado ao lado dos outros metadados (prioridade e inbox)

```javascript
const assignedTeam = computed(() => {
  const { meta: { team = null } = {} } = props.conversation;
  return team;
});
```

### Frontend - Seletores de Times

#### 3. `app/javascript/dashboard/routes/dashboard/conversation/ConversationAction.vue`

**Mudanças:**
- Removida condicional que mostrava "Nenhum" apenas quando havia time atribuído
- Agora a opção "Nenhum" aparece sempre no topo da lista de times

**Antes:**
```javascript
teamsList() {
  if (this.hasAnAssignedTeam) {
    return [
      { id: 0, name: this.$t('TEAMS_SETTINGS.LIST.NONE') },
      ...this.teams,
    ];
  }
  return this.teams;
}
```

**Depois:**
```javascript
teamsList() {
  return [
    { id: 0, name: this.$t('TEAMS_SETTINGS.LIST.NONE') },
    ...this.teams,
  ];
}
```

#### 4. `app/javascript/dashboard/composables/commands/useConversationHotKeys.js`

**Mudanças:**
- Mesma modificação aplicada aos atalhos de teclado (command bar)
- Garante consistência em toda a aplicação

#### 5. `app/javascript/dashboard/components/widgets/conversation/contextMenu/Index.vue`

**Mudanças:**
- Adicionada computed property `assignableTeams` que sempre inclui a opção "Nenhum"
- Atualizado o menu de times para usar `assignableTeams` ao invés de `teams`

```javascript
assignableTeams() {
  return [
    {
      id: 0,
      name: this.$t('TEAMS_SETTINGS.LIST.NONE'),
    },
    ...this.teams,
  ];
}
```

#### 6. `app/javascript/dashboard/components/widgets/conversation/conversationBulkActions/TeamActions.vue`

**Mudanças:**
- Substituído texto hardcoded `'None'` por tradução
- Agora usa `this.$t('TEAMS_SETTINGS.LIST.NONE')`

### Frontend - Traduções Hardcoded Corrigidas

#### 7. `app/javascript/dashboard/components/widgets/conversation/conversationBulkActions/AgentSelector.vue`

**Mudanças:**
- Substituído `name: 'None'` por `name: this.$t('AGENT_MGMT.MULTI_SELECTOR.LIST.NONE')`
- Garante que agentes também usem a tradução correta

#### 8. `app/javascript/dashboard/components/widgets/conversation/contextMenu/Index.vue` (agentes)

**Mudanças:**
- Substituído `name: 'None'` por `name: this.$t('AGENT_MGMT.MULTI_SELECTOR.LIST.NONE')`
- Consistência com times

### Frontend - Traduções (i18n)

#### 9. `app/javascript/dashboard/i18n/locale/en/chatlist.json`

**Mudanças:**
- Adicionada nova chave de tradução para o label do time

```json
"ASSIGNED_TEAM": "Team"
```

#### 10. `app/javascript/dashboard/i18n/locale/pt_BR/teamsSettings.json`

**Mudanças:**
- Ajustado de "Nenhuma" para "Nenhum" (masculino)

```json
"NONE": "Nenhum"
```

#### 11. `app/javascript/dashboard/i18n/locale/pt_BR/conversation.json`

**Mudanças:**
- Ajustado placeholder de seleção de time de "Nenhuma" para "Nenhum"

```json
"SELECT": {
  "PLACEHOLDER": "Nenhum"
}
```

## Backend - Como Funciona

### Serialização do Time no JSON

O backend já estava preparado para enviar os dados do time no JSON das conversas através do arquivo:

**`app/views/api/v1/conversations/partials/_conversation.json.jbuilder`**

```ruby
if conversation.team.present?
  json.team do
    json.partial! 'api/v1/models/team', formats: [:json], resource: conversation.team
  end
end
```

### Remoção de Atribuição de Time

**`app/controllers/api/v1/accounts/conversations/assignments_controller.rb`**

Quando `team_id: 0` é enviado:
1. O `find_by(id: 0)` retorna `nil`
2. O `@conversation.update!(team: nil)` remove a atribuição do time

```ruby
def set_team
  @team = Current.account.teams.find_by(id: params[:team_id])
  @conversation.update!(team: @team)
  render json: @team
end
```

## Fluxo de Dados

### Exibição do Time na Conversa

```
Backend (Ruby) 
  ↓
  Serializa conversation.team no JSON
  ↓
Frontend (Vue)
  ↓
  Vuex Store recebe os dados
  ↓
  ConversationCard.vue lê chat.meta.team
  ↓
  Computed property assignedTeam
  ↓
  Badge é renderizado se team não for null
```

### Atribuição/Remoção de Time

```
Usuário seleciona "Nenhum" ou um time
  ↓
  Vue emite evento com team.id (0 para "Nenhum")
  ↓
  Vuex Action assignTeam
  ↓
  API POST /api/v1/accounts/:account_id/conversations/:id/assignments
    Params: { team_id: 0 ou team_id: <id_do_time> }
  ↓
  Backend atualiza conversation.team
  ↓
  Backend retorna JSON atualizado
  ↓
  Frontend atualiza o store
  ↓
  UI reflete a mudança
```

## Considerações Técnicas

### Compatibilidade com Enterprise

Como mencionado nas guidelines do projeto, sempre que modificamos funcionalidade core, devemos considerar o impacto no Enterprise Edition.

Nesta implementação:
- **Não há quebra de compatibilidade**: apenas adicionamos exibição visual
- **API não foi modificada**: apenas aproveitamos dados já existentes
- **Backend já suportava team_id: 0**: não há mudanças no comportamento

### Estilo e Design System

A implementação segue as guidelines do Chatwoot:
- ✅ Usa apenas classes Tailwind (sem CSS customizado)
- ✅ Usa o design system de cores (`bg-n-slate-3`, `text-n-slate-12`)
- ✅ Mantém consistência visual com outros badges (labels, SLA)
- ✅ Usa i18n para todos os textos

### Performance

- **Sem impacto**: os dados do time já vinham no JSON da conversa
- **Não há requests extras**: apenas renderização condicional
- **Computed properties**: reatividade eficiente do Vue

## Testes

### Como Testar

1. **Visualização do Badge:**
   - Atribuir um time a uma conversa
   - Verificar se o badge aparece acima do horário
   - Verificar tooltip ao passar o mouse
   - Verificar truncamento em nomes longos

2. **Opção "Nenhum":**
   - Abrir seletor de times (sidebar, menu contexto, ações em massa)
   - Verificar se "Nenhum" aparece no topo da lista
   - Selecionar "Nenhum" e verificar se remove a atribuição
   - Verificar se o badge desaparece da lista de conversas

3. **Traduções:**
   - Mudar idioma para português
   - Verificar se exibe "Nenhum" em todos os seletores
   - Verificar se o badge mantém o nome do time (não traduz)

### Casos de Teste

| Caso | Ação | Resultado Esperado |
|------|------|-------------------|
| 1 | Conversa sem time | Badge não aparece |
| 2 | Conversa com time | Badge aparece com nome do time |
| 3 | Nome de time longo | Badge trunca e mostra tooltip |
| 4 | Selecionar "Nenhum" | Remove atribuição e badge some |
| 5 | Idioma PT-BR | Exibe "Nenhum" em todos os seletores |
| 6 | Idioma EN | Exibe "None" em todos os seletores |

## Manutenção Futura

### Adicionando Novos Idiomas

Ao adicionar suporte a um novo idioma, certifique-se de traduzir:

1. **Para o badge de time:**
   - `CHAT_LIST.ASSIGNED_TEAM` em `chatlist.json`

2. **Para a opção "Nenhum":**
   - `TEAMS_SETTINGS.LIST.NONE` em `teamsSettings.json`
   - `AGENT_MGMT.MULTI_SELECTOR.LIST.NONE` em `agentMgmt.json`

### Modificando o Estilo do Badge

Para alterar a aparência do badge, modifique as classes Tailwind nos arquivos:
- `app/javascript/dashboard/components/widgets/conversation/ConversationCard.vue`
- `app/javascript/dashboard/components-next/Conversation/ConversationCard/ConversationCard.vue`

**Classes atuais:**
```
bg-n-slate-3        // Cor de fundo
text-xs             // Tamanho do texto
font-medium         // Peso da fonte
text-n-slate-12     // Cor do texto
rounded-full        // Bordas arredondadas
px-2 py-0.5         // Padding
max-w-[120px]       // Largura máxima
truncate            // Truncamento de texto
```

## Referências

- [Chatwoot Development Guidelines](../../.github/CONTRIBUTING.md)
- [Team Model](../../app/models/team.rb)
- [Conversation Model](../../app/models/conversation.rb)
- [Assignment Controller](../../app/controllers/api/v1/accounts/conversations/assignments_controller.rb)

## Conclusão

Esta implementação adiciona visibilidade importante sobre a atribuição de times nas conversas, mantendo a consistência com o padrão já existente para agentes. Todas as mudanças seguem as guidelines do projeto e não introduzem breaking changes.

