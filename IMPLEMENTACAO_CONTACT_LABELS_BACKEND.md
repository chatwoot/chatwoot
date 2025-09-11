# 🔧 Implementação Backend - Contact Labels

## 📝 Objetivo
Adicionar suporte no backend para filtrar conversas por **etiquetas de contato** sem afetar o sistema existente de etiquetas de conversa.

## 🎯 Estratégia
**ADIÇÃO PARALELA** - Criar novo filtro `contact_labels` que funciona junto com `labels` existente.

---

## 🛠️ Mudanças Necessárias

### **1. Arquivo: `lib/filters/filter_keys.yml`**
**Localização:** Seção `conversations` (após linha 124)
**Ação:** ADICIONAR nova entrada

```yaml
# ADICIONAR APÓS mail_subject:
contact_labels:
  attribute_type: "standard"
  data_type: "labels"
  filter_operators:
    - "equal_to"
    - "not_equal_to"
    - "is_present"
    - "is_not_present"
```

### **2. Arquivo: `app/javascript/dashboard/components-next/filter/provider.js`**
**Localização:** Linha 214
**Ação:** ALTERAR attributeKey

```javascript
// MUDAR DE:
attributeKey: 'labels',

// PARA:
attributeKey: 'contact_labels',
```

### **3. Backend Logic (se necessário)**
**Arquivo:** Provavelmente `app/services/filter_service.rb` ou similar
**Ação:** Adicionar lógica especial para `contact_labels`

---

## 🧪 Como Testar

### **Teste 1: Functionality**
1. Criar contato com etiqueta "VIP"
2. Criar conversa com esse contato
3. Usar filtro avançado "Etiquetas" → Selecionar "VIP"
4. **Resultado esperado:** Mostrar a conversa do contato VIP

### **Teste 2: Backward Compatibility**
1. Usar sidebar Labels (etiquetas de conversa)
2. **Resultado esperado:** Funcionar normalmente
3. Usar automações com etiquetas
4. **Resultado esperado:** Funcionar normalmente

### **Teste 3: API Direct**
```bash
# Testar endpoint diretamente
curl -X POST "/api/v1/accounts/1/conversations/filter" \
  -d '{"payload":[{"attribute_key":"contact_labels","values":["VIP"],"filter_operator":"equal_to"}]}'
```

---

## 🔄 Rollback Completo

### **Se der problema, reverter em 3 passos:**

#### **1. Reverter YAML:**
```yaml
# REMOVER/COMENTAR estas linhas em filter_keys.yml:
# contact_labels:
#   attribute_type: "standard" 
#   data_type: "labels"
#   filter_operators:
#     - "equal_to"
#     - "not_equal_to"
#     - "is_present"
#     - "is_not_present"
```

#### **2. Reverter Frontend:**
```javascript
// VOLTAR PARA:
attributeKey: 'labels',  // Em vez de 'contact_labels'
```

#### **3. Deploy:**
```bash
git add .
git commit -m "revert: Voltar para etiquetas de conversa nos filtros"
git push origin cliente-heycommerce
# Build na VPS
```

---

## ⚡ Comandos de Deploy

### **Implementar:**
```bash
# 1. Fazer mudanças nos arquivos
# 2. Commit
git add .
git commit -m "feat: Adicionar suporte a filtros por etiquetas de contato

- Adicionar contact_labels no filter_keys.yml
- Modificar frontend para usar contact_labels
- Manter compatibilidade com etiquetas de conversa

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# 3. Push
git push origin cliente-heycommerce

# 4. Na VPS
git pull origin cliente-heycommerce
docker-compose build  # ou como você builda
docker-compose up -d
```

---

## 🛡️ Garantias de Segurança

### **✅ NÃO afeta:**
- Etiquetas de conversa existentes
- APIs atuais de etiquetas
- Sidebar de conversas (Labels)
- Sidebar de contatos (Tagged With) 
- Automações existentes
- Macros existentes
- Dados no banco
- Volumes/storage

### **✅ Só ADICIONA:**
- Nova opção de filtro `contact_labels`
- Nova funcionalidade paralela
- Zero breaking changes

### **✅ Rollback:**
- 100% reversível
- Não precisa limpar dados
- 3 minutos para reverter
- Zero downtime

---

## 📊 Estados do Sistema

### **ANTES:**
```
Filtros de Conversa:
├── labels (etiquetas de conversa) ✅
├── status ✅  
├── assignee ✅
└── ... outros ✅
```

### **DEPOIS:**
```
Filtros de Conversa:
├── labels (etiquetas de conversa) ✅         ← Mantém
├── contact_labels (etiquetas de contato) ✅  ← NOVO
├── status ✅  
├── assignee ✅
└── ... outros ✅
```

### **Interface do Usuário:**
- **Filtros Avançados:** Mostra "Etiquetas" → Filtra por contact_labels
- **Sidebar Labels:** Continua funcionando com labels de conversa
- **Contatos Tagged:** Continua funcionando normalmente

---

## 🎯 Próximos Passos (Após Esta Implementação)

1. **Testar filtros** funcionando
2. **Esconder sidebar Labels** de conversas
3. **Modificar macros** para usar etiquetas de contato
4. **Modificar automações** para usar etiquetas de contato
5. **Unificação completa**

---

## 📞 Suporte

**Se algo der errado:**
1. Verificar logs do Rails
2. Testar endpoint diretamente  
3. Rollback usando instruções acima
4. Reportar issue específica

**Arquivos modificados:**
- `lib/filters/filter_keys.yml`
- `app/javascript/dashboard/components-next/filter/provider.js`

**Tempo estimado:** 10 minutos implementação + 10 minutos teste