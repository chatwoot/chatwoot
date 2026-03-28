# SDD — Ecossistema IgaraLead

## 1. Objetivo do documento

Este documento consolida o estado atual do ecossistema IgaraLead e descreve o plano maior de arquitetura, operação e evolução das plataformas.

Escopo deste SDD:

- Hub como plataforma central do ecossistema
- Entity como produto de enriquecimento e dados
- Amplex como CRM baseado em Odoo
- Nexus como plataforma omnichannel baseada em Chatwoot
- Baileys como camada técnica de WhatsApp para o Nexus
- Automata como oferta de consultoria e automação
- Site institucional como camada pública de posicionamento comercial

O documento assume o estado corrente do projeto em março de 2026.

## 2. Visão executiva

A IgaraLead está construindo um ecossistema de receita modular no qual cada produto pode ser vendido separadamente, mas todos convergem para uma operação integrada quando conectados ao Hub.

O desenho estratégico atual é:

- O Hub é a central administrativa do ecossistema, gerenciando identidade, organizações, contatos compartilhados, assinaturas, permissões, precificação e métricas agregadas. Os dados ficam armazenados na infraestrutura compartilhada (Infra) e o Hub é uma das formas de acessá-los e gerê-los — não a única.
- Cada produto mantém sua especialização operacional e seus próprios dados de domínio.
- O acesso do cliente deve ser consistente em todas as plataformas através do padrão `/c/{cliente}`.
- A experiência comercial deve permitir venda modular por orçamento, sem perder a visão unificada do cliente.
- A experiência visual está convergindo para uma linguagem comum IgaraLead, sem apagar as características de cada produto.

Em termos práticos, o ecossistema já saiu da fase conceitual. O Hub, o Entity, o Nexus e o Amplex já têm integração funcional em pontos críticos, com gaps concentrados em robustez operacional, observabilidade, testes e governança de configuração.

## 3. Princípios de arquitetura

### 3.1. Infraestrutura compartilhada e administração centralizada

A infraestrutura compartilhada (Infra) hospeda os recursos comuns do ecossistema: postgres, redis e minio. Os dados de identidade, organizações e assinaturas ficam nessa camada compartilhada.

O Hub atua como central administrativa — uma interface para gerenciar esses dados. Ele não é a "fonte de verdade" em si, mas sim uma das formas de acessar e modificar os dados armazenados na infra. Cada plataforma também pode ler e, quando necessário, escrever nesses dados.

O Hub administra:

- autenticação
- organizações e client slug
- usuários e papéis
- assinaturas e limites
- contatos compartilhados
- integração entre produtos
- visão consolidada de métricas
- configurações de super-admin de todas as plataformas

Produtos satélite não devem reinventar billing, identidade ou gestão global quando esses dados já existirem no Hub.

### 3.2. Produtos especializados

Cada plataforma continua responsável pelo seu domínio principal:

- Amplex: CRM e processo comercial
- Nexus: atendimento e relacionamento omnichannel
- Entity: enriquecimento, prospecção e crédito de consultas
- Baileys: transporte WhatsApp
- Automata: desenho e execução de automações

### 3.3. Isolamento por cliente

O isolamento de tenant é mandatório em toda a arquitetura. O padrão oficial é:

- `hub.igaralead.com.br/c/{cliente}`
- `amplex.igaralead.com.br/c/{cliente}`
- `nexus.igaralead.com.br/c/{cliente}`
- `cnpj.igaralead.com.br/c/{cliente}`

O `client_slug` do token precisa corresponder ao `cliente` da URL. Esse contrato já está definido e já foi parcialmente aplicado no ecossistema.

### 3.4. Tratamentos dos forks

Cada fork é tratado de uma maneira específica. A estratégia atual depende do tipo de licença do repositório de origem do fork:

- Amplex: baseado no Odoo, que é licenciado em LGPLv3. Tratamento ideal é estudar como o original funciona e replicar funcionalidades desejadas sem copiar códigos
- Nexus: baseado no Chatwoot (apenas arquivos do Community Edition), que é licenciado em MIT Expat. Tratamento ideal é modificar a plataforma de acordo com o desejado, adaptando ela para ficar independente dos arquivos da edição enterprise
- Baileys: licenciado em MIT. É utilizado em conjunto com o Nexus, fornecendo os dados para o canal de WhatsApp Web (API QR code). Tratamento ideal é continuar usando ele como sidecar do Nexus, ajustando o Nexus conforme novas funcionalidades ou mudanças às funcionalidades e processos existentes.

