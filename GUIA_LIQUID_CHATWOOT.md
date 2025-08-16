# 📚 Guia Completo: Liquid Templates no Chatwoot

Este é o guia definitivo de **todas as funcionalidades Liquid** que funcionam no Chatwoot. Use como referência para criar templates dinâmicos e inteligentes em mensagens, macros, campanhas e emails.

## 📖 Índice

1. [Conceitos Básicos](#-1-conceitos-básicos)
2. [Condicionais](#-2-condicionais)
3. [Loops e Iterações](#-3-loops-e-iterações)
4. [Filtros](#-4-filtros)
5. [Variáveis e Operações](#-5-variáveis-e-operações)
6. [Objetos Disponíveis](#-6-objetos-disponíveis)
7. [Exemplos Práticos por Categoria](#-7-exemplos-práticos-por-categoria)
8. [Casos de Uso Reais](#-8-casos-de-uso-reais)
9. [Dicas Avançadas](#-9-dicas-avançadas)
10. [Referência Rápida](#-10-referência-rápida)

---

## 🎯 1. Conceitos Básicos

### **Sintaxe Fundamental:**
```liquid
{{variable}}           - Saída de variável
{% tag %}              - Tags de lógica
{% if condition %}     - Abertura de bloco
{% endif %}            - Fechamento de bloco
{{ variable | filter }} - Aplicar filtro
```

### **Onde Funciona:**
- ✅ **Mensagens saindo** (outgoing)
- ✅ **Macros/Atalhos**
- ✅ **Respostas prontas**  
- ✅ **Templates de email**
- ✅ **Campanhas**
- ❌ **Mensagens entrando** (incoming)

---

## 🔀 2. Condicionais

### **2.1 IF/ELSE/ELSIF**

#### **Sintaxe:**
```liquid
{% if condition %}
  Conteúdo se verdadeiro
{% elsif other_condition %}
  Conteúdo para segunda condição
{% else %}
  Conteúdo se falso
{% endif %}
```

#### **Exemplos Práticos:**
```liquid
{% if contact.name %}
  Olá {{contact.name}}! 👋
{% else %}
  Olá! Como posso ajudar? 👋
{% endif %}

{% if contact.email %}
  📧 Email: {{contact.email}}
{% elsif contact.phone_number %}
  📱 Contato: {{contact.phone_number}}
{% else %}
  ❓ Preciso de seus dados de contato
{% endif %}
```

### **2.2 UNLESS (Negação)**

#### **Sintaxe:**
```liquid
{% unless condition %}
  Conteúdo se condição for FALSA
{% endunless %}
```

#### **Exemplo:**
```liquid
{% unless contact.email %}
  ❗ **Importante:** Por favor, informe seu email
{% endunless %}
```

### **2.3 CASE/WHEN (Switch)**

#### **Sintaxe:**
```liquid
{% case variable %}
  {% when "valor1" %}
    Conteúdo para valor1
  {% when "valor2" %}
    Conteúdo para valor2
  {% else %}
    Conteúdo padrão
{% endcase %}
```

#### **Exemplo:**
```liquid
{% case user.first_name %}
  {% when "João" %}
    🚀 João aqui! Expert em Google Ads
  {% when "Maria" %}
    📱 Maria falando! Especialista em Facebook
  {% else %}
    👋 {{user.name}} da {{account.name}}
{% endcase %}
```

---

## 🔄 3. Loops e Iterações

### **3.1 FOR Loop**

#### **Sintaxe:**
```liquid
{% for item in collection %}
  {{item.propriedade}}
{% endfor %}
```

#### **Exemplo (Mensagens Recentes):**
```liquid
📝 **Últimas mensagens:**
{% for message in conversation.recent_messages %}
- {{message.sender}}: {{message.content}}
{% endfor %}
```

### **3.2 FOR com Condições**

```liquid
{% for message in conversation.recent_messages %}
  {% if message.sender != "Bot" %}
    💬 {{message.sender}}: {{message.content}}
  {% endif %}
{% endfor %}
```

### **3.3 FOR com Limitações**

```liquid
{% for message in conversation.recent_messages limit:3 %}
  {{forloop.index}}. {{message.content}}
{% endfor %}
```

### **3.4 Variáveis do ForLoop**

```liquid
{% for message in conversation.recent_messages %}
  {% if forloop.first %}📌 Primeira mensagem:{% endif %}
  {{forloop.index}} - {{message.content}}
  {% if forloop.last %}✅ Última mensagem{% endif %}
{% endfor %}
```

**Variáveis disponíveis:**
- `forloop.index` - Posição atual (1, 2, 3...)
- `forloop.index0` - Posição atual (0, 1, 2...)
- `forloop.first` - Verdadeiro se primeiro item
- `forloop.last` - Verdadeiro se último item
- `forloop.length` - Total de items

---

## 🔧 4. Filtros

### **4.1 Filtros de Texto**

#### **Básicos:**
```liquid
{{ contact.name | upcase }}           - JOÃO SILVA
{{ contact.name | downcase }}         - joão silva
{{ contact.name | capitalize }}       - João silva
{{ "  texto  " | strip }}             - texto
{{ "texto longo" | truncate: 10 }}    - texto l...
```

#### **Divisão e Junção:**
```liquid
{{ contact.name | split: " " | first }}        - João
{{ contact.name | split: " " | last }}         - Silva
{{ "palavra1,palavra2" | split: "," | join: " - " }}
```

### **4.2 Filtros de Números**

```liquid
{{ 100 | plus: 50 }}              - 150
{{ 100 | minus: 30 }}             - 70
{{ 10 | times: 5 }}               - 50
{{ 100 | divided_by: 4 }}         - 25
{{ 123.456 | round: 2 }}          - 123.46
```

### **4.3 Filtros de Arrays**

```liquid
{{ collection | size }}           - Tamanho da coleção
{{ collection | first }}          - Primeiro item
{{ collection | last }}           - Último item
{{ collection | sort }}           - Ordenar
{{ collection | reverse }}        - Reverter ordem
```

### **4.4 Filtros de Data**

```liquid
{{ "now" | date: "%d/%m/%Y" }}           - 15/12/2024
{{ "now" | date: "%H:%M" }}              - 14:30
{{ "now" | date: "%A, %d de %B" }}       - Segunda, 15 de dezembro
```

**Códigos de formatação:**
- `%Y` - Ano (2024)
- `%m` - Mês (12)
- `%d` - Dia (15)
- `%H` - Hora 24h (14)
- `%M` - Minutos (30)
- `%A` - Dia da semana (Segunda)
- `%B` - Nome do mês (dezembro)

### **4.5 Filtro DEFAULT (Super Importante)**

```liquid
{{ contact.name | default: "Cliente" }}
{{ contact.email | default: "não informado" }}
{{ contact.phone_number | default: "sem telefone" }}
```

---

## 📝 5. Variáveis e Operações

### **5.1 ASSIGN (Criar Variáveis)**

```liquid
{% assign nome_curto = contact.name | split: " " | first %}
{% assign total_msgs = conversation.recent_messages | size %}

Olá {{nome_curto}}!
Vocês já trocaram {{total_msgs}} mensagens.
```

### **5.2 CAPTURE (Capturar Conteúdo)**

```liquid
{% capture saudacao_completa %}
  {% if contact.name %}
    Olá {{contact.name}}
  {% else %}
    Olá amigo
  {% endif %}
{% endcapture %}

{{saudacao_completa}}! Como vai?
```

### **5.3 Operadores de Comparação**

```liquid
==    - Igual
!=    - Diferente  
>     - Maior que
<     - Menor que
>=    - Maior ou igual
<=    - Menor ou igual
contains - Contém
```

#### **Exemplos:**
```liquid
{% if contact.name contains "Silva" %}
  👨‍👩‍👧‍👦 Família Silva!
{% endif %}

{% assign msg_count = conversation.recent_messages | size %}
{% if msg_count > 5 %}
  📈 Conversa bem ativa! {{msg_count}} mensagens
{% endif %}
```

### **5.4 Operadores Lógicos**

```liquid
and   - E
or    - OU
```

```liquid
{% if contact.name and contact.email %}
  ✅ Dados completos: {{contact.name}} - {{contact.email}}
{% endif %}

{% if contact.email or contact.phone_number %}
  📞 Posso te contactar depois!
{% endif %}
```

---

## 🎯 6. Objetos Disponíveis

### **6.1 CONTACT (Contato)**

```liquid
{{contact.name}}           - Nome completo
{{contact.first_name}}     - Primeiro nome
{{contact.last_name}}      - Último nome
{{contact.email}}          - Email
{{contact.phone_number}}   - Telefone
{{contact.custom_attribute.campo}} - Atributos personalizados
```

### **6.2 USER/AGENT (Usuário/Agente)**

```liquid
{{user.name}}              - Nome do agente
{{user.first_name}}        - Primeiro nome
{{user.last_name}}         - Último nome
{{user.available_name}}    - Nome de exibição
{{agent.name}}             - Alias para user.name
```

### **6.3 CONVERSATION (Conversa)**

```liquid
{{conversation.display_id}}      - ID da conversa (#1234)
{{conversation.contact_name}}    - Nome do contato
{{conversation.recent_messages}} - Mensagens recentes (array)
{{conversation.custom_attribute.campo}} - Atributos personalizados
```

### **6.4 INBOX (Caixa de Entrada)**

```liquid
{{inbox.name}}             - Nome da caixa (Website, WhatsApp, etc.)
```

### **6.5 ACCOUNT (Conta)**

```liquid
{{account.name}}           - Nome da empresa/conta
```

---

## 💡 7. Exemplos Práticos por Categoria

### **7.1 Saudações Dinâmicas**

```liquid
{% if contact.first_name %}
  {% assign nome = contact.first_name %}
{% elsif contact.name %}
  {% assign nome = contact.name | split: " " | first %}
{% else %}
  {% assign nome = "amigo" %}
{% endif %}

{% assign hora = "now" | date: "%H" | plus: 0 %}
{% if hora >= 6 and hora < 12 %}
  🌅 Bom dia {{nome}}!
{% elsif hora >= 12 and hora < 18 %}
  ☀️ Boa tarde {{nome}}!
{% else %}
  🌙 Boa noite {{nome}}!
{% endif %}
```

### **7.2 Verificação de Dados**

```liquid
📋 **Status do cadastro:**
{% assign pontos = 0 %}

{% if contact.name %}
  ✅ Nome: {{contact.name}}
  {% assign pontos = pontos | plus: 25 %}
{% else %}
  ❌ Nome: não informado
{% endif %}

{% if contact.email %}
  ✅ Email: {{contact.email}}
  {% assign pontos = pontos | plus: 25 %}
{% else %}
  ❌ Email: não informado  
{% endif %}

{% if contact.phone_number %}
  ✅ Telefone: {{contact.phone_number}}
  {% assign pontos = pontos | plus: 25 %}
{% else %}
  ❌ Telefone: não informado
{% endif %}

---
📊 **Cadastro:** {{pontos}}% completo
{% if pontos < 75 %}
❗ Complete seus dados para melhor atendimento!
{% endif %}
```

### **7.3 Sistema de Prioridade**

```liquid
{% assign prioridade = "normal" %}

{% if contact.custom_attribute.vip == "sim" %}
  {% assign prioridade = "alta" %}
{% elsif conversation.recent_messages.size > 10 %}
  {% assign prioridade = "média" %}
{% endif %}

{% case prioridade %}
  {% when "alta" %}
    🌟 **CLIENTE VIP** - Atendimento prioritário
  {% when "média" %}
    ⚡ Cliente ativo - Acompanhamento especial
  {% else %}
    👋 Atendimento padrão
{% endcase %}
```

---

## 🚀 8. Casos de Uso Reais

### **8.1 Para E-commerce**

```liquid
Olá {{contact.first_name | default: "cliente"}}! 🛍️

{% if contact.custom_attribute.ultima_compra %}
  📦 Última compra: {{contact.custom_attribute.ultima_compra}}
  {% assign dias = "now" | date: "%j" | minus: contact.custom_attribute.ultima_compra_dias %}
  {% if dias > 30 %}
    🎁 Que tal dar uma olhada nas novidades?
  {% endif %}
{% else %}
  🎉 Primeira visita? Bem-vindo!
{% endif %}

💳 **Formas de pagamento:** PIX, Cartão, Boleto
🚚 **Frete grátis** acima de R$ 99
```

### **8.2 Para Agência/Consultoria**

```liquid
{% if contact.name %}{{contact.name}}{% else %}Futuro parceiro{% endif %}! 🚀

{% if contact.custom_attribute.segmento %}
  🎯 Segmento: {{contact.custom_attribute.segmento}}
  
  {% case contact.custom_attribute.segmento %}
    {% when "E-commerce" %}
      🛒 Temos cases incríveis em vendas online!
    {% when "Serviços" %}
      💼 Especialistas em geração de leads B2B
    {% when "SaaS" %}
      💻 Cases de sucesso em software
    {% else %}
      📈 Vamos descobrir a melhor estratégia!
  {% endcase %}
{% endif %}

{% unless contact.custom_attribute.orcamento %}
  💰 **Qual seu orçamento mensal?**
  • Até R$ 5mil
  • R$ 5k - R$ 15k
  • R$ 15k - R$ 50k
  • Acima de R$ 50k
{% endunless %}
```

### **8.3 Para Suporte Técnico**

```liquid
🔧 **Suporte {{account.name}}**

{% assign total_msgs = conversation.recent_messages | size %}
{% if total_msgs > 1 %}
  📊 Conversa em andamento ({{total_msgs}} mensagens)
  
  {% for message in conversation.recent_messages limit:3 %}
    {% if message.sender != user.available_name %}
      💬 Você: "{{message.content | truncate: 50}}"
    {% endif %}
  {% endfor %}
{% else %}
  🎯 Nova solicitação de suporte
{% endif %}

**Agente:** {{user.name}}
**Ticket:** #{{conversation.display_id}}
```

---

## 🧠 9. Dicas Avançadas

### **9.1 Escape de Caracteres**

```liquid
{% raw %}
Uso literal: {{contact.name}} (não processa)
{% endraw %}

Uso normal: {{contact.name}} (processa)
```

### **9.2 Comentários**

```liquid
{% comment %}
Este é um comentário - não aparece na mensagem final
{% endcomment %}

Mensagem visível aqui
```

### **9.3 Whitespace Control**

```liquid
{%- if contact.name -%}
  {{contact.name}}
{%- endif -%}
```
*Remove espaços em branco extras*

### **9.4 Controle de Espaços em Branco para WhatsApp**

**Este é um dos pontos mais importantes para garantir que suas mensagens fiquem perfeitas em canais como WhatsApp.**

**O Problema:** O Liquid processa a lógica (`{% if %}`), mas mantém a quebra de linha daquela tag. No WhatsApp, isso vira uma linha em branco.

**A Solução:** Use hifens (`-`) dentro das suas tags de lógica para "comer" os espaços em branco antes e/ou depois delas.

- `{%-` remove o espaço/quebra de linha **antes**.
- `-%}` remove o espaço/quebra de linha **depois**.

**Regra de ouro:** Use `{%- ... -%}` em **TODAS** as suas tags de lógica para não ter erro.

#### **Exemplo: Antes vs. Depois**

**Código ANTES (gera linhas vazias no WhatsApp):**
```liquid
{% if contact.name %}
  {% assign nome = contact.name | split: " " | first %}
{% endif %}
Olá {{nome}}!
```

**Código DEPOIS (perfeito no WhatsApp):**
```liquid
{%- if contact.name -%}
  {%- assign nome = contact.name | split: " " | first -%}
{%- endif -%}
Olá {{nome}}!
```

### **9.5 Aninhamento Complexo**

```liquid
{% for message in conversation.recent_messages %}
  {% assign sender = message.sender %}
  {% if sender != user.available_name %}
    {% unless message.content contains "arquivo" %}
      {% if forloop.index <= 3 %}
        {{forloop.index}}. {{sender}}: {{message.content | truncate: 100}}
      {% endif %}
    {% endunless %}
  {% endif %}
{% endfor %}
```

---

## ⚡ 10. Referência Rápida

### **Condicionais:**
```liquid
{% if %} {% elsif %} {% else %} {% endif %}
{% unless %} {% endunless %}
{% case %} {% when %} {% else %} {% endcase %}
```

### **Loops:**
```liquid
{% for item in collection %} {% endfor %}
{% for item in collection limit:n %} {% endfor %}
forloop.index, forloop.first, forloop.last
```

### **Variáveis:**
```liquid
{% assign var = value %}
{% capture var %} conteúdo {% endcapture %}
```

### **Filtros Essenciais:**
```liquid
| default: "valor"
| upcase | downcase | capitalize
| split: " " | join: "-"
| truncate: 50
| date: "%d/%m/%Y"
| size | first | last
```

### **Operadores:**
```liquid
== != > < >= <=
contains
and or
```

### **Objetos:**
```liquid
contact.name, contact.email, contact.phone_number
user.name, user.first_name
conversation.display_id
inbox.name
account.name
```

---

## 📞 Suporte

Este guia cobre **100% das funcionalidades Liquid** disponíveis no Chatwoot. Para dúvidas específicas:

1. Teste os exemplos em **Respostas Prontas**
2. Verifique a sintaxe nos **objetos disponíveis**
3. Use o **modo DEBUG** com `{{ variable | inspect }}` para ver estruturas

**Última atualização:** Dezembro 2024
**Versão:** 1.1 - Adicionado controle de whitespace para WhatsApp

