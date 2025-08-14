# 🔒 Como Esconder Redes Sociais no Chatwoot

Este documento ensina como esconder campos de redes sociais na interface do Chatwoot **sem perder os dados** já salvos no sistema.

## 🎯 Contexto

O Chatwoot permite cadastrar perfis de redes sociais dos contatos (LinkedIn, GitHub, Twitter, Facebook, Instagram, Telegram). Porém, para algumas equipes, esses campos podem:

- **Poluir a interface** com informações desnecessárias
- **Confundir usuários** não técnicos
- **Distrair** do foco principal do atendimento

Este guia permite esconder redes sociais específicas ou todas, **mantendo a funcionalidade intacta**.

## 🗺️ Onde Aparecem as Redes Sociais

### **1. 👁️ VISUALIZAÇÃO (Ícones clicáveis)**
- **Local**: Página de detalhes do contato
- **Formato**: Ícones pequenos que abrem os perfis
- **Arquivo**: `app/javascript/dashboard/routes/dashboard/conversation/contact/SocialIcons.vue`

### **2. ✏️ EDIÇÃO (Campos de formulário)**
- **Local**: Formulário de edição do contato
- **Formato**: Campos para inserir usernames/links
- **Arquivo**: `app/javascript/dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue`

---

## 📋 INSTRUÇÕES PASSO A PASSO

### **CENÁRIO A: Esconder Redes Específicas (Recomendado)**

*Exemplo: Esconder só GitHub, Twitter e LinkedIn*

#### **1️⃣ Esconder Ícones de Visualização**

**📁 Arquivo:** `app/javascript/dashboard/routes/dashboard/conversation/contact/SocialIcons.vue`

**📍 Localizar linhas ~11-18:**
```javascript
// LOCALIZAR:
socialMediaLinks: [
  { key: 'facebook', icon: 'facebook', link: 'https://facebook.com/' },
  { key: 'twitter', icon: 'twitter', link: 'https://twitter.com/' },
  { key: 'linkedin', icon: 'linkedin', link: 'https://linkedin.com/' },
  { key: 'github', icon: 'github', link: 'https://github.com/' },
  { key: 'instagram', icon: 'instagram', link: 'https://instagram.com/' },
  { key: 'telegram', icon: 'telegram', link: 'https://t.me/' },
],

// COMENTAR AS LINHAS DESEJADAS:
socialMediaLinks: [
  { key: 'facebook', icon: 'facebook', link: 'https://facebook.com/' },
  // { key: 'twitter', icon: 'twitter', link: 'https://twitter.com/' },        // ← ESCONDIDO
  // { key: 'linkedin', icon: 'linkedin', link: 'https://linkedin.com/' },     // ← ESCONDIDO
  // { key: 'github', icon: 'github', link: 'https://github.com/' },           // ← ESCONDIDO
  { key: 'instagram', icon: 'instagram', link: 'https://instagram.com/' },
  { key: 'telegram', icon: 'telegram', link: 'https://t.me/' },
],
```

#### **2️⃣ Esconder Campos de Edição**

**📁 Arquivo:** `app/javascript/dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue`

**📍 Localizar linhas ~43-49:**
```javascript
// LOCALIZAR:
const SOCIAL_CONFIG = {
  LINKEDIN: 'i-ri-linkedin-box-fill',
  FACEBOOK: 'i-ri-facebook-circle-fill',
  INSTAGRAM: 'i-ri-instagram-line',
  TWITTER: 'i-ri-twitter-x-fill',
  GITHUB: 'i-ri-github-fill',
};

// COMENTAR AS LINHAS DESEJADAS:
const SOCIAL_CONFIG = {
  // LINKEDIN: 'i-ri-linkedin-box-fill',      // ← ESCONDIDO
  FACEBOOK: 'i-ri-facebook-circle-fill',
  INSTAGRAM: 'i-ri-instagram-line',
  // TWITTER: 'i-ri-twitter-x-fill',          // ← ESCONDIDO
  // GITHUB: 'i-ri-github-fill',              // ← ESCONDIDO
};
```

---

### **CENÁRIO B: Esconder TODAS as Redes Sociais**

#### **1️⃣ Esconder Visualização Completa**

**📁 Arquivo:** `SocialIcons.vue`

**📍 Linha ~32 - Adicionar `style="display: none;"`:**
```vue
<!-- ALTERAR DE: -->
<template>
  <div v-if="availableProfiles.length" class="flex items-end gap-3 mx-0 my-2">

<!-- PARA: -->
<template>
  <div v-if="availableProfiles.length" class="flex items-end gap-3 mx-0 my-2" style="display: none;">
```