### 3.5. Sem APIs abertas

O ecossistema não expõe APIs públicas para consumo externo. Toda comunicação é exclusivamente interna entre as plataformas (service-to-service via `X-Api-Key` ou JWT do Hub). Clientes acessam os produtos apenas via interface web. Esta decisão poderá ser reavaliada no futuro, mas no momento presente não há previsão de APIs abertas.

### 3.6. Happy path primeiro

O ecossistema foi conduzido com estratégia MVP-first. Isso significa que boa parte do estado atual privilegia fluxos principais já funcionando, enquanto itens como automação operacional, suíte de testes ampla e observabilidade completa ainda estão em maturação.

## 4. Estado atual do ecossistema

### 4.1. Hub

#### Papel no ecossistema

O Hub é a plataforma central do grupo. Ele conecta identidade, organizações, contatos, assinaturas, limites, integrações cross-product e dashboards consolidados.

#### Stack atual

- Backend em FastAPI
- Frontend em React + Vite + TypeScript
- PostgreSQL + Redis
- Docker Compose para desenvolvimento e deploy local

#### Estado funcional atual

O Hub já possui base operacional relevante:

- autenticação com JWT
- emissão e validação de claims de escopo
- JWKS exposto para consumo pelos demais produtos
- CRUD de organizações, usuários e contatos
- gestão de pricing modular
- gestão de cupons
- fluxo de orçamentos
- conversão de orçamento em organização e assinatura
- onboarding via convite
- endpoints voltados aos produtos (`/c/{slug}/settings`, `/subscription`, `/organization`)
- endpoints agregadores de métricas
- mapa inicial de integrações cross-product

#### Estado de produto

O Hub já é mais do que um MVP conceitual. Ele está suficientemente maduro para atuar como backplane de identidade, contratos de assinatura e integração entre produtos.

Hoje, ele já concentra o modelo comercial do ecossistema:

- venda por orçamento
- composição modular de preço por produto e métrica
- provisionamento de créditos do Entity
- definição de limites consumidos por Nexus e Amplex

#### Gaps atuais

Os principais gaps do Hub são de consolidação e escala operacional:

- melhorar o painel do cliente para gestão mais completa de usuários e organização
- ampliar o painel de super-admin para configurações globais por produto
- adicionar observabilidade forte
- introduzir envio real de emails
- expandir testes automatizados
- fortalecer analytics de uso e receita

#### Leitura estratégica

O Hub já está no papel correto de central administrativa do ecossistema. O foco agora não é reinventar o Hub, mas endurecer sua operação e ampliar a profundidade das funcionalidades administrativas.

### 4.2. Entity

#### Papel no ecossistema

O Entity é o produto de enriquecimento, prospecção e consultas de dados. Ele é o ativo próprio mais alinhado com geração de demanda e inteligência comercial.

#### Stack atual

- Backend em Python/FastAPI
- Frontend web próprio
- Docker Compose para orquestração
- billing local descontinuado em favor do Hub
- **Dual database**: dados de usuário no postgres compartilhado (VPS 1 / Infra), dados CNPJ no postgres dedicado (VPS 2)

#### Arquitetura de banco de dados

O Entity usa dois bancos PostgreSQL:

| Banco | Localização | Env var | Tabelas |
|-------|------------|---------|---------|
| User DB | VPS 1 (Infra postgres) | `DATABASE_URL` | usuarios, creditos, historico_buscas, assinaturas, config_sistema, organizacoes, org_members, logs_acoes |
| CNPJ DB | VPS 2 (postgres dedicado) | `CNPJ_DATABASE_URL` | estabelecimento, empresa, simples, socios, municipio/munic, cnae, natju, moti, quals, pais |

Em desenvolvimento, ambos apontam para o mesmo postgres local. Em produção, o CNPJ DB roda no VPS 2 junto com o Entity, enquanto o User DB fica no VPS 1 com a infraestrutura compartilhada.

#### Estado funcional atual

O produto já cobre:

- autenticação integrada ao Hub
- escopo por `client_slug`
- gestão de créditos
- histórico de consultas
- mecanismos administrativos
- métricas do produto
- provisionamento de créditos disparado pelo Hub

