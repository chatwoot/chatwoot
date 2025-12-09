# Sincronização Bidirecional de Etiquetas entre Contatos e Conversas

## 📋 Resumo Executivo

Este documento descreve a implementação da sincronização bidirecional de etiquetas (labels) entre o perfil de contatos e as conversas no Chatwoot. Quando uma etiqueta é adicionada ou removida em qualquer um dos locais, ela é automaticamente sincronizada no outro.

**Funcionalidade:** Sincronização automática de etiquetas entre:
- ✅ **Conversa → Contato**: Etiquetas adicionadas/removidas na conversa aparecem no perfil do contato
- ✅ **Contato → Conversas**: Etiquetas adicionadas/removidas no perfil do contato aparecem em todas as conversas desse contato

---

## 🎯 Objetivo

Garantir que as etiquetas associadas a um contato estejam sempre sincronizadas entre:
1. O perfil do contato (página de detalhes do contato)
2. Todas as conversas desse contato

Isso permite que os agentes vejam as mesmas etiquetas independentemente de onde elas foram adicionadas, melhorando a consistência dos dados e a experiência do usuário.

---

## 🔄 Fluxo de Sincronização

### 1. Sincronização Conversa → Contato

**Quando acontece:**
- Usuário adiciona ou remove uma etiqueta diretamente na conversa
- Etiqueta é atualizada via ActionCable (WebSocket)

**Fluxo:**
```
Conversa (UI) 
  ↓
conversationLabels/update (Vuex Action)
  ↓
ConversationAPI.updateLabels (Backend)
  ↓
Busca contactId da conversa
  ↓
contactLabels/update (Sincronização)
  ↓
Perfil do Contato atualizado
```

### 2. Sincronização Contato → Conversas

**Quando acontece:**
- Usuário adiciona ou remove uma etiqueta no perfil do contato (botão "+ etiqueta")

**Fluxo:**
```
Perfil do Contato (UI)
  ↓
contactLabels/update (Vuex Action)
  ↓
ContactAPI.updateContactLabels (Backend)
  ↓
Busca todas as conversas do contato
  ↓
Para cada conversa:
  conversationLabels/update
  ↓
Todas as conversas atualizadas
```

---

## 🏗️ Arquitetura da Implementação

### Componentes Modificados

#### 1. `store/modules/conversationLabels.js`

**Mudanças:**
- Adicionada lógica de sincronização na action `update`
- Criada action `syncContactLabels` para sincronização reutilizável
- Modificada action `setConversationLabel` para sincronizar quando atualizado via ActionCable

**Principais funções:**

```javascript
// Action principal que atualiza labels da conversa
update: async ({ commit, dispatch, rootGetters }, { conversationId, labels }) => {
  // 1. Atualiza labels da conversa
  // 2. Busca contactId da conversa
  // 3. Sincroniza com contactLabels/update
}

// Action para sincronização quando atualizado via ActionCable
setConversationLabel: ({ commit, dispatch }, { id, data }) => {
  // 1. Atualiza labels no store
  // 2. Chama syncContactLabels para sincronizar
}

// Action reutilizável para sincronização
syncContactLabels: async ({ dispatch, rootGetters }, { conversationId, labels }) => {
  // Busca contactId e sincroniza com contato
}
```

**Estratégia de busca do contactId:**
1. **Tentativa 1**: Busca do store de conversas (`conversations/getConversationById`)
2. **Tentativa 2**: Busca via API (`ConversationAPI.show()`)
3. **Tentativa 3**: Verifica resposta da API de `updateLabels`

#### 2. `components-next/Contacts/ContactLabels/ContactLabels.vue`

**Mudanças:**
- Adicionada sincronização reversa na função `handleLabelAction`
- Busca todas as conversas do contato e atualiza suas labels

**Fluxo de sincronização:**

```javascript
handleLabelAction: async ({ value }) => {
  // 1. Calcula novas labels do contato
  // 2. Atualiza labels do contato (contactLabels/update)
  // 3. Busca todas as conversas do contato (ContactAPI.getConversations)
  // 4. Para cada conversa, atualiza labels (conversationLabels/update)
}
```

