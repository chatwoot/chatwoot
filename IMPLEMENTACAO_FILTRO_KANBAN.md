# Implementação do Filtro de Times no Kanban

## Visão Geral

Este documento descreve a implementação do filtro de times (`team_id`) no Kanban de contatos do Chatwoot. O filtro permite que os usuários visualizem apenas contatos que possuem conversas associadas a times específicos.

## Problema Inicial

O filtro de times no Kanban estava gerando um erro 500 (Internal Server Error) ao ser aplicado. O problema principal era:

1. **Relação indireta**: Contatos não possuem `team_id` diretamente. O `team_id` está na tabela `conversations`, que se relaciona com contatos através de `contact_id`.

2. **Erro SQL com DISTINCT e ORDER BY**: Quando o filtro era aplicado, o PostgreSQL gerava o erro:
   ```
   PG::InvalidColumnReference: ERROR: for SELECT DISTINCT, ORDER BY expressions must appear in select list
   ```
   Isso ocorria porque o `DISTINCT` era aplicado diretamente na query principal, e depois o `ORDER BY` (aplicado pelo método `filtrate` no controller) tentava ordenar por colunas que não estavam no `SELECT DISTINCT`.

## Solução Implementada

A solução utiliza uma **subquery** para isolar a operação `DISTINCT` dos `contact_ids` que correspondem ao filtro de times, permitindo que a query principal aplique `ORDER BY` sem conflitos.

## Arquitetura da Solução

### Fluxo Completo

```
Frontend (KanbanView.vue)
    ↓
1. Usuário seleciona filtro de time
    ↓
2. handleApplyFilter() processa filtros
    ↓
3. filterQueryGenerator() gera payload
    ↓
4. API POST /api/v1/accounts/:account_id/contacts/filter
    ↓
Backend (ContactsController)
    ↓
5. Contacts::FilterService.perform()
    ↓
6. Detecta filtro de team_id
    ↓
7. Cria subquery com JOIN em conversations
    ↓
8. Aplica DISTINCT em contact_ids
    ↓
9. Filtra base_relation por IDs da subquery
    ↓
10. Aplica outros filtros e ORDER BY
    ↓
11. Retorna contatos filtrados
    ↓
Frontend
    ↓
12. KanbanColumn.vue filtra contatos localmente
    ↓
13. ContactsSidebar.vue também aplica filtro
```

## Detalhamento Técnico

### 1. Frontend - KanbanView.vue

**Localização**: `app/javascript/dashboard/components-next/Contacts/Kanban/KanbanView.vue`

**Função Principal**: `handleApplyFilter()`

```javascript
const handleApplyFilter = async (filters) => {
  // 1. Valida filtros (remove filtros sem valores)
  const validFilters = filters.filter(f => {
    const hasValue = f.values !== null && f.values !== undefined && f.values !== '' &&
                     (!Array.isArray(f.values) || f.values.length > 0);
    return hasValue || ['is_present', 'is_not_present'].includes(f.filterOperator);
  });
  
  // 2. Processa valores de team_id (extrai IDs de objetos se necessário)
  const filtersForQuery = validFilters.map(f => {
    let processedValues = f.values;
    
    if (f.attributeKey === 'team_id') {
      if (typeof f.values === 'object' && f.values !== null && !Array.isArray(f.values)) {
        processedValues = [f.values.id || f.values];
      } else if (Array.isArray(f.values)) {
        processedValues = f.values.map(v => typeof v === 'object' && v !== null ? (v.id || v) : v);
      } else {
        processedValues = [f.values];
      }
    }
    
    return {
      attribute_key: f.attributeKey,
      filter_operator: f.filterOperator,
      values: processedValues,
      query_operator: f.queryOperator || 'and',
    };
  });
  
  // 3. Gera payload e faz requisição à API
  const queryPayload = filterQueryGenerator(filtersForQuery);
  const result = await store.dispatch('contacts/filter', {
    page: 1,
    queryPayload,
  });
  
  appliedFilters.value = filters;
};
```

**Pontos Importantes**:
- Extrai IDs de objetos quando `team_id` vem como objeto
- Normaliza valores para arrays
- Usa `filterQueryGenerator` para formatar o payload

### 2. Backend - ContactsController

**Localização**: `app/controllers/api/v1/accounts/contacts_controller.rb`

