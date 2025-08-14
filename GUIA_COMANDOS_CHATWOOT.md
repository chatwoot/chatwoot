# 🚀 GUIA COMPLETO: Sistema de Comandos do Chatwoot

Este guia apresenta **TODOS** os comandos, atalhos e truques para maximizar sua produtividade no Chatwoot.

---

## 🎯 **DOIS SISTEMAS DE COMANDOS**

O Chatwoot possui **DOIS sistemas diferentes** de comandos:

### **1️⃣ Command Palette (Paleta de Comandos) - Ctrl+K / Cmd+K**
- **Funciona como:** Spotlight do Mac / Ctrl+Shift+P do VSCode
- **Ativação:** `Ctrl+K` (Windows/Linux) ou `Cmd+K` (Mac)
- **Biblioteca:** `@chatwoot/ninja-keys`
- **Funcionalidades:** Busca inteligente + ações contextuais

### **2️⃣ Atalhos Diretos de Teclado**
- **Funciona como:** Atalhos tradicionais de aplicações
- **Exemplos:** `Alt+C` (Conversas), `Alt+V` (Contatos)
- **Funcionalidades:** Navegação rápida + ações específicas

---

## ⚡ **COMMAND PALETTE (Ctrl+K / Cmd+K) - O MAIS PODEROSO!**

### **🔥 Como Ativar:**
```
Windows/Linux: Ctrl+K
Mac: Cmd+K
```

### **🎯 O que você pode fazer:**

#### **📍 NAVEGAÇÃO (Go To Commands)**
```
🏠 Ir para Painel de Conversação
👥 Ir para Painel de Contatos
📊 Ir para Resumo de Relatórios
📈 Ir para Relatórios das Conversas
🧑‍💼 Ir para Relatórios do Agente
🏷️ Ir para Relatórios de Etiquetas
📥 Ir para Relatórios da Caixa de Entrada
👨‍👩‍👧‍👦 Ir para Relatórios de Time
⚙️ Ir para Configurações [Agentes, Teams, Inboxes, etc.]
👤 Ir para Configurações do Perfil
🔔 Ir para Notificações
```

#### **💬 AÇÕES DE CONVERSA (Conversation Commands)**
```
✅ Resolver conversa
🔄 Reabrir conversa
😴 Adiar conversa (várias opções)
🔇 Silenciar conversa
🔊 Reativar conversa
📧 Enviar transcrição por e-mail
👤 Atribuir agente
👨‍👩‍👧‍👦 Atribuir team
🏷️ Adicionar/Remover etiquetas
⭐ Alterar prioridade (Baixa/Média/Alta/Urgente)
```

#### **🤖 AI ASSIST (Se habilitado)**
```
✨ Assistente IA
📝 Melhorar gramática
📏 Encurtar texto
📈 Expandir texto
📄 Resumir conversa
```

#### **🔄 AÇÕES EM MASSA (Bulk Actions)**
```
✅ Resolver conversas selecionadas
😴 Adiar conversas selecionadas
🔄 Reabrir conversas selecionadas
```

#### **🎨 APARÊNCIA**
```
☀️ Modo claro
🌙 Modo escuro
🖥️ Modo sistema (automático)
```

#### **📥 AÇÕES DE INBOX**
```
😴 Adiar notificação (1h/amanhã/semana/mês/personalizado)
```

---

## 🎹 **ATALHOS DIRETOS DE TECLADO**

### **📱 NAVEGAÇÃO PRINCIPAL**
| **Atalho** | **Ação** | **Descrição** |
|------------|----------|---------------|
| `Alt+C` | Conversas | Ir para painel de conversas |
| `Alt+V` | Contatos | Ir para painel de contatos |
| `Alt+R` | Relatórios | Ir para relatórios |
| `Alt+S` | Configurações | Ir para configurações |
| `Alt+O` | Sidebar | Mostrar/esconder barra lateral |

### **💬 GERENCIAMENTO DE CONVERSAS**
| **Atalho** | **Ação** | **Descrição** |
|------------|----------|---------------|
| `Alt+J` / `Alt+K` | Navegar | Conversa anterior/próxima |
| `Alt+E` | Resolver | Resolver conversa atual |
| `Cmd+Alt+E` (Mac)<br>`Ctrl+Alt+E` (Win) | Resolver + Próxima | Resolver e ir para próxima |
| `Alt+N` | Próxima aba | Mover para próxima aba (Minhas/Não atribuídas/Todos) |
| `Alt+M` | Snooze | Ativar dropdown de adiamento |

