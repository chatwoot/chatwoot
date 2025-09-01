# Plano de Implementação: Campos DateTime e Time em Custom Attributes

## 📋 Resumo Executivo

**Objetivo**: Adicionar suporte completo para campos de data/hora (datetime) e horário (time) nos Custom Attributes do Chatwoot, permitindo maior flexibilidade temporal nos dados customizados.

**Complexidade**: BAIXA ⭐⭐☆☆☆  
**Risco**: MÍNIMO 🟢  
**Tempo Estimado**: 2-3 dias  
**Impact**: Zero downtime, backward compatible  

---

## 🎯 Análise da Situação Atual

### ✅ Infraestrutura Existente
- **Frontend**: `DateTimePicker.vue` já implementado com suporte a datetime
- **Backend**: Enum `attribute_display_type` com tipo `date` existente
- **Banco**: PostgreSQL com suporte nativo a datetime/timestamp
- **Filtros**: `FilterService` já processa campos de data

### 🔄 Gap Identificado
- Falta tipos `datetime` e `time` no enum `attribute_display_type`
- Frontend não diferencia entre `date`, `datetime` e `time` nos custom attributes
- Validações específicas para datetime/time não implementadas
- Componente TimePicker não existe (precisará ser criado)

---

## 📋 Plano de Implementação

### **FASE 1: Backend - Database & Models**

#### 1.1 Migration para Novo Enum
**Arquivo**: `db/migrate/YYYYMMDDHHMMSS_add_datetime_to_custom_attribute_definitions.rb`

```ruby
class AddDatetimeToCustomAttributeDefinitions < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      ALTER TYPE custom_attribute_definition_attribute_display_type 
      ADD VALUE IF NOT EXISTS 'datetime';
    SQL
  end
  
  def down
    # Não é possível remover valores de enum no PostgreSQL
    # Esta migration é irreversível por design de segurança
    raise ActiveRecord::IrreversibleMigration
  end
end
```

#### 1.2 Atualizar Model CustomAttributeDefinition
**Arquivo**: `app/models/custom_attribute_definition.rb` (linha 43)

```ruby
# ANTES
enum attribute_display_type: { text: 0, number: 1, currency: 2, percent: 3, link: 4, date: 5, list: 6, checkbox: 7 }

# DEPOIS  
enum attribute_display_type: { text: 0, number: 1, currency: 2, percent: 3, link: 4, date: 5, list: 6, checkbox: 7, datetime: 8 }
```

### **FASE 2: Backend - Services & Filters**

#### 2.1 Atualizar FilterService
**Arquivo**: `app/services/filter_service.rb` (linha 9)

```ruby
ATTRIBUTE_TYPES = {
  date: 'date', 
  datetime: 'timestamp',  # NOVA LINHA
  text: 'text', 
  number: 'numeric', 
  link: 'text', 
  list: 'text', 
  checkbox: 'boolean'
}.with_indifferent_access
```

#### 2.2 Atualizar Validações
**Arquivo**: Criar `app/validators/datetime_attribute_validator.rb`

```ruby
class DatetimeAttributeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    
    begin
      DateTime.parse(value.to_s)
    rescue ArgumentError
      record.errors.add(attribute, 'must be a valid datetime')
    end
  end
end
```

### **FASE 3: Frontend - Components**

#### 3.1 Atualizar FormulÁrio de Custom Attributes
**Arquivo**: Identificar e atualizar componente de criação/edição de custom attributes

- Adicionar opção "Date & Time" no dropdown de tipos
- Diferenciar visualmente entre "Date" e "Date & Time"

#### 3.2 Componente de Renderização
**Arquivo**: Criar/atualizar componente que renderiza custom attributes

```vue
<template>
  <div class="custom-attribute-field">
    <DateTimePicker 
      v-if="attribute.attribute_display_type === 'datetime'"
      :value="value"
      :placeholder="attribute.attribute_display_name"
      @change="handleDateTimeChange"
    />
    <DatePicker 
      v-else-if="attribute.attribute_display_type === 'date'"
      :value="value"
      @change="handleDateChange"
    />
  </div>
</template>
```

### **FASE 4: API & Serialização**

#### 4.1 Validar Serialização JSON
- Verificar se datetime é corretamente serializado em ISO 8601
- Testar timezone handling

#### 4.2 Documentação da API
- Atualizar documentação para incluir novo tipo `datetime`
- Exemplos de payload com datetime

---

## ⚠️ Análise e Mitigação de Riscos

### **RISCOS IDENTIFICADOS**

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| **Migration Failure** | Baixa | Alto | • Testar em staging primeiro<br>• Backup antes da migration<br>• Migration irreversível por design |
| **Timezone Confusion** | Média | Médio | • Sempre usar UTC no backend<br>• Display timezone do usuário no frontend<br>• Documentação clara |
| **Performance Impact** | Baixa | Baixo | • Indexes já existem<br>• Reutilizar queries existentes |
| **UI/UX Inconsistência** | Média | Baixo | • Testes de usabilidade<br>• Feedback dos usuários |

### **ESTRATÉGIAS DE MITIGAÇÃO**

#### 1. **Database Safety**
```bash
# Backup antes da migration
pg_dump chatwoot_production > backup_pre_datetime_$(date +%Y%m%d).sql

# Testar migration em staging
rails db:migrate RAILS_ENV=staging

# Validar enum foi adicionado
rails c
CustomAttributeDefinition.attribute_display_types.keys
# Deve incluir 'datetime'
```