**Ação**: `filter`

```ruby
def filter
  result = ::Contacts::FilterService.new(Current.account, Current.user, params.permit!).perform
  contacts = result[:contacts]
  @contacts_count = result[:count]
  @contacts = fetch_contacts(contacts)  # Aplica paginação e ORDER BY
rescue CustomExceptions::CustomFilter::InvalidAttribute,
       CustomExceptions::CustomFilter::InvalidOperator,
       CustomExceptions::CustomFilter::InvalidQueryOperator,
       CustomExceptions::CustomFilter::InvalidValue => e
  render_could_not_create_error(e.message)
end
```

**Método `fetch_contacts`**:
```ruby
def fetch_contacts(contacts)
  includes_hash = { avatar_attachment: [:blob] }
  includes_hash[:contact_inboxes] = { inbox: :channel } if @include_contact_inboxes

  filtrate(contacts)  # Aplica ORDER BY baseado em params[:sort]
    .includes(includes_hash)
    .page(@current_page)
    .per(RESULTS_PER_PAGE)
end
```

**Observação**: O `filtrate` aplica o `ORDER BY` após o `FilterService` retornar os contatos. Por isso, a subquery é necessária para evitar o conflito com `DISTINCT`.

### 3. Backend - Contacts::FilterService

**Localização**: `app/services/contacts/filter_service.rb`

**Classe Base**: `FilterService` (`app/services/filter_service.rb`)

#### Método Principal: `perform`

```ruby
def perform
  validate_query_operator
  has_team_filter = @params[:payload]&.any? { |f| f['attribute_key'] == 'team_id' }
  
  if has_team_filter
    # Estratégia com subquery para evitar conflito DISTINCT + ORDER BY
    @base_relation_with_conversations = base_relation.joins(:conversations)
    filtered_contacts = query_builder_with_conversations(@filters['contacts'])
    
    # Subquery: seleciona apenas IDs únicos de contatos que passaram no filtro
    contact_ids_subquery = filtered_contacts.select('DISTINCT contacts.id')
    
    # Query principal: filtra contatos pelos IDs da subquery
    # Agora pode aplicar ORDER BY sem problemas
    @contacts = base_relation.where(id: contact_ids_subquery)
  else
    # Sem filtro de team, usar lógica padrão
    @contacts = query_builder(@filters['contacts'])
  end

  {
    contacts: @contacts,
    count: @contacts.count
  }
end
```

**Por que usar subquery?**
- A subquery isola o `DISTINCT` em `contact_ids`
- A query principal pode aplicar `ORDER BY` sem conflito
- Evita duplicação de contatos quando há múltiplas conversas

#### Método: `filter_values`

```ruby
def filter_values(query_hash)
  if query_hash['attribute_key'] == 'team_id'
    # Para team_id, retornar array de valores (números)
    query_hash['values'].is_a?(Array) ? query_hash['values'] : [query_hash['values']]
  elsif query_hash['attribute_key'] == 'phone_number'
    # ... tratamento para phone_number
  elsif query_hash['attribute_key'] == 'country_code'
    # ... tratamento para country_code
  else
    # ... tratamento padrão
  end
end
```

**Importante**: Garante que `team_id` sempre retorna um array, permitindo usar `IN` na query SQL.

#### Método: `equals_to_filter_string`

```ruby
def equals_to_filter_string(filter_operator, current_index)
  # Usar IN para permitir múltiplos valores
  return "IN (:value_#{current_index})" if filter_operator == 'equal_to'
  "NOT IN (:value_#{current_index})"
end
```

**Por que `IN`?**: Permite filtrar por múltiplos times simultaneamente (ex: `team_id IN (1, 2, 3)`).

#### Método: `query_builder_with_conversations`

```ruby
def query_builder_with_conversations(model_filters)
  @query_string = ''
  @params[:payload].each_with_index do |query_hash, current_index|
    condition_query = build_condition_query_for_team(model_filters, query_hash, current_index)
    @query_string += " #{condition_query.strip}" if condition_query.present?
  end
  
  # Validações
  raise CustomExceptions::CustomFilter::InvalidValue.new(attribute_name: 'team_id') if @query_string.strip.blank?
  raise CustomExceptions::CustomFilter::InvalidValue.new(attribute_name: 'team_id') if @filter_values.empty?
  
  # Aplica filtros na relação com JOIN em conversations
  @base_relation_with_conversations.where(@query_string.strip, @filter_values.with_indifferent_access)
end
```