Uma mudança estrutural importante já aconteceu: o Entity deixou de ser responsável por login local e billing local. Isso simplifica o produto e reforça o modelo de ecossistema.

#### Estado de integração

O Entity já consome o Hub como provedor de identidade e como origem da alocação comercial. Isso coloca o produto em bom estágio de acoplamento saudável ao ecossistema.

#### Gaps atuais

- isolar mais a lógica de criação de usuários em serviços dedicados
- documentar com mais rigor as configurações administrativas existentes
- ampliar cobertura de testes
- evoluir ETL e governança de pipeline como componentes mais explícitos da arquitetura

#### Leitura estratégica

O Entity está bem posicionado como motor de aquisição e inteligência de dados do ecossistema. A próxima etapa é transformar robustez operacional e governança em diferenciais claros, não apenas funcionalidades isoladas.

### 4.3. Amplex

#### Papel no ecossistema

O Amplex é o CRM do ecossistema, construído sobre Odoo com customização orientada a CRM-only. Sua função é operacionalizar pipeline, oportunidades e rotina comercial.

#### Stack atual

- Fork de Odoo
- customizações em módulos próprios
- deploy preparado com Docker
- configuração dedicada para operação CRM-only

#### Estado funcional atual

O Amplex já possui:

- branding IgaraLead
- estrutura de integração com o Hub
- OAuth com provedor do Hub
- sincronização de contatos com o Hub
- verificação de assinatura ativa
- endpoint de métricas
- endpoint de integração cross-product
- enforcement de limite de usuários
- bloqueio de login local por senha quando Hub estiver ativo

Também já existe baseline de infraestrutura para deploy específico do produto, com arquivos de configuração, Dockerfile e compose.

#### Estado arquitetural

O uso de módulos separados em `igaralead_addons/` é a decisão incorreta. O ideal é usar o Odoo como referência e criar código novo para suprir todas as demandas do frontend e do ecossistema, restringindo completamente qualquer reaproveitamento de código do Odoo.

#### Gaps atuais

- consolidar multi-company quando necessário
- mapear configurações globais existentes para migração plena ao Hub
- aumentar clareza documental sobre o modelo operacional do CRM-only
- ampliar testes de integração nos fluxos Hub ↔ Amplex

#### Leitura estratégica

O Amplex já deixou de ser apenas um fork adaptado e passou a atuar como CRM integrado de verdade dentro do ecossistema. O maior risco aqui é a dependência do Odoo, que deve ser substituído por código próprio.

### 4.4. Nexus

#### Papel no ecossistema

O Nexus é a plataforma de atendimento, relacionamento e comunicação omnichannel. Ele conecta operação de suporte, vendas conversacionais e histórico de interação com cliente.

#### Stack atual

- Fork de Chatwoot
- Backend Rails
- Frontend Vue
- Sidekiq, ActionCable e stack padrão Chatwoot
- overlay enterprise preservado

#### Estado funcional atual

O Nexus já apresenta um grau avançado de integração com o Hub:

- branding IgaraLead aplicado
- validação de token do Hub com JWKS
- login por Hub/SSO
- bloqueio de login local por senha
- leitura de configurações e limites a partir do Hub
- endpoint de métricas por cliente
- enforcement de limites de usuários e canais
- estrutura própria para código IgaraLead em `app/igaralead/`
- evolução do canal WhatsApp com suporte à integração Baileys

#### Estado de produto

Entre as plataformas do ecossistema, o Nexus é uma das mais sensíveis porque combina volume operacional, UI complexa, múltiplos canais e forte dependência de UX. Ainda assim, a plataforma já está funcionalmente alinhada com o Hub.

#### Gaps atuais

- endurecer testes de integração e regressão
- consolidar o fluxo do WhatsApp até produção com disciplina operacional
- garantir que sincronização de contatos e métricas cubra todos os cenários críticos
- converter frontend para React + Vite para padronização de linguagem no ambiente de desenvolvimento frontend, e padronizar interface com tema IgaraLead
- criar integração natural com o Amplex, onde um complementa o outro com botões de ação, registros, etc.

#### Leitura estratégica

O Nexus tem potencial de ser a face mais visível do ecossistema no dia a dia do cliente. Por isso, confiabilidade, performance e clareza de operação valem mais aqui do que expansão acelerada de features periféricas.

### 4.5. Baileys

