# 📝 Como Renomear "Macros" no Chatwoot

Este documento ensina como alterar o nome da funcionalidade "Macros" para qualquer outro nome desejado no Chatwoot.

## 🎯 Contexto

A funcionalidade "Macros" do Chatwoot permite criar ações automatizadas para agilizar o atendimento. No entanto, o termo "Macro" pode ser muito técnico para algumas equipes. Este guia permite renomear para termos mais intuitivos como:

- **Atalhos** (recomendado para times comerciais)
- **Automações** 
- **Rotinas**
- **Fluxos**
- **Comandos**
- Ou qualquer outro nome de sua preferência

## 📂 Arquivos que Precisam ser Alterados

### Português Brasileiro (pt_BR)
1. `app/javascript/dashboard/i18n/locale/pt_BR/settings.json`
2. `app/javascript/dashboard/i18n/locale/pt_BR/conversation.json`
3. `app/javascript/dashboard/i18n/locale/pt_BR/macros.json`

### Inglês (en) - Opcional
4. `app/javascript/dashboard/i18n/locale/en/settings.json`
5. `app/javascript/dashboard/i18n/locale/en/conversation.json`
6. `app/javascript/dashboard/i18n/locale/en/macros.json`

---

## 📋 INSTRUÇÕES PASSO A PASSO

### **1. SIDEBAR PRINCIPAL (Menu Configurações)**

**📁 Arquivo:** `app/javascript/dashboard/i18n/locale/pt_BR/settings.json`

**📍 Localizar linha ~308:**
```json
// ALTERE DE:
"MACROS": "Macros",

// PARA (exemplo com "Atalhos"):
"MACROS": "Atalhos",
```

---

### **2. SIDEBAR DA CONVERSA (Painel direito)**

**📁 Arquivo:** `app/javascript/dashboard/i18n/locale/pt_BR/conversation.json`

**📍 Localizar linha ~314:**
```json
// ALTERE DE:
"MACROS": "Macros",

// PARA (exemplo com "Atalhos"):
"MACROS": "Atalhos",
```

---

### **3. PÁGINA PRINCIPAL DE MACROS**

**📁 Arquivo:** `app/javascript/dashboard/i18n/locale/pt_BR/macros.json`

**📍 Principais alterações:**

#### Linha ~3 - Título Principal:
```json
// DE:
"HEADER": "Macros",
// PARA:
"HEADER": "Atalhos",
```

#### Linha ~4 - Descrição Principal:
```json
// DE:
"DESCRIPTION": "Uma macro é um conjunto de ações salvas que ajudam os agentes de atendimento ao cliente a concluir tarefas com facilidade. Os agentes podem definir um conjunto de ações, como etiquetar uma conversa com um rótulo, enviar uma transcrição de e-mail, atualizar um atributo personalizado, etc., e podem executar essas ações com um único clique.",

// PARA:
"DESCRIPTION": "Um atalho é um conjunto de ações salvas que ajudam os agentes de atendimento ao cliente a concluir tarefas com facilidade. Os agentes podem definir um conjunto de ações, como etiquetar uma conversa com um rótulo, enviar uma transcrição de e-mail, atualizar um atributo personalizado, etc., e podem executar essas ações com um único clique.",
```

#### Linha ~5 - Link de Ajuda:
```json
// DE:
"LEARN_MORE": "Aprenda mais sobre macros",
// PARA:
"LEARN_MORE": "Aprenda mais sobre atalhos",
```

#### Linha ~6 - Botão de Adicionar:
```json
// DE:
"HEADER_BTN_TXT": "Adicionar uma nova macro",
// PARA:
"HEADER_BTN_TXT": "Adicionar um novo atalho",
```

#### Linha ~7 - Botão de Salvar:
```json
// DE:
"HEADER_BTN_TXT_SAVE": "Salvar macro",
// PARA:
"HEADER_BTN_TXT_SAVE": "Salvar atalho",
```

#### Linha ~8 - Loading:
```json
// DE:
"LOADING": "Obtendo macros",
// PARA:
"LOADING": "Obtendo atalhos",
```

#### Linha ~10 - Informações de Ordem:
```json
// DE:
"ORDER_INFO": "As macros serão executadas na ordem que você adicionar suas ações. Você pode reorganizá-las arrastando-as pelo identificador ao lado de cada nó.",
// PARA:
"ORDER_INFO": "Os atalhos serão executados na ordem que você adicionar suas ações. Você pode reorganizá-las arrastando-as pelo identificador ao lado de cada nó.",
```

### **4. FORMULÁRIOS E VALIDAÇÕES**

#### Seção ADD → FORM → NAME (linhas ~14-16):
```json
// DE:
"NAME": {
  "LABEL": "Nome da macro",
  "PLACEHOLDER": "Digite um nome para sua macro",
  "ERROR": "Nome é necessário para criar uma macro"
}

// PARA:
"NAME": {
  "LABEL": "Nome do atalho",
  "PLACEHOLDER": "Digite um nome para seu atalho",
  "ERROR": "Nome é necessário para criar um atalho"
}
```

#### Seção ADD → API (linhas ~23-24):
```json
// DE:
"SUCCESS_MESSAGE": "Macro adicionada com sucesso",
"ERROR_MESSAGE": "Não é possível criar a macro, por favor, tente novamente mais tarde"

// PARA:
"SUCCESS_MESSAGE": "Atalho adicionado com sucesso",
"ERROR_MESSAGE": "Não é possível criar o atalho, por favor, tente novamente mais tarde"
```