**Observação**: Este método constrói a query que será usada na subquery. Aplica filtros na relação `contacts` com `JOIN` em `conversations`.

#### Método: `build_condition_query_for_team`

```ruby
def build_condition_query_for_team(model_filters, query_hash, current_index)
  if query_hash['attribute_key'] == 'team_id'
    # Sempre chamar filter_operation primeiro para popular @filter_values
    filter_operator_value = filter_operation(query_hash, current_index)
    
    # Determina query_operator (AND/OR)
    is_last_filter = current_index == @params[:payload].length - 1
    query_operator = if is_last_filter
                       ''
                     elsif query_hash[:query_operator].present?
                       " #{query_hash[:query_operator].upcase}"
                     else
                       ' AND'
                     end
    
    # Para is_present e is_not_present, filter_operation retorna nil
    # O valor real está em @filter_values
    if filter_operator_value.nil?
      filter_value = @filter_values["value_#{current_index}"]
      "conversations.team_id #{filter_value}#{query_operator}"
    else
      # Para outros operadores (equal_to, not_equal_to)
      "conversations.team_id #{filter_operator_value}#{query_operator}"
    end
  else
    # Para outros atributos, usar lógica padrão
    build_condition_query(model_filters, query_hash, current_index)
  end
end
```

**Pontos Importantes**:
- Usa `conversations.team_id` (não `contacts.team_id`)
- Trata `is_present` e `is_not_present` separadamente
- Remove `query_operator` do último filtro (conforme esperado pela API)

### 4. Frontend - KanbanColumn.vue

**Localização**: `app/javascript/dashboard/components-next/Contacts/Kanban/KanbanColumn.vue`

**Função**: Filtra contatos localmente após receber da API

```javascript
// Se há filtro de team, verificar se o contato está na lista filtrada pela API
if (hasTeamFilter) {
  const filteredContactsFromAPI = contactsFromAPI.value || [];
  const filteredContactIds = new Set(filteredContactsFromAPI.map(c => c.id));
  
  // Filtrar apenas contatos que estão na lista retornada pela API
  filtered = filtered.filter(fc => {
    if (!fc || !fc.contact) return false;
    return filteredContactIds.has(fc.contact.id);
  });
  
  // Aplicar outros filtros locais se houver (como labels)
  if (localFilters.length > 0) {
    filtered = filtered.filter(fc => {
      return applyContactFilters(fc.contact, localFilters);
    });
  }
}
```

**Por que filtrar localmente?**
- A API retorna todos os contatos que passaram no filtro de times
- Cada coluna do Kanban precisa filtrar apenas os contatos que pertencem àquela coluna
- Filtros locais (como labels) são aplicados no frontend para melhor performance

### 5. Frontend - ContactsSidebar.vue

**Localização**: `app/javascript/dashboard/components-next/Contacts/Kanban/ContactsSidebar.vue`

**Função**: Similar ao `KanbanColumn`, filtra contatos na sidebar

```javascript
if (hasTeamFilter) {
  // Se há filtro de team, a API já filtrou os contatos no store
  // A lista de contatos em contacts.value já está filtrada pela API
  // Aplicar outros filtros locais se houver
  if (localFilters.length > 0) {
    const matchesFilters = applyContactFilters(contact, localFilters);
    if (!matchesFilters) return false;
  }
  return true; // Contato passou no filtro da API e nos filtros locais
}
```

## Estrutura de Dados

### Payload da API

```javascript
{
  payload: [
    {
      attribute_key: 'team_id',
      filter_operator: 'equal_to',  // ou 'not_equal_to', 'is_present', 'is_not_present'
      values: [1],  // Array de IDs de times
      query_operator: undefined  // undefined para o último filtro
    }
  ]
}
```

### Resposta da API

```json
{
  "payload": [
    {
      "id": 1,
      "name": "João Silva",
      "email": "joao@example.com",
      // ... outros campos do contato
    }
  ],
  "meta": {
    "count": 10,
    "current_page": 1,
    "per_page": 15
  }
}
```

## Operadores Suportados

O filtro de `team_id` suporta os seguintes operadores (definidos em `lib/filters/filter_keys.yml`):