#### Papel no ecossistema

Baileys não é um produto final. Ele é a camada de protocolo WhatsApp (API Web - vínculo via QR code) usada para viabilizar o canal no Nexus.

#### Estado atual

O contrato arquitetural está claro:

- Baileys é transporte, não domínio de negócio
- o isolamento multi-tenant deve ser imposto pelo Nexus
- sessões precisam carregar `client_slug`
- armazenamento de sessão deve ser segregado por cliente

#### Gaps atuais

- concluir padronização do wrapper de sessão
- fechar dependências operacionais em ambiente Docker
- garantir fluxo completo de mensagens e contatos alinhado ao Hub por intermédio do Nexus

#### Leitura estratégica

Baileys deve permanecer fino. Quanto mais regra de negócio for empurrada para a biblioteca, maior será o custo de manutenção e menor a clareza da arquitetura.

### 4.6. Automata

#### Papel no ecossistema

Automata é uma oferta de consultoria e execução de automações, não uma plataforma SaaS autônoma nos mesmos moldes de Hub, Entity, Amplex e Nexus.

O posicionamento atual é correto:

- criação de fluxos sob medida
- uso de n8n como motor de automação quando fizer sentido
- o cliente recebe o resultado da automação, não uma redistribuição indevida de software licenciado

#### Estado atual

Automata está mais maduro como proposta comercial do que como produto técnico interno. Isso não é um problema, desde que a oferta seja tratada como camada de serviço integrada ao ecossistema.

#### Direção recomendada

Automata deve operar como:

- serviço profissional que integra Hub, Entity, Nexus e Amplex
- acelerador de implantação para clientes enterprise
- camada de orquestração de processos que o Hub futuramente pode catalogar e monitorar

#### Leitura estratégica

Automata é importante porque amplia ticket médio, reduz fricção de implantação e cria stickiness. O erro a evitar é tentar transformá-lo cedo demais em produto genérico antes de consolidar os casos recorrentes.

### 4.7. Site institucional

#### Papel no ecossistema

O site institucional é a interface pública de posicionamento da IgaraLead. Ele não é apenas marketing; ele precisa refletir corretamente a tese do ecossistema.

#### Estado atual

O site foi convertido para React + Vite e já reflete o portfólio com:

- Hub
- Entity
- Amplex
- Nexus
- Automata

#### Leitura estratégica

Esse site deve permanecer alinhado com o modelo comercial do ecossistema. Ele precisa vender a integração entre produtos, não apenas listar soluções isoladas.

## 5. Estado atual de integração entre plataformas

### 5.1. Identidade e autenticação

Estado atual:

- Hub emite identidade e claims de escopo
- Nexus já valida via JWKS
- Entity já usa fluxo Hub-based
- Amplex já usa Hub como provedor de login

Conclusão:

O eixo de identidade do ecossistema já existe e já está funcional. O trabalho agora é consolidar cobertura, testes e observabilidade.

### 5.2. Isolamento por cliente

Estado atual:

- contrato `/c/{cliente}` definido
- validação de `client_slug` prevista e parcialmente aplicada
- escopo por cliente já orienta a arquitetura dos produtos

Conclusão:

O modelo está correto. O maior cuidado daqui para frente é não permitir rotas legadas sem escopo ou atalhos operacionais fora desse padrão.

### 5.3. Dados compartilhados

Estado atual:

- Hub centraliza entidades comuns
- contatos já entram como ponto forte de sincronização
- produtos expõem métricas para consolidação

Conclusão:

O ecossistema caminha para uma visão 360 do cliente, mas ainda precisa disciplinar melhor ownership, consistência eventual e reconciliação de dados.

### 5.4. Billing e comercial

Estado atual:

- Hub concentra precificação, orçamento e assinatura
- Entity já foi desoplado do billing local
- Amplex e Nexus já consomem limites definidos pelo Hub

Conclusão:

O modelo comercial do ecossistema já está ancorado corretamente. O que falta é maturidade operacional, especialmente em histórico de pagamentos, auditoria e gestão administrativa avançada.

### 5.5. Observabilidade

Estado atual:

- métricas de produto já existem em mais de uma plataforma
- logging e healthchecks existem em partes da stack

Conclusão:

Observabilidade ainda é um dos maiores gaps transversais do ecossistema. Sem isso, escalar operação e suporte ficará caro.

