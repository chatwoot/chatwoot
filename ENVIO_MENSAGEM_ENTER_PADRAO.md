# ⌨️ Mudança do Comportamento Padrão: Enter para Enviar Mensagens

Este documento detalha a alteração do comportamento padrão de envio de mensagens de `Shift+Enter` para apenas `Enter`.

## 🎯 **Funcionalidade Implementada**

### **Antes da Mudança:**
- **Padrão:** `Shift+Enter` (ou `Cmd+Enter` no Mac) para enviar
- **Opcional:** `Enter` simples (usuário precisava ativar)

### **Depois da Mudança:**
- **Padrão:** `Enter` simples para enviar
- **Opcional:** `Shift+Enter` (usuário pode escolher se preferir)

### **Resultado:**
- ✅ **Novos usuários:** Enter simples por padrão (mais intuitivo)
- ✅ **Usuários existentes:** Mantém configuração escolhida anteriormente
- ✅ **Flexibilidade:** Ainda permite alternar entre os dois modos

---

## 🔧 **Alteração Técnica**

### **Arquivo Modificado:**
`app/javascript/dashboard/composables/useUISettings.js`

### **Localização:** Linha 115 (função `isEditorHotKeyEnabled`)

### **ANTES:**
```javascript
/**
 * Checks if a specific editor hotkey is enabled.
 * @param {string} key - The key to check.
 * @param {Object} uiSettings - Reactive UI settings object.
 * @returns {boolean} True if the hotkey is enabled, otherwise false.
 */
const isEditorHotKeyEnabled = (key, uiSettings) => {
  const {
    editor_message_key: editorMessageKey,
    enter_to_send_enabled: enterToSendEnabled,
  } = uiSettings.value || {};
  if (!editorMessageKey) {
    return key === (enterToSendEnabled ? 'enter' : 'cmd_enter');
  }
  return editorMessageKey === key;
};
```

### **DEPOIS:**
```javascript
/**
 * Checks if a specific editor hotkey is enabled.
 * @param {string} key - The key to check.
 * @param {Object} uiSettings - Reactive UI settings object.
 * @returns {boolean} True if the hotkey is enabled, otherwise false.
 */
const isEditorHotKeyEnabled = (key, uiSettings) => {
  const {
    editor_message_key: editorMessageKey,
    enter_to_send_enabled: enterToSendEnabled,
  } = uiSettings.value || {};
  if (!editorMessageKey) {
    // Default changed: now uses 'enter' by default instead of 'cmd_enter'
    return key === (enterToSendEnabled === false ? 'cmd_enter' : 'enter');
  }
  return editorMessageKey === key;
};
```

---

## 🧠 **Lógica da Mudança**

### **Lógica Original:**
```javascript
enterToSendEnabled ? 'enter' : 'cmd_enter'
```
- Se `enterToSendEnabled` = `true` → usa `'enter'`
- Se `enterToSendEnabled` = `false` ou `undefined` → usa `'cmd_enter'`

### **Nova Lógica:**
```javascript
enterToSendEnabled === false ? 'cmd_enter' : 'enter'
```
- Se `enterToSendEnabled` = **explicitamente** `false` → usa `'cmd_enter'`
- Se `enterToSendEnabled` = `true` ou `undefined` → usa `'enter'`

### **Diferença Fundamental:**
- **Antes:** Padrão era `cmd_enter` quando não configurado
- **Depois:** Padrão é `enter` quando não configurado

---

## 📊 **Cenários de Comportamento**

| Configuração do Usuário | Antes da Mudança | Depois da Mudança |
|-------------------------|-------------------|-------------------|
| Não configurado (`undefined`) | `Shift+Enter` | `Enter` |
| `enter_to_send_enabled: true` | `Enter` | `Enter` |
| `enter_to_send_enabled: false` | `Shift+Enter` | `Shift+Enter` |

