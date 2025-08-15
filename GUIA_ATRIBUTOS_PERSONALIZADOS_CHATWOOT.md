# 🏷️ GUIA COMPLETO: Atributos Personalizados no Chatwoot

Este guia mostra como dominar completamente o sistema de **Atributos Personalizados** (Custom Attributes) do Chatwoot - uma das funcionalidades mais poderosas para personalizar e otimizar seu atendimento.

---

## 🎯 **O QUE SÃO ATRIBUTOS PERSONALIZADOS?**

Os **Atributos Personalizados** permitem capturar e armazenar **informações específicas** sobre seus **contatos** e **conversas** que vão além dos campos padrão do Chatwoot.

### **📊 Exemplos Práticos:**
- 💰 **Valor do contrato** (para saber quanto o cliente vale)
- 🏢 **Empresa do cliente** (para segmentação) 
- 🎯 **Fonte de aquisição** (Facebook Ads, Google, Indicação)
- ⭐ **Nível de satisfação** (1-5 estrelas)
- 📅 **Data de renovação** (para follow-ups automáticos)
- 🎭 **Persona** (Decisor, Influenciador, Usuário)

---

## 🔄 **DOIS TIPOS DE ATRIBUTOS**

### **👤 ATRIBUTOS DE CONTATO (Contact Attributes)**
- **Se aplicam:** À pessoa/empresa específica
- **Persistem:** Entre todas as conversas daquele contato
- **Exemplos:** Nome da empresa, cargo, valor do contrato, data de nascimento

### **💬 ATRIBUTOS DE CONVERSA (Conversation Attributes)**
- **Se aplicam:** À conversa específica
- **Únicos:** Para cada conversa individual  
- **Exemplos:** Motivo do contato, urgência, produto de interesse, status do projeto

---

## 🎨 **8 TIPOS DE CAMPOS DISPONÍVEIS**

| **Tipo** | **Uso** | **Exemplo Prático** |
|----------|---------|---------------------|
| 📝 **Texto** | Informações livres | Nome da empresa, observações |
| 🔢 **Número** | Valores numéricos | Número de funcionários, idade |
| 💰 **Moeda** | Valores monetários | Valor do contrato, ticket médio |
| 📊 **Percentual** | Porcentagens | Taxa de conversão, desconto |
| 🔗 **Link** | URLs e links | Site da empresa, LinkedIn |
| 📅 **Data** | Datas importantes | Renovação, aniversário, deadline |
| 📋 **Lista** | Opções predefinidas | Plano (Básico/Pro/Enterprise) |
| ☑️ **Checkbox** | Sim/Não | Cliente ativo, lead qualificado |

---

## 🛠️ **COMO CRIAR ATRIBUTOS PERSONALIZADOS**

### **📍 Passo a Passo:**

1. **Ir para:** Configurações → Atributos Personalizados
2. **Clicar:** "Criar atributo personalizado"  
3. **Preencher:**

#### **🎯 Campos Obrigatórios:**
```
Nome para exibição: "Valor do Contrato"
Descrição: "Valor mensal do contrato do cliente"
Aplica-se a: "Contato" ou "Conversas"
Tipo: "Moeda" 
Chave: "valor_contrato" (gerada automaticamente)
```

#### **🔧 Campos Opcionais:**
```
Valores da Lista: (para tipo "Lista")
Regex Pattern: Validação personalizada
Regex Cue: Mensagem de erro customizada
```

---

## 🚀 **USANDO COM LIQUID/VARIÁVEIS**

### **🎯 Sintaxe no Liquid:**

#### **Para Atributos de CONTATO:**
```liquid
{{contact.custom_attribute.nome_do_campo}}
```

#### **Para Atributos de CONVERSA:**
```liquid
{{conversation.custom_attribute.nome_do_campo}}
```

### **💡 Exemplos Práticos:**

#### **📧 Email Personalizado:**
```liquid
Olá {{contact.first_name | default: contact.name}}!

Empresa: {{contact.custom_attribute.empresa}}
Valor do Contrato: R$ {{contact.custom_attribute.valor_contrato}}
Renovação: {{contact.custom_attribute.data_renovacao | date: "%d/%m/%Y"}}

{% if contact.custom_attribute.plano == "Enterprise" %}
Como cliente Enterprise, você tem suporte prioritário! 🌟
{% elsif contact.custom_attribute.plano == "Pro" %}  
Seu plano Pro inclui consultoria especializada! 💼
{% else %}
Que tal conhecer nossos planos Pro e Enterprise? 🚀
{% endif %}

Att,
{{agent.name}}
```