#### Seção LIST (linha ~34):
```json
// DE:
"404": "Nenhuma macro encontrada"
// PARA:
"404": "Nenhum atalho encontrado"
```

### **5. AÇÕES DE EDIÇÃO/EXCLUSÃO**

#### Seção DELETE (linhas ~37, ~44-45):
```json
// DE:
"TOOLTIP": "Excluir macro",
// PARA:
"TOOLTIP": "Excluir atalho",

// DE:
"SUCCESS_MESSAGE": "Macro excluída com sucesso",
"ERROR_MESSAGE": "Ocorreu um erro ao excluir a macro. Por favor, tente novamente mais tarde"

// PARA:
"SUCCESS_MESSAGE": "Atalho excluído com sucesso",
"ERROR_MESSAGE": "Ocorreu um erro ao excluir o atalho. Por favor, tente novamente mais tarde"
```

#### Seção EDIT (linhas ~49, ~51-52):
```json
// DE:
"TOOLTIP": "Editar macro",
// PARA:
"TOOLTIP": "Editar atalho",

// DE:
"SUCCESS_MESSAGE": "Macro atualizada com sucesso",
"ERROR_MESSAGE": "Não foi possível atualizar Macro, Por favor, tente novamente mais tarde"

// PARA:
"SUCCESS_MESSAGE": "Atalho atualizado com sucesso",
"ERROR_MESSAGE": "Não foi possível atualizar Atalho, Por favor, tente novamente mais tarde"
```

### **6. EDITOR E VISIBILIDADE**

#### Seção EDITOR (linhas ~58, ~62, ~65, ~69):
```json
// DE:
"LOADING": "Obtendo macro",
// PARA:
"LOADING": "Obtendo atalho",

// DE:
"LABEL": "Visibilidade da Macro",
// PARA:
"LABEL": "Visibilidade do Atalho",

// DE:
"DESCRIPTION": "Esta macro está disponível publicamente para todos os agentes desta conta."
// PARA:
"DESCRIPTION": "Este atalho está disponível publicamente para todos os agentes desta conta."

// DE:
"DESCRIPTION": "Esta macro será privada para você e não estará disponível para outras pessoas."
// PARA:
"DESCRIPTION": "Este atalho será privado para você e não estará disponível para outras pessoas."
```

#### Seção EXECUTE (linhas ~75-76):
```json
// DE:
"PREVIEW": "Pré-visualizar Macro",
"EXECUTED_SUCCESSFULLY": "Macro executada com sucesso"

// PARA:
"PREVIEW": "Pré-visualizar Atalho",
"EXECUTED_SUCCESSFULLY": "Atalho executado com sucesso"
```

---

## 📝 DICAS IMPORTANTES

### ⚠️ **Atenção ao Gênero das Palavras**

Ao escolher o novo nome, observe o gênero (masculino/feminino) para manter a concordância correta:

**Masculino (como "Atalho"):**
- "um atalho"
- "o atalho" 
- "novo atalho"
- "executado"

**Feminino (como "Automação"):**
- "uma automação"
- "a automação"
- "nova automação" 
- "executada"

### 🔍 **Como Encontrar as Linhas Rapidamente**

1. Abra o arquivo no seu editor
2. Use **Ctrl+F** (Windows/Linux) ou **Cmd+F** (Mac)
3. Pesquise por palavras-chave como `"HEADER"`, `"MACROS"`, `"macro"`
4. Faça as substituições uma por vez

### ✅ **Lista de Verificação**

- [ ] settings.json (pt_BR) - linha ~308
- [ ] conversation.json (pt_BR) - linha ~314  
- [ ] macros.json (pt_BR) - ~15 alterações
- [ ] settings.json (en) - linha ~308 *(opcional)*
- [ ] conversation.json (en) - linha ~314 *(opcional)*
- [ ] macros.json (en) - ~15 alterações *(opcional)*

### 🔄 **Aplicar Alterações**

Após fazer as alterações:
1. Salve todos os arquivos
2. Reinicie o servidor de desenvolvimento
3. Limpe o cache do navegador (Ctrl+F5)
4. Teste a interface para verificar se as alterações aparecem

---

## 🚀 **Sugestões de Nomes Alternativos**

| Nome | Adequado para | Vantagens |
|------|---------------|-----------|
| **Atalhos** | Times comerciais | Simples, todo mundo entende |
| **Automações** | Times técnicos | Deixa claro o propósito |
| **Rotinas** | Atendimento geral | Linguagem do dia a dia |
| **Fluxos** | Times de marketing/vendas | Familiar para CRM |
| **Comandos** | Usuários avançados | Direto e objetivo |
| **Tarefas** | Times operacionais | Simples, mas pode confundir |

---

**💡 Dica Final:** Escolha um nome que sua equipe já usa no dia a dia. A mudança será mais natural!

---

## ✅ ALTERAÇÕES CONFIRMADAS

### **STATUS DE IMPLEMENTAÇÃO:**

**📁 app/javascript/dashboard/i18n/locale/pt_BR/settings.json**
- ✅ **CONCLUÍDO** - Linha 308: `"MACROS": "Atalhos"` ✨
- ✅ **TESTADO** - Menu lateral "Configurações" → "Atalhos"

**📁 Próximas alterações recomendadas:**
- 📋 `conversation.json` - Sidebar da conversa
- 📋 `macros.json` - Página completa de macros

---

## 📞 Suporte

Este documento foi criado para facilitar a customização do Chatwoot. Para dúvidas técnicas específicas, consulte a documentação oficial do Chatwoot.

**Data de criação:** Dezembro 2024  
**Versão:** 1.1 - Atualizada com confirmações de implementação