### **✅ Compatibilidade Garantida:**
- **Usuários que JÁ escolheram uma opção:** Não são afetados
- **Usuários novos:** Terão Enter simples como padrão
- **Configuração personalizada:** Continua funcionando normalmente

---

## 💡 **Benefícios da Mudança**

### **🎯 UX Melhorada:**
- ✅ **Mais intuitivo** para novos usuários
- ✅ **Padrão da indústria** (WhatsApp, Telegram, Discord usam Enter)
- ✅ **Menos fricção** na experiência de envio

### **🔧 Técnicos:**
- ✅ **Sem breaking changes** para usuários existentes
- ✅ **Mudança mínima** no código (1 linha)
- ✅ **Retrocompatibilidade** total

### **📱 Usabilidade:**
- ✅ **Mobile-friendly** (Enter é mais natural)
- ✅ **Menos teclas** para nova mensagem
- ✅ **Consistência** com outras plataformas de chat

---

## 🔄 **Como Reverter (Se Necessário)**

### **Reverter para Comportamento Original**

**Arquivo:** `useUISettings.js` (linha 116)

**Substituir:**
```javascript
// Default changed: now uses 'enter' by default instead of 'cmd_enter'
return key === (enterToSendEnabled === false ? 'cmd_enter' : 'enter');
```

**Por:**
```javascript
return key === (enterToSendEnabled ? 'enter' : 'cmd_enter');
```

### **Verificar Reversão:**
1. Abrir chat em conta nova/não configurada
2. Tentar enviar com `Enter` → deve quebrar linha
3. Tentar enviar com `Shift+Enter` → deve enviar mensagem

---

## 🧪 **Como Testar**

### **Teste 1: Usuário Novo (Sem Configuração)**
1. **Limpar localStorage/configurações** ou usar conta nova
2. **Digitar mensagem** no chat
3. **Pressionar Enter** → Deve enviar mensagem
4. **Pressionar Shift+Enter** → Deve quebrar linha

### **Teste 2: Usuário com Configuração Existente**
1. **Usuário que já escolheu** "Enter para enviar" → deve continuar igual
2. **Usuário que escolheu** "Shift+Enter para enviar" → deve continuar igual

### **Teste 3: Alternância Manual**
1. **Ir em Configurações** → Preferências de Chat
2. **Alternar** "Pressione Enter para enviar"
3. **Verificar comportamento** muda conforme esperado

---

## 🎛️ **Onde o Usuário Pode Mudar**

### **Localização da Configuração:**
- **Menu:** Configurações → Preferências
- **Opção:** "Pressione Enter para enviar mensagens"
- **Toggle:** Liga/Desliga entre `Enter` e `Shift+Enter`

### **Comportamento do Toggle:**
- **Ligado:** Enter envia, Shift+Enter quebra linha
- **Desligado:** Shift+Enter envia, Enter quebra linha

---

## 📅 **Histórico de Alterações**

**Data:** Janeiro 2025  
**Tipo:** Enhancement - Melhoria de UX  
**Impacto:** Baixo risco - Mudança apenas no comportamento padrão  
**Compatibilidade:** Totalmente retrocompatível  
**Breaking Changes:** Nenhum  

---

## 🔗 **Arquivos Relacionados**

- `useUISettings.js:116` - Lógica principal alterada
- `db/schema.rb` - Campo `ui_settings` com default `{}`
- Configurações do usuário - Interface para alternar comportamento

---

## 🚀 **Benefícios Esperados**

### **📈 Métricas de UX:**
- **Redução** de confusão para novos usuários
- **Aumento** na velocidade de adaptação
- **Diminuição** de dúvidas sobre como enviar mensagens

### **👥 Experiência do Usuário:**
- **Onboarding mais fluido** para novos usuários
- **Consistência** com expectativas modernas de chat
- **Flexibilidade mantida** para usuários avançados

---

**Última atualização:** Janeiro 2025  
**Compatível com:** Todas as versões do Chatwoot  
**Status:** ✅ Implementado e Testado  
**Reversível:** ✅ Sim, com mudança de 1 linha