#### **⚡ Atalho Contextual:**
```liquid
{% assign motivo = conversation.custom_attribute.motivo_contato %}
{% assign urgencia = conversation.custom_attribute.urgencia %}

{% if urgencia == "Alta" %}🚨 URGENTE: {% endif %}

Olá {{contact.first_name | default: contact.name}}!

{% case motivo %}
{% when "Suporte Técnico" %}
Nossa equipe técnica está analisando sua solicitação.
Tempo estimado: {% if urgencia == "Alta" %}2h{% else %}24h{% endif %}

{% when "Dúvida Comercial" %}
Vou conectar você com nosso especialista comercial.
{{contact.custom_attribute.empresa}} tem potencial para nosso plano {{contact.custom_attribute.plano_interesse | default: "Pro"}}!

{% when "Renovação" %}
Sua renovação está próxima: {{contact.custom_attribute.data_renovacao | date: "%d/%m/%Y"}}
Valor atual: R$ {{contact.custom_attribute.valor_contrato}}
{% endcase %}

Att,
{{agent.name}}
```

---

## 💼 **CASOS PRÁTICOS PARA AGÊNCIA DE TRÁFEGO**

### **👤 ATRIBUTOS DE CONTATO ESSENCIAIS:**

#### **📊 Dados Comerciais:**
```
💰 ticket_medio (Moeda) - Ticket médio mensal
📈 faturamento_atual (Moeda) - Faturamento atual  
🎯 meta_faturamento (Moeda) - Meta de faturamento
📅 data_inicio_contrato (Data) - Início do contrato
📅 data_renovacao (Data) - Renovação do contrato
🏢 segmento_empresa (Lista) - E-commerce, Serviços, SaaS, Físico
👥 numero_funcionarios (Número) - Porte da empresa
```

#### **🎭 Segmentação:**
```
⭐ nivel_maturidade (Lista) - Iniciante, Intermediário, Avançado  
🎯 fonte_aquisicao (Lista) - Facebook Ads, Google, Indicação, Site
📊 plano_atual (Lista) - Básico, Pro, Enterprise
🎪 persona (Lista) - Decisor, Influenciador, Usuário
🌟 score_cliente (Número) - Score de 1-10
✅ cliente_ativo (Checkbox) - Cliente ativo ou não
```

### **💬 ATRIBUTOS DE CONVERSA ÚTEIS:**

#### **🎯 Contexto do Atendimento:**
```
🎭 motivo_contato (Lista) - Suporte, Comercial, Financeiro, Técnico
🚨 urgencia (Lista) - Baixa, Média, Alta, Crítica  
📊 tipo_demanda (Lista) - Otimização, Novo Canal, Relatório, Bug
💡 produto_interesse (Lista) - Facebook Ads, Google Ads, LinkedIn, TikTok
⏰ tempo_resposta_esperado (Lista) - Imediato, 2h, 24h, 48h
🏆 resultado_esperado (Texto) - Descrição do que o cliente espera
```

---

## 🤖 **INTEGRAÇÃO COM AUTOMAÇÕES**

### **🎯 Regras de Automação Baseadas em Atributos:**

#### **📊 Exemplo 1: Roteamento por Valor do Cliente**
```
SE: contact.custom_attribute.ticket_medio > 5000
ENTÃO: 
  - Atribuir para: "Gerente de Contas VIP"
  - Adicionar etiqueta: "Cliente Premium"
  - Prioridade: "Alta"
```

#### **⏰ Exemplo 2: Follow-up de Renovação**
```
SE: contact.custom_attribute.data_renovacao está em "30 dias"
ENTÃO:
  - Enviar email: Template "Renovação Próxima"
  - Criar tarefa: "Follow-up renovação - {contact.name}"
  - Notificar: Equipe comercial
```

#### **🎭 Exemplo 3: Resposta por Persona**
```
SE: conversation.custom_attribute.motivo_contato == "Técnico"
   E contact.custom_attribute.plano_atual == "Enterprise"
ENTÃO:
  - Atribuir para: "Suporte Técnico Senior"  
  - SLA: "2 horas"
  - Template: "Suporte Enterprise Prioritário"
```

---

## 📊 **RELATÓRIOS E FILTROS AVANÇADOS**

### **🔍 Filtros por Atributos Personalizados:**

#### **📈 Análises de Segmentação:**
- **Por ticket médio:** Clientes > R$ 10k vs < R$ 2k
- **Por fonte:** Facebook Ads vs Google vs Indicação  
- **Por segmento:** E-commerce vs Serviços vs SaaS
- **Por maturidade:** Iniciante vs Intermediário vs Avançado

#### **📊 Relatórios Personalizados:**
- **ROI por canal:** Ticket médio × Fonte de aquisição
- **Renovações próximas:** Clientes com renovação em 30 dias
- **Clientes inativos:** Última conversa > 90 dias + Ticket > R$ 5k
- **Oportunidades:** Leads qualificados + Meta > Faturamento atual

---

## 🎯 **DICAS AVANÇADAS DE USO**