## 6. Plano maior para o ecossistema

### 6.1. Meta principal

Transformar o portfólio atual em uma plataforma integrada de receita, em que aquisição, relacionamento, operação comercial, atendimento e automação compartilham contexto, identidade e governança.

### 6.2. Resultado estratégico esperado

Ao fim das próximas fases, a IgaraLead deve oferecer:

- uma entrada única para o cliente
- gestão centralizada de usuários, permissões e assinaturas
- visão unificada de contatos e contas
- uso combinado de CRM, dados, atendimento e automação
- dashboards consolidados de receita, operação e produtividade
- implantação enterprise, visando esforço de integração manual próximo a zero

### 6.3. Fases de evolução

#### Fase 1 — Consolidação do core integrado

Objetivo:

- endurecer autenticação, escopo e limites em todos os produtos

Prioridades:

- eliminar rotas não escopadas remanescentes
- fechar testes de autenticação e autorização cross-product
- endurecer sincronização de contatos
- estabilizar endpoints de métricas

#### Fase 2 — Governança operacional

Objetivo:

- tornar o ecossistema operável em escala

Prioridades:

- observabilidade central
- logs estruturados
- alertas
- trilhas de auditoria
- configuração global por produto via Hub

#### Fase 3 — Camada comercial madura

Objetivo:

- transformar o modelo por orçamento em operação previsível

Prioridades:

- histórico financeiro
- gestão administrativa avançada
- governança de cupons, contratos e limites
- onboarding mais automatizado

#### Fase 4 — Inteligência cross-product

Objetivo:

- usar o ecossistema como vantagem competitiva real

Prioridades:

- dashboards consolidados por cliente
- workflows entre plataformas
- gatilhos de automação baseados em eventos de produto
- recomendação operacional usando contexto combinado

#### Fase 5 — Productização seletiva do Automata

Objetivo:

- transformar casos recorrentes de automação em ativos replicáveis

Prioridades:

- catálogo de automações
- templates internos por vertical
- monitoramento das automações contratadas
- integração da operação do Automata ao Hub

## 7. Riscos principais

### 7.1. Risco de fragmentação arquitetural

Se cada produto evoluir integrações à sua maneira, o Hub perde autoridade como central administrativa e o ecossistema vira apenas um conjunto de integrações frágeis.

### 7.2. Risco de drift visual e operacional

A convergência de design e experiência precisa continuar, mas sem forçar uniformidade artificial em stacks com naturezas diferentes.

### 7.3. Risco de manutenção dos forks

Nexus precisa manter disciplina de extensão. Modificar core sem critério aumenta custo de merge e reduz previsibilidade.

### 7.4. Risco de baixa observabilidade

Sem telemetria adequada, qualquer crescimento de base ou volume operacional pode degradar suporte, onboarding e confiabilidade.

### 7.5. Risco de escopo do Automata

Automata pode virar um dreno operacional se for tratado como qualquer pedido customizado sem catalogação mínima, padrões e critérios de repetibilidade.

## 8. Próximos passos recomendados

### 8.1. Curto prazo

- formalizar este SDD como referência viva do ecossistema
- criar matriz de ownership de dados por domínio
- fechar checklist de autenticação e escopo por cliente em todos os produtos
- definir baseline de observabilidade compartilhada

### 8.2. Médio prazo

- consolidar dashboards cross-product no Hub
- ampliar gestão administrativa por organização
- integrar histórico financeiro e eventos comerciais
- padronizar eventos de integração entre plataformas

### 8.3. Longo prazo

- transformar o ecossistema em plataforma comercial e operacional de ponta a ponta
- usar Automata como camada de aceleração e diferenciação enterprise
- evoluir de integrações pontuais para orquestração real de receita

## 9. Conclusão

O ecossistema IgaraLead já tem estrutura suficiente para ser tratado como plataforma integrada em construção avançada, não apenas como conjunto de produtos independentes.

O centro de gravidade está corretamente no Hub. Entity, Amplex e Nexus já orbitam esse modelo com integrações concretas. O próximo ciclo precisa ser menos sobre adicionar novas peças e mais sobre consolidar contratos, observabilidade, governança e fluidez operacional entre todas elas.

Se essa disciplina for mantida, a IgaraLead deixa de operar apenas softwares conectados e passa a oferecer uma infraestrutura unificada de receita, relacionamento e automação.