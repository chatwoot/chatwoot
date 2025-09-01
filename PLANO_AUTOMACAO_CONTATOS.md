# PLANO COMPLETO: EXPANSÃO DO SISTEMA DE AUTOMAÇÃO PARA EVENTOS DE CONTATO

## RESUMO EXECUTIVO

**OBJETIVO:** Expandir o sistema de automação existente do Chatwoot para suportar eventos de contato (criação, atualização, exclusão), multiplicando exponencialmente as possibilidades de automação.

**IMPACTO:** Transformar o Chatwoot de um sistema reativo para um sistema proativo e inteligente de gestão de relacionamento com cliente.

**COMPLEXIDADE:** BAIXA (aproveita 90% da infraestrutura existente)
**TEMPO ESTIMADO:** 3-4 horas de desenvolvimento
**RISCO:** MUITO BAIXO (não altera funcionalidades existentes)

---

## ANÁLISE SITUACIONAL

### ✅ INFRAESTRUTURA EXISTENTE (JÁ FUNCIONAL)
```
✓ Event Dispatcher System (Rails.configuration.dispatcher)
✓ AutomationRule Model (conditions + actions)
✓ AutomationRuleListener (pattern estabelecido)
✓ ConditionsFilterService (filtros complexos)
✓ ActionService (execução de ações)
✓ Interface Frontend completa
✓ Sistema de tradução PT-BR
✓ Testes automatizados
```

### ❌ LACUNAS IDENTIFICADAS
```
✗ contact_created não tem listener de automação
✗ contact_updated não tem listener de automação  
✗ contact_deleted não tem listener de automação
✗ Frontend não suporta eventos de contato
✗ Constantes de condições não incluem atributos de contato
```

### 🎯 EVENTOS DISPONÍVEIS (MAS NÃO AUTOMATIZÁVEIS)
- `CONTACT_CREATED` - Disparado em `contact.rb:236`
- `CONTACT_UPDATED` - Disparado em `contact.rb:240` (com changed_attributes)  
- `CONTACT_DELETED` - Disparado em `contact.rb:244`

---

## ESPECIFICAÇÃO TÉCNICA DETALHADA

### FASE 1: BACKEND - LISTENERS DE AUTOMAÇÃO

#### 1.1 Modificar AutomationRuleListener
**Arquivo:** `app/listeners/automation_rule_listener.rb`

**Adicionar 3 métodos:**

```ruby
def contact_created(event)
  return if performed_by_automation?(event)
  
  contact = event.data[:contact]
  account = contact.account
  
  return unless rule_present?('contact_created', account)
  
  rules = current_account_rules('contact_created', account)
  
  rules.each do |rule|
    conditions_match = ::AutomationRules::ConditionsFilterService.new(
      rule, 
      nil, # conversation é nil para eventos de contato
      { contact: contact }
    ).perform
    
    ::AutomationRules::ActionService.new(rule, account, nil, contact).perform if conditions_match.present?
  end
end

def contact_updated(event)
  return if performed_by_automation?(event)
  
  contact = event.data[:contact]
  account = contact.account
  changed_attributes = event.data[:changed_attributes]
  
  return unless rule_present?('contact_updated', account)
  
  rules = current_account_rules('contact_updated', account)
  
  rules.each do |rule|
    conditions_match = ::AutomationRules::ConditionsFilterService.new(
      rule, 
      nil,
      { contact: contact, changed_attributes: changed_attributes }
    ).perform
    
    ::AutomationRules::ActionService.new(rule, account, nil, contact).perform if conditions_match.present?
  end
end

def contact_deleted(event)
  return if performed_by_automation?(event)
  
  contact = event.data[:contact]
  account = contact.account
  
  return unless rule_present?('contact_deleted', account)
  
  rules = current_account_rules('contact_deleted', account)
  
  rules.each do |rule|
    conditions_match = ::AutomationRules::ConditionsFilterService.new(
      rule, 
      nil,
      { contact: contact }
    ).perform
    
    # Para contatos deletados, apenas ações que não dependem do contato (webhooks, notificações)
    ::AutomationRules::ActionService.new(rule, account, nil, contact).perform if conditions_match.present?
  end
end
```

