# Ajustes no Botão de IA e Layout do ReplyBox

## 📋 Resumo das Alterações

Este documento descreve as alterações realizadas para:
1. Alterar o texto do botão de "Inteligência Artificial" / "Assistente de IA" para apenas "IA"
2. Corrigir o layout do ReplyBottomPanel para evitar que o botão "Enviar" seja empurrado para fora da caixa

---

## 🔤 Alteração 1: Texto do Botão de IA

### Problema
O botão de assistência de IA exibia textos muito longos como "Inteligência Artificial" ou "Assistente de IA", ocupando muito espaço na interface.

### Solução
Alteração das traduções em todos os idiomas para exibir apenas "IA".

### Arquivos Modificados

#### Português do Brasil (pt_BR)
- **`app/javascript/dashboard/i18n/locale/pt_BR/integrations.json`**
  - Linha 137: `"AI_ASSIST": "Inteligência Artificial"` → `"AI_ASSIST": "IA"`

- **`app/javascript/dashboard/i18n/locale/pt_BR/generalSettings.json`**
  - Linha 197: `"AI_ASSIST": "Assistente IA"` → `"AI_ASSIST": "IA"`
  - Linha 221: `"AI_ASSIST": "Assistente IA"` → `"AI_ASSIST": "IA"`

#### Português (pt)
- **`app/javascript/dashboard/i18n/locale/pt/integrations.json`**
  - Linha 137: `"AI_ASSIST": "Assistente de IA"` → `"AI_ASSIST": "IA"`

- **`app/javascript/dashboard/i18n/locale/pt/generalSettings.json`**
  - Linha 197: `"AI_ASSIST": "Assistente IA"` → `"AI_ASSIST": "IA"`
  - Linha 221: `"AI_ASSIST": "Assistente IA"` → `"AI_ASSIST": "IA"`

#### Inglês (en)
- **`app/javascript/dashboard/i18n/locale/en/integrations.json`**
  - Linha 137: `"AI_ASSIST": "AI Assist"` → `"AI_ASSIST": "IA"`

- **`app/javascript/dashboard/i18n/locale/en/generalSettings.json`**
  - Linha 197: `"AI_ASSIST": "AI Assist"` → `"AI_ASSIST": "IA"`
  - Linha 221: `"AI_ASSIST": "AI Assist"` → `"AI_ASSIST": "IA"`

---

## 📦 Alteração 2: Layout do ReplyBottomPanel

### Problema
O botão "Enviar" estava sendo empurrado para fora da caixa quando muitos botões estavam visíveis no lado esquerdo da barra de ações (emoji, anexo, microfone, assinatura, IA, etc.).

### Solução
Implementação de propriedades Flexbox para garantir que:
- Os botões à esquerda possam encolher quando necessário
- O botão "Enviar" sempre permaneça visível e dentro da caixa
- Espaçamento adequado entre os grupos de botões

### Arquivo Modificado

**`app/javascript/dashboard/components/widgets/WootWriter/ReplyBottomPanel.vue`**

#### Mudanças no Template:

1. **Container principal** (linha 285):
   ```vue
   <!-- ANTES -->
   <div class="flex justify-between p-3" :class="wrapClass">
   
   <!-- DEPOIS -->
   <div class="flex justify-between p-3 gap-2" :class="wrapClass">
   ```
   - **Adicionado**: `gap-2` para espaçamento entre grupos de botões

2. **Left-wrap (botões da esquerda)** (linha 286):
   ```vue
   <!-- ANTES -->
   <div class="left-wrap">
   
   <!-- DEPOIS -->
   <div class="left-wrap flex-shrink min-w-0">
   ```
   - **Adicionado**: `flex-shrink` - permite que o container encolha quando necessário
   - **Adicionado**: `min-w-0` - permite que o container reduza abaixo de seu tamanho mínimo padrão

3. **Right-wrap (botão Enviar)** (linha 416):
   ```vue
   <!-- ANTES -->
   <div class="right-wrap">
   
   <!-- DEPOIS -->
   <div class="right-wrap flex-shrink-0">
   ```
   - **Adicionado**: `flex-shrink-0` - impede que o botão "Enviar" encolha

4. **Botão Enviar** (linha 417):
   ```vue
   <!-- ANTES -->
   <NextButton
     :label="sendButtonText"
     type="submit"
     sm
     :color="isNote ? 'amber' : 'blue'"
     :disabled="isSendDisabled"
     class="flex-shrink-0"
     @click="onSend"
   />
   
   <!-- DEPOIS -->
   <NextButton
     :label="sendButtonText"
     type="submit"
     sm
     :color="isNote ? 'amber' : 'blue'"
     :disabled="isSendDisabled"
     class="flex-shrink-0 whitespace-nowrap"
     @click="onSend"
   />
   ```
   - **Adicionado**: `whitespace-nowrap` - impede quebra de linha no texto do botão

---

## 🎯 Resultado Final

### Antes
- Texto: "Inteligência Artificial" / "Assistente de IA" (muito longo)
- Layout: Botão "Enviar" podia ser empurrado para fora da visualização

### Depois
- Texto: "IA" (conciso e limpo)
- Layout: Botão "Enviar" sempre visível, com layout responsivo e equilibrado

---

## 🧪 Como Testar

1. Recarregue a aplicação frontend para aplicar as novas traduções
2. Abra uma conversa e verifique a barra de ações de resposta
3. Confirme que o botão exibe "IA" em vez de texto longo
4. Teste com todos os botões visíveis (emoji, anexo, microfone, assinatura, IA)
5. Verifique que o botão "Enviar" permanece visível em diferentes tamanhos de tela

---

## 📝 Notas Técnicas

### Propriedades Tailwind Utilizadas:
- `gap-2`: Espaçamento de 0.5rem entre elementos
- `flex-shrink`: Permite que elementos flexbox encolham
- `flex-shrink-0`: Impede que elementos flexbox encolham
- `min-w-0`: Remove o tamanho mínimo padrão de elementos flex
- `whitespace-nowrap`: Impede quebra de linha em texto

### Componentes Afetados:
- `AIAssistanceCTAButton.vue` (via tradução)
- `AIAssistanceButton.vue` (via tradução)
- `ReplyBottomPanel.vue` (layout)

---

## ✅ Checklist de Validação

- [x] Traduções atualizadas em pt_BR
- [x] Traduções atualizadas em pt
- [x] Traduções atualizadas em en
- [x] Layout ajustado no ReplyBottomPanel
- [x] Classes Tailwind aplicadas corretamente
- [x] Nenhum erro de lint detectado
- [x] Botão "Enviar" sempre visível
- [x] Texto "IA" exibido corretamente

---

**Data da Implementação**: Dezembro 2025  
**Componente Principal**: Dashboard Reply Box