---

## 📁 Arquivos Modificados

### Backend
Nenhum arquivo backend foi modificado. A sincronização utiliza as APIs existentes:
- `POST /api/v1/accounts/:account_id/conversations/:id/labels`
- `POST /api/v1/accounts/:account_id/contacts/:id/labels`
- `GET /api/v1/accounts/:account_id/contacts/:id/conversations`

### Frontend

```
app/javascript/dashboard/
├── store/
│   └── modules/
│       └── conversationLabels.js          # ✅ Modificado
└── components-next/
    └── Contacts/
        └── ContactLabels/
            └── ContactLabels.vue          # ✅ Modificado
```

---

## 🔍 Detalhes Técnicos

### 1. Sincronização Conversa → Contato

**Localização:** `store/modules/conversationLabels.js`

**Action `update`:**
- Atualiza labels da conversa via API
- Após sucesso, busca o `contactId` da conversa
- Chama `contactLabels/update` para sincronizar

**Action `setConversationLabel`:**
- Chamada quando conversa é atualizada via ActionCable
- Atualiza labels no store local
- Chama `syncContactLabels` para sincronizar com contato

**Tratamento de erros:**
- Erros de sincronização não bloqueiam a atualização principal da conversa
- Logs de debug ajudam a identificar problemas

### 2. Sincronização Contato → Conversas

**Localização:** `components-next/Contacts/ContactLabels/ContactLabels.vue`

**Função `handleLabelAction`:**
1. Calcula as novas labels baseado na ação (adicionar/remover)
2. Atualiza labels do contato via `contactLabels/update`
3. Busca todas as conversas do contato via `ContactAPI.getConversations()`
4. Para cada conversa encontrada:
   - Chama `conversationLabels/update` com as mesmas labels
   - Tratamento de erro individual para não bloquear outras conversas

**Tratamento de erros:**
- Se uma conversa falhar ao atualizar, continua com as próximas
- Logs detalhados para debug

---

## 🧪 Como Testar

### Teste 1: Sincronização Conversa → Contato

1. Abra uma conversa no Chatwoot
2. Adicione uma etiqueta (ex: "assinatura") usando o menu de etiquetas da conversa
3. Abra o perfil do contato dessa conversa
4. **Resultado esperado**: A etiqueta "assinatura" deve aparecer no perfil do contato

5. Volte para a conversa e remova a etiqueta
6. Volte para o perfil do contato
7. **Resultado esperado**: A etiqueta deve ter desaparecido do perfil

### Teste 2: Sincronização Contato → Conversas

1. Abra o perfil de um contato (ex: "Matheusteste")
2. Adicione uma etiqueta (ex: "duvida") usando o botão "+ etiqueta"
3. Abra uma conversa desse contato
4. **Resultado esperado**: A etiqueta "duvida" deve aparecer na conversa

5. Volte para o perfil do contato e remova a etiqueta
6. Volte para a conversa
7. **Resultado esperado**: A etiqueta deve ter desaparecido da conversa

### Teste 3: Múltiplas Conversas

1. Certifique-se de que um contato tem múltiplas conversas
2. No perfil do contato, adicione uma etiqueta
3. Abra cada conversa desse contato
4. **Resultado esperado**: A etiqueta deve aparecer em todas as conversas

---

## 🐛 Debug e Logs

A implementação inclui logs detalhados para facilitar o debug. Os logs aparecem no console do navegador (F12 → Console).

### Logs de Sincronização Conversa → Contato

```
[Sync Labels] Action update chamada: {conversationId: 5, labels: [...]}
[Sync Labels] Resposta da API: {...}
[Sync Labels] ContactId encontrado via API: 3
[Sync Labels] 🔄 Sincronizando labels do contato: {...}
[Sync Labels] ✅ Labels sincronizadas com sucesso!
```

### Logs de Sincronização Contato → Conversas