#### **2️⃣ Esconder Formulário Completo**

**📁 Arquivo:** `ContactsForm.vue`

**📍 Linha ~288 - Adicionar `style="display: none;"`:**
```vue
<!-- ALTERAR DE: -->
<div class="flex flex-col items-start gap-2">
  <span class="py-1 text-sm font-medium text-n-slate-12">
    {{ t('CONTACTS_LAYOUT.CARD.SOCIAL_MEDIA.TITLE') }}
  </span>

<!-- PARA: -->
<div class="flex flex-col items-start gap-2" style="display: none;">
  <span class="py-1 text-sm font-medium text-n-slate-12">
    {{ t('CONTACTS_LAYOUT.CARD.SOCIAL_MEDIA.TITLE') }}
  </span>
```

---

## 🔧 GUIA DE REDES SOCIAIS DISPONÍVEIS

### **📍 Redes Suportadas:**

| Rede Social | Key | Ícone | Link Base |
|-------------|-----|-------|-----------|
| **Facebook** | `facebook` | `brand-facebook` | `https://facebook.com/` |
| **Twitter** | `twitter` | `brand-twitter` | `https://twitter.com/` |
| **LinkedIn** | `linkedin` | `brand-linkedin` | `https://linkedin.com/` |
| **GitHub** | `github` | `brand-github` | `https://github.com/` |
| **Instagram** | `instagram` | `brand-instagram` | `https://instagram.com/` |
| **Telegram** | `telegram` | `brand-telegram` | `https://t.me/` |

### **🎯 Combinações Comuns:**

#### **Para Times Comerciais:**
```javascript
// MANTER APENAS:
{ key: 'facebook', ... },      // ✅ Facebook
{ key: 'instagram', ... },     // ✅ Instagram
// { key: 'linkedin', ... },   // ❌ LinkedIn (muito "corporativo")
// { key: 'twitter', ... },    // ❌ Twitter (muito "técnico")
// { key: 'github', ... },     // ❌ GitHub (só desenvolvedores)
{ key: 'telegram', ... },      // ✅ Telegram (comunicação)
```

#### **Para Times Técnicos:**
```javascript
// MANTER APENAS:
// { key: 'facebook', ... },   // ❌ Facebook (pouco relevante)
{ key: 'twitter', ... },       // ✅ Twitter (comunidade tech)
{ key: 'linkedin', ... },      // ✅ LinkedIn (networking)
{ key: 'github', ... },        // ✅ GitHub (perfil técnico)
// { key: 'instagram', ... },  // ❌ Instagram (não profissional)
{ key: 'telegram', ... },      // ✅ Telegram (comunicação)
```

#### **Para Suporte Geral:**
```javascript
// MANTER APENAS:
{ key: 'facebook', ... },      // ✅ Facebook (amplo alcance)
{ key: 'instagram', ... },     // ✅ Instagram (visual)
// { key: 'linkedin', ... },   // ❌ LinkedIn (muito específico)
// { key: 'twitter', ... },    // ❌ Twitter (pode ser controverso)
// { key: 'github', ... },     // ❌ GitHub (não relevante)
{ key: 'telegram', ... },      // ✅ Telegram (atendimento)
```

---

## 🔍 LOCALIZAÇÃO RÁPIDA

### **Como Encontrar as Linhas:**
1. **Ctrl+F** (Windows/Linux) ou **Cmd+F** (Mac)
2. Pesquisar por:
   - `socialMediaLinks` → para ícones
   - `SOCIAL_CONFIG` → para campos de formulário
   - `LINKEDIN`, `GITHUB`, `TWITTER` → para redes específicas

### **Estrutura dos Arquivos:**
```
SocialIcons.vue:
├── <script> (linhas 1-28)
│   └── socialMediaLinks[] (linhas 11-18)  ← EDITAR AQUI
└── <template> (linhas 32-48)

ContactsForm.vue:
├── <script> (linhas 1-200+)
│   └── SOCIAL_CONFIG{} (linhas 43-49)     ← EDITAR AQUI
└── <template> (linhas 250+)
```

---

## ⚠️ CUIDADOS IMPORTANTES

### **✅ O que É Seguro:**
- ✅ **Comentar linhas** com `//` (JavaScript) ou `<!---->` (HTML)
- ✅ **Adicionar** `style="display: none;"`
- ✅ **Remover completamente** linhas específicas
- ✅ **Testar** em ambiente de desenvolvimento primeiro