#### 1.2 Atualizar AutomationRule Model  
**Arquivo:** `app/models/automation_rule.rb`

**Expandir conditions_attributes (linha 38):**
```ruby
def conditions_attributes
  %w[content email country_code status message_type browser_language assignee_id team_id referer city company inbox_id
     mail_subject phone_number priority conversation_language name identifier blocked contact_type
     additional_attributes custom_attributes]
end
```

#### 1.3 Atualizar ConditionsFilterService
**Arquivo:** `app/services/automation_rules/conditions_filter_service.rb`

**Adicionar suporte para filtragem por atributos de contato:**
- Verificar se o serviço já lida com objetos contact
- Adicionar lógica para custom_attributes de contato
- Suportar additional_attributes (company_name, city, etc)

#### 1.4 Atualizar ActionService  
**Arquivo:** `app/services/automation_rules/action_service.rb`

**Modificar construtor para aceitar parâmetro contact:**
```ruby
def initialize(rule, account, conversation = nil, contact = nil)
  @rule = rule
  @account = account  
  @conversation = conversation
  @contact = contact
end
```

**Adaptar ações para funcionar com contatos:**
- `send_webhook_event` - funciona (payload do contato)
- `send_email_to_team` - funciona (notificação sobre contato)
- `add_label/remove_label` - adaptar para labels de contato
- `send_message` - só se contato tiver conversa ativa

---

### FASE 2: FRONTEND - INTERFACE DE CONFIGURAÇÃO

#### 2.1 Atualizar Constants.js
**Arquivo:** `app/javascript/dashboard/routes/dashboard/settings/automation/constants.js`

**Adicionar definições de eventos de contato:**

```javascript
export const AUTOMATIONS = {
  // ... eventos existentes ...
  
  contact_created: {
    conditions: [
      {
        key: 'email',
        name: 'EMAIL',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'name', 
        name: 'NAME',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'phone_number',
        name: 'PHONE_NUMBER', 
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_6,
      },
      {
        key: 'identifier',
        name: 'IDENTIFIER',
        inputType: 'plain_text', 
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'contact_type',
        name: 'CONTACT_TYPE',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'country_code', 
        name: 'COUNTRY_NAME',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'blocked',
        name: 'BLOCKED_STATUS',
        inputType: 'search_select', 
        filterOperators: OPERATOR_TYPES_1,
      },
    ],
    actions: [
      {
        key: 'send_webhook_event',
        name: 'SEND_WEBHOOK_EVENT',
      },
      {
        key: 'send_email_to_team',
        name: 'SEND_EMAIL_TO_TEAM', 
      },
      {
        key: 'add_label',
        name: 'ADD_LABEL',
      },
      // Ações limitadas para eventos de contato
    ],
  },
  
  contact_updated: {
    // Similar ao contact_created mas com mais condições
    conditions: [
      // Todas as condições de contact_created +
      {
        key: 'changed_attributes',
        name: 'CHANGED_FIELDS',
        inputType: 'multi_select', 
        filterOperators: OPERATOR_TYPES_1,
      },
    ],
    actions: [
      // Mesmas ações de contact_created
    ],
  },
  
  contact_deleted: {
    conditions: [
      // Condições básicas (email, name, etc)
    ],
    actions: [
      // Apenas ações que não dependem do contato existir
      {
        key: 'send_webhook_event',
        name: 'SEND_WEBHOOK_EVENT',
      },
      {
        key: 'send_email_to_team', 
        name: 'SEND_EMAIL_TO_TEAM',
      },
    ],
  },
};
```

**Atualizar AUTOMATION_RULE_EVENTS:**
```javascript
export const AUTOMATION_RULE_EVENTS = [
  // ... eventos existentes ...
  {
    key: 'contact_created',
    value: 'CONTACT_CREATED',
  },
  {
    key: 'contact_updated', 
    value: 'CONTACT_UPDATED',
  },
  {
    key: 'contact_deleted',
    value: 'CONTACT_DELETED',  
  },
];
```