```
[ContactLabels] Atualizando labels do contato: {contactId: 3, labels: [...]}
[ContactLabels] Buscando conversas do contato para sincronizar...
[ContactLabels] Conversas encontradas: 2
[ContactLabels] Sincronizando labels da conversa: {conversationId: 5, labels: [...]}
[ContactLabels] ✅ Labels sincronizadas para conversa: 5
[ContactLabels] ✅ Sincronização completa!
```

### Logs de Erro

```
[Sync Labels] ❌ Erro ao sincronizar labels do contato: Error...
[ContactLabels] ❌ Erro ao sincronizar labels com conversas: Error...
```

---

## ⚠️ Considerações Importantes

### Performance

- **Sincronização Contato → Conversas**: Quando um contato tem muitas conversas, todas serão atualizadas. Isso pode causar múltiplas chamadas à API.
- **Otimização futura**: Poderia ser implementado um batch update no backend para atualizar múltiplas conversas de uma vez.

### Tratamento de Erros

- Erros de sincronização **não bloqueiam** a operação principal
- Se a sincronização falhar, a etiqueta ainda será adicionada/removida no local onde foi solicitada
- Logs de erro ajudam a identificar problemas sem interromper o fluxo do usuário

### Race Conditions

- Se uma etiqueta for adicionada simultaneamente na conversa e no perfil, ambas as sincronizações podem ocorrer
- A última atualização prevalece (comportamento esperado)

### ActionCable (WebSocket)

- Quando uma conversa é atualizada via ActionCable, a sincronização também ocorre automaticamente
- Isso garante que mudanças feitas por outros usuários também sejam sincronizadas

---

## 🔮 Melhorias Futuras

1. **Batch Update**: Implementar endpoint no backend para atualizar múltiplas conversas de uma vez
2. **Cache de Conversas**: Cachear a lista de conversas do contato para evitar múltiplas chamadas
3. **Otimização de Performance**: Debounce para evitar múltiplas sincronizações rápidas
4. **Feedback Visual**: Indicador de sincronização em progresso na UI
5. **Configuração**: Permitir desabilitar sincronização bidirecional se necessário

---

## 📝 Notas de Desenvolvimento

### Decisões de Design

1. **Sincronização "Best Effort"**: A sincronização não bloqueia a operação principal. Se falhar, a etiqueta ainda é atualizada no local solicitado.

2. **Múltiplas Tentativas de Busca**: O `contactId` é buscado de múltiplas fontes (store, API) para garantir que seja encontrado mesmo em diferentes estados da aplicação.

3. **Logs Detalhados**: Logs extensivos facilitam o debug durante desenvolvimento e produção.

4. **Tratamento Individual de Erros**: Quando sincronizando múltiplas conversas, cada uma é tratada individualmente para não bloquear as outras.

### Compatibilidade

- ✅ Compatível com o sistema de etiquetas existente
- ✅ Não quebra funcionalidades existentes
- ✅ Funciona com ActionCable/WebSocket
- ✅ Suporta múltiplas conversas por contato

---

## 📚 Referências

- **Vuex Store Modules**: `store/modules/conversationLabels.js`, `store/modules/contactLabels.js`
- **API Endpoints**: 
  - `POST /api/v1/accounts/:account_id/conversations/:id/labels`
  - `POST /api/v1/accounts/:account_id/contacts/:id/labels`
  - `GET /api/v1/accounts/:account_id/contacts/:id/conversations`
- **Componentes Vue**: `components-next/Contacts/ContactLabels/ContactLabels.vue`

---

## ✅ Status da Implementação

- ✅ Sincronização Conversa → Contato: **Implementado e Funcionando**
- ✅ Sincronização Contato → Conversas: **Implementado e Funcionando**
- ✅ Suporte a ActionCable: **Implementado e Funcionando**
- ✅ Tratamento de Erros: **Implementado**
- ✅ Logs de Debug: **Implementado**

---

*Documento criado em: Dezembro 2025*  
*Última atualização: Dezembro 2025*