- **`equal_to`**: Contatos com conversas em times específicos
  - SQL: `conversations.team_id IN (:value_0)`
  
- **`not_equal_to`**: Contatos com conversas que NÃO estão em times específicos
  - SQL: `conversations.team_id NOT IN (:value_0)`
  
- **`is_present`**: Contatos que possuem conversas com time atribuído
  - SQL: `conversations.team_id IS NOT NULL`
  
- **`is_not_present`**: Contatos que possuem conversas sem time atribuído
  - SQL: `conversations.team_id IS NULL`

## Exemplo de Query SQL Gerada

### Com filtro `team_id = 1`:

```sql
-- Subquery (seleciona IDs únicos)
SELECT DISTINCT contacts.id
FROM contacts
INNER JOIN conversations ON conversations.contact_id = contacts.id
WHERE conversations.team_id IN (1)

-- Query principal (aplica ORDER BY sem problemas)
SELECT contacts.*
FROM contacts
WHERE contacts.id IN (
  SELECT DISTINCT contacts.id
  FROM contacts
  INNER JOIN conversations ON conversations.contact_id = contacts.id
  WHERE conversations.team_id IN (1)
)
ORDER BY contacts.name ASC
LIMIT 15 OFFSET 0
```

## Arquivos Modificados

### Backend

1. **`app/services/contacts/filter_service.rb`**
   - Adicionado método `perform` com lógica de subquery
   - Adicionado método `query_builder_with_conversations`
   - Adicionado método `build_condition_query_for_team`
   - Modificado método `filter_values` para tratar `team_id`
   - Modificado método `equals_to_filter_string` para usar `IN`

### Frontend

1. **`app/javascript/dashboard/components-next/Contacts/Kanban/KanbanView.vue`**
   - Método `handleApplyFilter` processa valores de `team_id`

2. **`app/javascript/dashboard/components-next/Contacts/Kanban/KanbanColumn.vue`**
   - Lógica para filtrar contatos localmente quando há filtro de times

3. **`app/javascript/dashboard/components-next/Contacts/Kanban/ContactsSidebar.vue`**
   - Lógica similar ao `KanbanColumn` para filtrar na sidebar

## Configuração

O filtro `team_id` está configurado em `lib/filters/filter_keys.yml`:

```yaml
conversations:
  team_id:
    attribute_type: "standard"
    data_type: "number"
    filter_operators:
      - "equal_to"
      - "not_equal_to"
      - "is_present"
      - "is_not_present"

contacts:
  team_id:
    attribute_type: "standard"
    data_type: "number"
    filter_operators:
      - "equal_to"
      - "not_equal_to"
      - "is_present"
      - "is_not_present"
```

## Considerações de Performance

1. **Subquery vs JOIN direto**: A subquery é necessária para evitar o conflito `DISTINCT` + `ORDER BY`, mas pode ter impacto em performance com muitos contatos. Considerar índices em `conversations.team_id` e `conversations.contact_id`.

2. **Filtros locais**: Filtros como labels são aplicados no frontend para evitar múltiplas requisições à API.

3. **Paginação**: A API retorna apenas 15 contatos por página (configurado em `RESULTS_PER_PAGE`).

## Testes

Para testar o filtro:

1. Acesse o Kanban de contatos
2. Abra o filtro avançado
3. Selecione "Time" como atributo
4. Escolha um operador (ex: "Igual a")
5. Selecione um ou mais times
6. Aplique o filtro

**Resultado esperado**: Apenas contatos com conversas nos times selecionados devem aparecer no Kanban.

## Possíveis Melhorias Futuras

1. **Cache**: Cachear resultados de filtros de times para melhorar performance
2. **Índices**: Adicionar índices compostos em `(conversations.contact_id, conversations.team_id)`
3. **Otimização de subquery**: Avaliar se a subquery pode ser otimizada usando `EXISTS` ao invés de `IN`
4. **Filtros combinados**: Melhorar suporte para combinar filtro de times com outros filtros complexos

## Conclusão

A implementação do filtro de times no Kanban utiliza uma estratégia de subquery para resolver o conflito entre `DISTINCT` e `ORDER BY` no PostgreSQL. A solução mantém a compatibilidade com outros filtros e permite que o frontend aplique filtros locais adicionais quando necessário.