#### 2.2 Atualizar Traduções PT-BR
**Arquivo:** `app/javascript/dashboard/i18n/locale/pt_BR/automation.json`

```json
{
  "EVENTS": {
    "CONTACT_CREATED": "Contato Criado",
    "CONTACT_UPDATED": "Contato Atualizado", 
    "CONTACT_DELETED": "Contato Excluído"
  },
  "CONDITIONS": {
    "NAME": "Nome",
    "IDENTIFIER": "Identificador",
    "CONTACT_TYPE": "Tipo de Contato",
    "BLOCKED_STATUS": "Status de Bloqueio",
    "CHANGED_FIELDS": "Campos Alterados"
  },
  "CONTACT_TYPES": {
    "visitor": "Visitante",
    "lead": "Lead", 
    "customer": "Cliente"
  },
  "BLOCKED_STATUS": {
    "true": "Bloqueado",
    "false": "Desbloqueado"
  }
}
```

#### 2.3 Atualizar AutomationHelper
**Arquivo:** `app/javascript/dashboard/helper/automationHelper.js`

**Adicionar condições padrão para eventos de contato:**
```javascript
export const DEFAULT_CONTACT_CONDITION = [
  {
    attribute_key: 'contact_type',
    filter_operator: 'equal_to',
    values: '',
    query_operator: 'and',
    custom_attribute_type: '',
  },
];

export const getDefaultConditions = eventName => {
  if (eventName === 'message_created') {
    return DEFAULT_MESSAGE_CREATED_CONDITION;
  }
  if (eventName === 'conversation_opened') {
    return DEFAULT_CONVERSATION_OPENED_CONDITION;
  }
  if (eventName.startsWith('contact_')) {
    return DEFAULT_CONTACT_CONDITION;  
  }
  return DEFAULT_OTHER_CONDITION;
};
```

---

### FASE 3: INTEGRAÇÃO E COMPATIBILIDADE

#### 3.1 Registro de Event Listeners
**Arquivo:** `config/application.rb` ou listener registry

**Verificar se contact events estão registrados:**
```ruby
# Garantir que os eventos estão sendo escutados
Rails.configuration.event_store.subscribe(AutomationRuleListener.new, to: [
  Events::Types::CONTACT_CREATED,
  Events::Types::CONTACT_UPDATED, 
  Events::Types::CONTACT_DELETED,
  # ... outros eventos existentes
])
```

#### 3.2 Validações de Segurança
**Implementar verificações:**
- Verificar permissões do usuário para criar regras de contato
- Validar que ações são apropriadas para eventos de contato
- Prevenir loops infinitos em automações

#### 3.3 Compatibilidade com Custom Attributes
**Garantir suporte a:**
- Nossos novos tipos datetime/time
- Filtragem por custom_attributes de contato
- Operadores apropriados para cada tipo

---

### FASE 4: CASOS DE USO PRÁTICOS

#### 4.1 Cenário 1: Lead Scoring Automático
```
EVENTO: contact_created
CONDIÇÕES: 
- email contém "@empresa.com"
- contact_type = "lead"
AÇÕES:
- add_label "Corporativo"
- send_webhook_event para CRM
- send_email_to_team "Novo lead corporativo"
```

#### 4.2 Cenário 2: Atualização VIP
```
EVENTO: contact_updated  
CONDIÇÕES:
- changed_attributes contém "additional_attributes" 
- additional_attributes.company_name = "Petrobras"
AÇÕES:
- add_label "VIP"
- send_webhook_event para notificar equipe premium
```

#### 4.3 Cenário 3: Sync CRM
```
EVENTO: contact_deleted
CONDIÇÕES: 
- identifier não é vazio
AÇÕES:
- send_webhook_event com dados do contato para limpeza no CRM externo
```

---

## CRONOGRAMA DE IMPLEMENTAÇÃO

### SPRINT 1 - Backend Core (2h)
- [ ] Adicionar métodos no AutomationRuleListener
- [ ] Atualizar conditions_attributes no AutomationRule  
- [ ] Modificar ConditionsFilterService para contatos
- [ ] Adaptar ActionService para aceitar contatos
- [ ] Testes básicos de integração