### **💡 Conditional Logic no Liquid:**

#### **🎨 Template Dinâmico por Segmento:**
```liquid
{% assign segmento = contact.custom_attribute.segmento_empresa %}
{% assign ticket = contact.custom_attribute.ticket_medio %}

Olá {{contact.first_name | default: contact.name}}!

{% case segmento %}
{% when "E-commerce" %}
  📦 Para e-commerces como {{contact.custom_attribute.empresa}}, 
  nossa especialidade é:
  • Facebook/Instagram Shopping Ads
  • Google Shopping + Performance Max
  • Remarketing para carrinho abandonado
  
  {% if ticket >= 5000 %}
  Com seu ticket de R$ {{ticket}}, recomendamos também TikTok Ads! 🚀
  {% endif %}

{% when "SaaS" %}
  💻 Para SaaS, nossa estratégia inclui:
  • LinkedIn Ads para B2B
  • Google Ads para long-tail keywords
  • Remarketing por trial e free users
  
{% when "Serviços" %}  
  🏢 Para prestadores de serviço:
  • Google Ads local + extensions
  • Facebook Ads para público local
  • YouTube Ads para demonstração
{% endcase %}

Vamos marcar uma call para mostrar cases específicos do seu segmento?

Att,
{{agent.name}}
```

#### **⚡ Template por Urgência:**
```liquid
{% assign urgencia = conversation.custom_attribute.urgencia %}
{% assign motivo = conversation.custom_attribute.motivo_contato %}

{% if urgencia == "Crítica" %}
🚨 CRÍTICO: Acionando equipe especializada imediatamente!
Tempo de resposta: Máximo 1 hora
{% elsif urgencia == "Alta" %}  
⚡ ALTA PRIORIDADE: Seu caso foi escalado
Tempo de resposta: Máximo 4 horas
{% elsif urgencia == "Média" %}
📋 PRIORIDADE MÉDIA: Em análise
Tempo de resposta: Até 24 horas  
{% else %}
📝 PRIORIDADE NORMAL: Na fila de atendimento
Tempo de resposta: Até 48 horas
{% endif %}

Motivo: {{motivo}}
{% if conversation.custom_attribute.produto_interesse %}
Produto de interesse: {{conversation.custom_attribute.produto_interesse}}
{% endif %}
```

---

## 📱 **INTEGRAÇÃO COM APIs**

### **🔧 Atualizando Atributos via API:**

#### **📊 Contato:**
```javascript
// Atualizar atributos de contato
POST /api/v1/accounts/{account_id}/contacts/{contact_id}/custom_attributes

{
  "custom_attributes": {
    "ticket_medio": 8500,
    "data_renovacao": "2024-06-15",
    "plano_atual": "Pro",
    "score_cliente": 9
  }
}
```

#### **💬 Conversa:**
```javascript
// Atualizar atributos de conversa  
POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/custom_attributes

{
  "custom_attributes": {
    "motivo_contato": "Suporte Técnico",
    "urgencia": "Alta",
    "produto_interesse": "Google Ads",
    "tempo_resposta_esperado": "2h"
  }
}
```

---

## 🎯 **CONFIGURAÇÕES PARA AGÊNCIA - SETUP COMPLETO**

### **👤 ATRIBUTOS DE CONTATO RECOMENDADOS:**

#### **💰 Financeiro:**
```
• ticket_medio (Moeda) - "Ticket Médio Mensal"
• faturamento_atual (Moeda) - "Faturamento Atual" 
• meta_faturamento (Moeda) - "Meta de Faturamento"
• investimento_trafego (Moeda) - "Investimento Atual em Tráfego"
• roas_atual (Número) - "ROAS Atual"
```

#### **📊 Negócio:**
```
• segmento_empresa (Lista) - E-commerce, SaaS, Serviços, Físico, Infoprodutos
• fonte_aquisicao (Lista) - Facebook, Google, LinkedIn, Indicação, Site, Evento
• plano_atual (Lista) - Trial, Básico, Pro, Enterprise, Custom
• nivel_maturidade (Lista) - Iniciante, Intermediário, Avançado, Expert
• canais_interesse (Lista) - Facebook Ads, Google Ads, TikTok, LinkedIn, YouTube
```

#### **👥 Relacionamento:**
```
• persona (Lista) - Decisor, Influenciador, Usuário, Analista
• cargo (Texto) - "Cargo do Contato Principal"
• empresa (Texto) - "Nome da Empresa"  
• numero_funcionarios (Número) - "Número de Funcionários"
• cliente_ativo (Checkbox) - "Cliente Ativo"
• nps_score (Número) - "Score NPS (0-10)"
```

### **💬 ATRIBUTOS DE CONVERSA RECOMENDADOS:**