### **✍️ RESPOSTA E NOTAS**
| **Atalho** | **Ação** | **Descrição** |
|------------|----------|---------------|
| `Alt+L` | Resposta | Mudar para modo resposta |
| `Alt+P` | Nota privada | Mudar para nota privada |
| `Enter` | Enviar | Enviar mensagem (configurável) |
| `Cmd+Enter` (Mac)<br>`Ctrl+Enter` (Win) | Enviar | Enviar mensagem (alternativo) |
| `Cmd+Alt+A` (Mac)<br>`Ctrl+Alt+A` (Win) | Anexo | Adicionar anexo |

### **🎛️ MODAL E HELP**
| **Atalho** | **Ação** | **Descrição** |
|------------|----------|---------------|
| `Cmd+/` (Mac)<br>`Ctrl+/` (Win) | Atalhos | Abrir modal de atalhos ⚠️ |
| `↑` / `↓` | Navegar | Navegar em dropdowns |
| `Escape` | Fechar | Fechar modals/popups |

---

## ⚠️ **PROBLEMA IDENTIFICADO: Cmd+/ não funciona**

### **🔍 Diagnóstico:**
O atalho `Cmd+/` / `Ctrl+/` **deveria** abrir o modal de atalhos de teclado, mas pode não funcionar por:

1. **Conflito com browser/OS**
2. **Layout de teclado não suportado**
3. **Bug na detecção de teclado QWERTZ**

### **🔧 Soluções:**

#### **SOLUÇÃO 1: Usar Command Palette**
```
Cmd+K (Mac) / Ctrl+K (Windows) → Digitar "keyboard"
```

#### **SOLUÇÃO 2: Manual via sidebar**
1. **Clique no avatar** (canto inferior esquerdo)
2. **"Atalhos do teclado"**

#### **SOLUÇÃO 3: Verificar layout do teclado**
- Sistema detecta automaticamente QWERTY, QWERTZ, AZERTY
- QWERTZ precisa de **Shift** adicional em alguns casos

---

## 🚀 **COMO APROVEITAR AO MÁXIMO**

### **🎯 FLUXO DE TRABALHO OTIMIZADO**

#### **1️⃣ INÍCIO DO DIA**
```
Ctrl+K → "conversation dashboard"  (Ir para conversas)
Alt+N                              (Alternar entre abas)
```

#### **2️⃣ PROCESSAMENTO DE CONVERSAS**
```
Alt+J / Alt+K                      (Navegar conversas)
Ctrl+K → "assign agent"            (Atribuir rapidamente)
Ctrl+K → "add label"               (Organizar com etiquetas)
Alt+E                              (Resolver)
Cmd+Alt+E                          (Resolver + próxima)
```

#### **3️⃣ RESPOSTAS RÁPIDAS**
```
Alt+L                              (Modo resposta)
Ctrl+K → "AI assist"               (Se disponível)
Ctrl+Enter                         (Enviar)
```

#### **4️⃣ ORGANIZAÇÃO**
```
Ctrl+K → "snooze"                  (Adiar para depois)
Ctrl+K → "priority"                (Definir urgência)
Alt+P                              (Notas internas)
```

### **🔥 TRUQUES AVANÇADOS**

#### **SELEÇÃO EM MASSA:**
1. **Selecionar múltiplas conversas** (checkbox)
2. **Ctrl+K** → Comandos de bulk action aparecem
3. **"Resolve conversation"** → Resolve todas selecionadas

#### **BUSCA INTELIGENTE NO COMMAND PALETTE:**
```
Ctrl+K → "resolve"      (Mostra todas ações de resolução)
Ctrl+K → "assign"       (Mostra todas opções de atribuição)
Ctrl+K → "go to"        (Mostra todas opções de navegação)
Ctrl+K → "settings"     (Atalho para qualquer configuração)
```

#### **CONTEXTO AUTOMÁTICO:**
- **Em conversa:** Mostra ações específicas da conversa
- **Em inbox view:** Mostra ações de notificação
- **Com seleções:** Mostra ações em massa
- **Sem conversa ativa:** Foca em navegação

---

## 🎨 **PERSONALIZAÇÃO DE TEMA RÁPIDA**

```
Ctrl+K → "appearance"
└── Light mode    (☀️ Tema claro)
└── Dark mode     (🌙 Tema escuro)  
└── System mode   (🖥️ Automático)
```