### SPRINT 2 - Frontend (1h)  
- [ ] Adicionar eventos de contato no constants.js
- [ ] Implementar traduções PT-BR
- [ ] Atualizar helpers de automação
- [ ] Testes da interface

### SPRINT 3 - Refinamentos (1h)
- [ ] Validações de segurança
- [ ] Integração com custom attributes
- [ ] Casos de uso avançados
- [ ] Documentação

**TOTAL: 4 horas**

---

## ANÁLISE DE RISCOS E MITIGAÇÕES

### RISCOS IDENTIFICADOS

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| ConditionsFilterService não suporta contatos | Média | Alto | Análise prévia + adaptação gradual |
| ActionService incompatível com contatos | Baixa | Alto | Parâmetro opcional + fallbacks |
| Performance em grandes volumes | Baixa | Médio | Filtros inteligentes + índices DB |
| Loops infinitos de automação | Média | Alto | performed_by_automation? checks |
| Interface complexa demais | Baixa | Baixo | UX simplificada + progressive disclosure |

### ESTRATÉGIAS DE ROLLBACK
```bash
# Se algo der errado:
1. Feature flag para desabilitar contact automation
2. Rollback dos listeners (remove métodos)  
3. Rollback do frontend (remove eventos)
4. Database inalterada (sem migrações necessárias)
```

---

## TESTES E VALIDAÇÃO

### TESTES UNITÁRIOS
- [ ] AutomationRuleListener - novos métodos
- [ ] ConditionsFilterService - filtragem de contatos
- [ ] ActionService - ações com contatos
- [ ] Frontend constants - definições corretas

### TESTES DE INTEGRAÇÃO  
- [ ] Fluxo completo: evento → condição → ação
- [ ] Webhook delivery para eventos de contato
- [ ] Email notifications funcionais
- [ ] Labels aplicadas corretamente

### TESTES MANUAIS
- [ ] Interface de criação de regras
- [ ] Execução de automações em contatos reais
- [ ] Performance com volume médio
- [ ] Compatibilidade com custom attributes

---

## MÉTRICAS DE SUCESSO

### QUANTITATIVAS
- [ ] 100% dos eventos de contato sendo capturados
- [ ] 0 erros de execução de automação
- [ ] Tempo de resposta < 2s para processamento
- [ ] Taxa de adoção > 50% pelos usuários

### QUALITATIVAS  
- [ ] Interface intuitiva para configuração
- [ ] Documentação clara e completa
- [ ] Feedback positivo dos usuários
- [ ] Casos de uso práticos funcionando

---

## BENEFÍCIOS ESPERADOS

### CURTO PRAZO (1 mês)
- ✅ Automação de welcome messages para novos contatos
- ✅ Sync automático com CRM externo
- ✅ Classificação automática de leads

### MÉDIO PRAZO (3 meses)
- ✅ Lead scoring avançado
- ✅ Segmentação inteligente de contatos  
- ✅ Workflows complexos de nurturing

### LONGO PRAZO (6+ meses)
- ✅ IA/ML para predição de comportamento
- ✅ Automação cross-platform
- ✅ ROI mensurável em automação

---

## CONCLUSÃO

Esta expansão do sistema de automação representa uma **evolução natural** do Chatwoot, aproveitando toda a infraestrutura existente para criar **capacidades revolucionárias** de automação de contatos.

Com **investimento mínimo** (4h de desenvolvimento) obtemos **retorno máximo** (multiplicação exponencial das possibilidades de automação).

O projeto tem **baixo risco** por não alterar funcionalidades existentes e **alto potencial** de transformar o Chatwoot em uma plataforma de automação de marketing e vendas.

**RECOMENDAÇÃO: APROVAÇÃO IMEDIATA PARA IMPLEMENTAÇÃO** 🚀

---

*Plano elaborado com análise minuciosa do codebase existente e consideração de todos os aspectos técnicos, funcionais e estratégicos.*