#### **🎯 Atendimento:**
```
• motivo_contato (Lista) - Suporte, Comercial, Financeiro, Técnico, Onboarding
• urgencia (Lista) - Baixa, Média, Alta, Crítica
• canal_origem (Lista) - WhatsApp, Email, Chat, Telefone, Formulário
• tipo_demanda (Lista) - Otimização, Novo Canal, Relatório, Bug, Dúvida
• satisfacao (Lista) - 1, 2, 3, 4, 5
```

#### **📊 Comercial:**
```
• produto_interesse (Lista) - Facebook Ads, Google Ads, LinkedIn, TikTok, Consultoria
• orcamento_informado (Moeda) - "Orçamento Informado pelo Cliente"
• tempo_decisao (Lista) - Imediato, 1 semana, 1 mês, 3 meses
• concorrente (Texto) - "Agência Atual/Concorrente"
• resultado_esperado (Texto) - "Resultado Esperado pelo Cliente"
```

---

## 🚀 **MELHORES PRÁTICAS**

### **✅ DO's (Faça):**
- **🎯 Planeje** os atributos antes de criar (pense nos relatórios que quer)
- **📝 Use nomes claros** e padronizados (sem espaços na chave)
- **📋 Liste** opções quando possível (evite texto livre desnecessário)  
- **🔄 Integre** com automações desde o início
- **📊 Monitore** o uso e qualidade dos dados
- **🎨 Use** com Liquid para personalização máxima

### **❌ DON'Ts (Não faça):**
- **🚫 Não** crie muitos atributos de uma vez (comece com essenciais)
- **⚠️ Não** altere chaves após criar (pode quebrar automações)
- **📝 Não** use texto livre para dados categorizáveis  
- **🔄 Não** esqueça de treinar a equipe sobre preenchimento
- **💾 Não** deixe campos importantes vazios

---

## 🔧 **TROUBLESHOOTING COMUM**

### **❌ Problema:** Atributo não aparece no Liquid
**✅ Solução:**
```
1. Verificar se o atributo foi criado corretamente
2. Confirmar se há dados preenchidos
3. Usar sintaxe correta: contact.custom_attribute.nome_do_campo
4. Testar com {‌{contact.custom_attribute}} para ver todos campos
```

### **❌ Problema:** Automação não funciona com atributo
**✅ Solução:**
```
1. Verificar se o valor está exatamente igual ao esperado
2. Considerar maiúsculas/minúsculas (case-sensitive)
3. Para datas, usar formato correto (YYYY-MM-DD)
4. Para números, verificar se não há caracteres especiais
```

### **❌ Problema:** Atributo Lista não funciona
**✅ Solução:**
```
1. Verificar se os valores foram cadastrados na criação
2. Certificar que o valor selecionado está na lista
3. Não usar acentos ou caracteres especiais nos valores
4. Testar primeiro manualmente antes de usar em automações
```

---

## 📈 **RESULTADOS ESPERADOS**

Implementando atributos personalizados corretamente, você terá:

### **🎯 Atendimento:**
- ✅ **Contexto imediato** - Agente sabe quem é o cliente antes de responder
- ✅ **Roteamento inteligente** - Cliente VIP vai direto para gerente  
- ✅ **Respostas personalizadas** - Templates dinâmicos por perfil
- ✅ **Follow-ups automáticos** - Baseados em datas e eventos

### **📊 Gestão:**
- ✅ **Relatórios segmentados** - ROI por canal, ticket por segmento
- ✅ **Previsibilidade** - Renovações, churn, oportunidades
- ✅ **Otimização** - Identificar padrões e melhorar processos
- ✅ **Escalabilidade** - Sistema estruturado para crescer

### **💰 Comercial:**
- ✅ **Qualificação automática** - Score leads por atributos
- ✅ **Upsell inteligente** - Ofertas baseadas no perfil
- ✅ **Retenção melhorada** - Identificar riscos antecipadamente  
- ✅ **Crescimento** - Dados para tomar decisões estratégicas

---

## 🏆 **CONCLUSÃO**

Os **Atributos Personalizados** são a diferença entre um **atendimento genérico** e um **atendimento de alto nível**. Com eles, você transforma o Chatwoot numa **ferramenta de CRM poderosa** que conhece profundamente seus clientes.

**Comece pequeno, pense grande!** 🚀

1. **Semana 1:** Crie 3-5 atributos essenciais
2. **Semana 2:** Configure automações básicas  
3. **Semana 3:** Crie templates Liquid personalizados
4. **Semana 4:** Configure relatórios e análises

Em 1 mês, você terá um sistema de atendimento **completamente personalizado** e **orientado por dados**!

---

**Última atualização:** Janeiro 2025  
**Status:** ✅ Guia completo testado em produção  
**Casos de uso:** Agências, E-commerce, SaaS, Serviços  
**Complexidade:** Intermediário a Avançado