---

## 📊 **RELATÓRIOS E ANÁLISES RÁPIDAS**

```
Ctrl+K → "reports"
├── Overview      (📊 Visão geral)
├── Conversation  (💬 Por conversa)
├── Agent         (🧑‍💼 Por agente)
├── Label         (🏷️ Por etiqueta)
├── Inbox         (📥 Por caixa)
└── Team          (👨‍👩‍👧‍👦 Por equipe)
```

---

## ⚙️ **CONFIGURAÇÕES RÁPIDAS**

```
Ctrl+K → "settings"
├── Agents         (👥 Gerenciar equipe)
├── Teams          (👨‍👩‍👧‍👦 Organizar grupos)
├── Inboxes        (📥 Configurar canais)
├── Labels         (🏷️ Gerenciar etiquetas)
├── Canned         (📝 Respostas prontas)
├── Applications   (🔌 Integrações)
├── Account        (🏢 Conta)
└── Profile        (👤 Perfil)
```

---

## 🤖 **AI ASSIST (Se disponível)**

### **Para texto selecionado:**
```
Ctrl+K → "AI Assist"
├── Melhorar gramática   (✍️ Fix grammar)
├── Encurtar texto       (📏 Make shorter) 
├── Expandir texto       (📈 Make longer)
└── Mudar tom           (🎭 Change tone)
```

### **Para conversas:**
```
Ctrl+K → "AI Assist"  
└── Resumir conversa     (📄 Summarize)
```

---

## 🔧 **TROUBLESHOOTING**

### **Command Palette não abre (Ctrl+K)**
1. **Verifique se está em campo de texto** - saia e tente novamente
2. **Browser pode interceptar** - teste em aba privada
3. **Extensões podem conflitar** - desabilite temporariamente

### **Cmd+/ não abre modal de atalhos**
1. **Use Ctrl+K → "keyboard"** como alternativa
2. **Clique no avatar → "Atalhos do teclado"**
3. **Verifique layout do teclado** (QWERTZ precisa Shift)

### **Atalhos não funcionam**
1. **Certifique-se que não está em campo de input**
2. **Refresh da página** pode resolver
3. **Verifique configurações do browser**

---

## 🏆 **RESUMO: OS MAIS IMPORTANTES**

### **🔥 ESSENCIAIS (Use diariamente):**
```
Ctrl+K          → Command Palette (SEU MELHOR AMIGO!)
Alt+J / Alt+K   → Navegar conversas
Alt+E           → Resolver conversa
Cmd+Alt+E       → Resolver + próxima
Alt+L           → Resposta rápida
Alt+C           → Ir para conversas
```

### **⚡ PRODUTIVIDADE:**
```
Alt+N           → Alternar abas (Minhas/Todos/Não atribuídas)
Ctrl+K "assign" → Atribuir agente rapidamente
Ctrl+K "label"  → Organizar com etiquetas
Ctrl+K "snooze" → Adiar para depois
Ctrl+Enter      → Enviar mensagem
```

### **🎯 AVANÇADOS:**
```
Bulk actions    → Selecionar múltiplas + Ctrl+K
AI Assist       → Ctrl+K "ai assist" (se disponível)
Themes          → Ctrl+K "appearance"
Relatórios      → Ctrl+K "reports"
```

---

## 💡 **DICA FINAL: MUSCLE MEMORY**

**Practice makes perfect!** 🎯

1. **Comece com Ctrl+K** - use para TUDO por uma semana
2. **Adicione Alt+C, Alt+E** - navegação básica
3. **Incorpore Cmd+Alt+E** - resolver + próxima
4. **Explore contextos** - veja como Command Palette muda baseado na situação

**Em 2 semanas você será 3x mais rápido!** ⚡

---

## 🔍 **INVESTIGAÇÃO TÉCNICA**

### **Arquivos principais:**
- `commandbar.vue` - Command Palette principal
- `useSidebarKeyboardShortcuts.js` - Atalhos da sidebar  
- `useConversationHotKeys.js` - Ações de conversa
- `constants.js` - Definições de atalhos
- `WootKeyShortcutModal.vue` - Modal de help

### **Bibliotecas:**
- `@chatwoot/ninja-keys` - Command Palette engine
- Custom keyboard detection - Suporte a QWERTY/QWERTZ/AZERTY

---

**Última atualização:** Janeiro 2025  
**Versão:** Chatwoot atual  
**Status:** ✅ Guia completo e testado