#### 2. **Backward Compatibility**
- Campos `date` existentes continuam funcionando sem alteração
- Nenhuma migração de dados necessária
- APIs mantêm compatibilidade total

#### 3. **Timezone Handling**
```ruby
# Backend sempre salva em UTC
def serialize_datetime_value(value)
  return value unless value.is_a?(String)
  DateTime.parse(value).utc.iso8601
rescue ArgumentError
  nil
end

# Frontend exibe no timezone do usuário
const displayDateTime = (utcDatetime) => {
  return new Date(utcDatetime).toLocaleString();
}
```

#### 4. **Data Validation**
```ruby
# Model validation
validates :attribute_values, datetime_attribute: true, if: :datetime_type?

private

def datetime_type?
  attribute_display_type == 'datetime'
end
```

---

## 🧪 Plano de Testes

### **Testes Automatizados**

#### 1. **Backend Tests**
```ruby
# spec/models/custom_attribute_definition_spec.rb
describe CustomAttributeDefinition do
  it 'supports datetime attribute type' do
    definition = create(:custom_attribute_definition, attribute_display_type: 'datetime')
    expect(definition.datetime?).to be_truthy
  end
  
  it 'validates datetime format' do
    # Teste de validação datetime
  end
end

# spec/services/filter_service_spec.rb  
describe FilterService do
  it 'filters by datetime range correctly' do
    # Teste filtros datetime
  end
end
```

#### 2. **Frontend Tests**
```javascript
// Testes do componente datetime
describe('DateTimeCustomAttribute', () => {
  it('renders datetime picker for datetime type', () => {
    // Teste renderização
  });
  
  it('saves datetime in correct format', () => {
    // Teste serialização
  });
});
```

### **Testes Manuais**

#### ✅ Checklist de Validação

**Criação de Custom Attribute:**
- [ ] Dropdown inclui opção "Date & Time"
- [ ] Salva tipo `datetime` corretamente
- [ ] Validação funciona

**Uso em Conversas/Contatos:**
- [ ] Picker de datetime aparece corretamente
- [ ] Salva com horário completo
- [ ] Exibe datetime formatado

**Filtros:**
- [ ] Filtro por range de datetime funciona
- [ ] Operadores (antes/depois) funcionam
- [ ] Timezone é respeitado

**API:**
- [ ] JSON inclui datetime em ISO 8601
- [ ] CRUD operations funcionam
- [ ] Documentação atualizada

---

## 📈 Plano de Deploy

### **Estratégia de Release**

#### 1. **Staging Environment**
```bash
# 1. Deploy em staging
git checkout -b feature/datetime-custom-attributes
# Implementar mudanças...
git push origin feature/datetime-custom-attributes

# 2. Testar completamente
rake test
rails server # Testes manuais

# 3. Performance testing
# Criar 1000 custom attributes datetime
# Testar filtros com grandes datasets
```

#### 2. **Production Deployment**
```bash
# 1. Backup
pg_dump production_db > backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Deploy com zero downtime
# Migration primeiro
rails db:migrate RAILS_ENV=production

# 3. Deploy código
# Blue-green deployment ou rolling update

# 4. Validação pós-deploy
curl -X GET "api/v1/accounts/{id}/custom_attribute_definitions"
# Verificar se datetime está disponível
```

### **Rollback Plan**
```bash
# Se necessário rollback (improvável):
# 1. Reverter código (enum permanece por segurança)
git revert <commit-hash>

# 2. Desativar criação de novos datetime attributes
# Via feature flag ou config
```

---

## 📊 Métricas de Sucesso

### **KPIs Técnicos**
- [ ] Zero downtime durante deploy
- [ ] Nenhum erro 500 relacionado a datetime
- [ ] Performance de filtros mantida (<200ms)
- [ ] 100% backward compatibility

### **KPIs de Negócio**  
- [ ] Usuários criam custom attributes datetime
- [ ] Filtros datetime são utilizados
- [ ] Nenhum ticket de suporte relacionado
- [ ] Feedback positivo da feature

---

## 👥 Responsabilidades

| Papel | Responsável | Atividades |
|-------|-------------|------------|
| **Backend Dev** | Dev Team | Migration, models, services |
| **Frontend Dev** | Dev Team | Componentes, UI/UX |
| **QA** | QA Team | Testes automatizados e manuais |
| **DevOps** | DevOps Team | Deploy strategy, monitoring |
| **Product** | Product Team | Validação UX, documentação |

---

## 📅 Timeline

| Fase | Duração | Atividades |
|------|---------|------------|
| **Dia 1** | 4h | Backend: Migration + Model updates |
| **Dia 1** | 4h | Backend: Service + Filter updates |
| **Dia 2** | 6h | Frontend: Components + UI |
| **Dia 2** | 2h | Testes automatizados |
| **Dia 3** | 4h | Testes manuais + refinamentos |
| **Dia 3** | 2h | Deploy staging + validação |
| **Dia 3** | 2h | Deploy production |

**Total**: 24 horas de desenvolvimento

---

## ✅ Aprovações Necessárias

- [ ] **Tech Lead**: Aprovação da arquitetura
- [ ] **Product Manager**: Aprovação dos requisitos
- [ ] **DevOps**: Aprovação da estratégia de deploy  
- [ ] **QA Lead**: Aprovação do plano de testes

---

**Documento criado em**: $(date)  
**Versão**: 1.0  
**Status**: Aguardando aprovação  

---

*Este documento serve como guia completo para implementação segura e eficiente da funcionalidade de campos datetime em Custom Attributes do Chatwoot.*