### **❌ O que NÃO Fazer:**
- ❌ **NÃO alterar** a estrutura dos objetos/arrays
- ❌ **NÃO remover** vírgulas importantes  
- ❌ **NÃO editar** linhas de backend/API
- ❌ **NÃO esquecer** de fechar blocos de código

### **🔄 Como Reverter:**
```javascript
// Para reverter, só descomentar:
// { key: 'github', icon: 'github', link: 'https://github.com/' },

// Vira:
{ key: 'github', icon: 'github', link: 'https://github.com/' },
```

---

## 🧪 TESTANDO AS ALTERAÇÕES

### **Passos para Testar:**
1. ✅ Salvar todos os arquivos editados
2. ✅ Reiniciar servidor de desenvolvimento
3. ✅ Limpar cache do navegador (Ctrl+F5)
4. ✅ Ir para página de contato
5. ✅ Verificar se redes escondidas sumiram
6. ✅ Verificar se redes visíveis ainda aparecem
7. ✅ Testar formulário de edição

### **Checklist de Validação:**
- [ ] Ícones escondidos não aparecem na visualização
- [ ] Campos escondidos não aparecem no formulário  
- [ ] Redes visíveis continuam funcionando
- [ ] Links das redes visíveis abrem corretamente
- [ ] Dados existentes não foram perdidos
- [ ] Formulário salva sem erros

---

## 🎯 EXEMPLOS PRÁTICOS

### **Exemplo 1: E-commerce (só visuais)**
```javascript
// SocialIcons.vue e ContactsForm.vue:
// MANTER APENAS:
{ key: 'facebook', ... },     // Facebook
{ key: 'instagram', ... },    // Instagram
```

### **Exemplo 2: B2B/Corporativo (networking)**
```javascript
// MANTER APENAS:
{ key: 'linkedin', ... },     // LinkedIn
```

### **Exemplo 3: Suporte Técnico (comunidade)**
```javascript
// MANTER APENAS:
{ key: 'github', ... },       // GitHub
{ key: 'twitter', ... },      // Twitter
{ key: 'telegram', ... },     // Telegram
```

---

## 📊 IMPACTO DAS ALTERAÇÕES

| Alteração | Interface | Dados | API | Performance |
|-----------|-----------|-------|-----|-------------|
| **Comentar linhas** | ✅ Esconde | ✅ Preserva | ✅ Mantém | ✅ Igual |
| **display: none** | ✅ Esconde | ✅ Preserva | ✅ Mantém | ✅ Igual |
| **Remover linhas** | ✅ Esconde | ✅ Preserva | ✅ Mantém | ⚡ Melhora* |

*\*Performance melhora marginalmente por renderizar menos elementos*

---

## 🚀 CASOS DE USO REAIS

### **"Minha equipe comercial se confunde com GitHub"**
```javascript
// SOLUÇÃO: Comentar só GitHub
// { key: 'github', icon: 'github', link: 'https://github.com/' },
```

### **"Queremos só Facebook e Instagram"**  
```javascript
// SOLUÇÃO: Manter só essas duas:
{ key: 'facebook', icon: 'facebook', link: 'https://facebook.com/' },
{ key: 'instagram', icon: 'instagram', link: 'https://instagram.com/' },
```

### **"Redes sociais poluem demais a tela"**
```html
<!-- SOLUÇÃO: Esconder seção completa -->
<div style="display: none;">
```

---

## 📞 Suporte e Manutenção

### **🔄 Atualizações do Chatwoot:**
- As alterações podem ser **sobrescritas** em updates
- **Sempre faça backup** dos arquivos editados
- **Reaplique** as mudanças após atualizações

### **🐛 Solução de Problemas:**
```javascript
// Se algo quebrar, sempre pode reverter:
// Arquivo original: SocialIcons.vue
// Backup: SocialIcons.vue.backup

// Ou simplesmente descomentar as linhas:
{ key: 'github', icon: 'github', link: 'https://github.com/' }, // ← Descomentado
```

### **💡 Dica Pro:**
Salve os arquivos originais como `.backup` antes de editar:
```bash
cp SocialIcons.vue SocialIcons.vue.backup
cp ContactsForm.vue ContactsForm.vue.backup
```

---

**💡 Lembre-se:** As alterações são **estéticas**, os dados ficam intactos no banco de dados. Você pode sempre reverter ou ajustar conforme necessário!

---

## 📅 Histórico do Documento

**Data de criação:** Dezembro 2024  
**Versão:** 1.0  
**Testado em:** Chatwoot v3.x  
**Compatibilidade:** Vue.js 3.x
