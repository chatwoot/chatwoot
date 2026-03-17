# Synapsea Connect — QA Homologation Checklist

Este guia organiza a homologação em 4 filtros obrigatórios:

1. funciona
2. não regrediu
3. está consistente
4. aguenta operação real

## Status padrão por item

- `OK`: validado e funcionando
- `AJUSTE`: funciona, mas precisa melhoria
- `ERRO`: não funciona corretamente
- `N/A`: não se aplica

Severidade sugerida:

- baixa
- média
- alta
- crítica

## Estrutura de registro

Use uma tabela com:

- módulo
- item
- cenário de teste
- resultado esperado
- status
- observação
- severidade

---

## 1) Validação estrutural do layout (logo após entrega)

Objetivo: confirmar que o layout foi aplicado de forma sistêmica, e não apenas por troca de cor/logo.

### Checklist

- logo Synapsea aparece corretamente
- favicon está correto
- tema aplicado globalmente (cores e superfícies)
- sidebar e header consistentes
- botões, cards, modais, formulários e tabelas no mesmo padrão
- estados de loading sem quebra visual
- sem mistura de estilos antigos e novos
- sem componentes duplicados
- sem CSS solto fora do padrão do projeto

### Sinais de risco

- padding inconsistente entre páginas
- tipografia desigual
- componentes “parecendo de produtos diferentes”

---

## 2) Validação de UX operacional

Objetivo: garantir que operador/supervisor conseguem trabalhar rápido.

### Cenário mínimo de operação

1. abrir conversa
2. ver contexto do cliente
3. responder
4. aplicar tag
5. transferir para setor/agente

### Checklist

- informação crítica visível primeiro
- ações principais sem excesso de clique
- contexto do cliente fácil de localizar
- fluxo de transferência claro
- IA assistiva ajuda sem poluir a tela

Regra prática: se o operador não entende a tela em ~2 segundos, precisa ajuste.

---

## 3) Validação visual completa

### Consistência visual

- cores consistentes
- tipografia consistente
- espaçamento/alinhamento consistente

### Estados de componentes

Validar sempre:

- hover
- focus
- active
- disabled
- loading
- error

### Componentes críticos

- botões
- inputs/selects
- dropdowns
- modais
- tabelas
- badges/tags
- tooltips/toasts

---

## 4) Validação de responsividade

Testar no mínimo:

- desktop grande (1920+)
- notebook (1366)
- tablet (~768)
- mobile (quando o layout suportar)

Validar:

- sidebar colapsa corretamente
- tabelas não quebram
- modais não saem da tela
- textos não cortam

---

## 5) Validação de acessibilidade básica

- contraste mínimo aceitável
- foco de teclado visível
- elementos clicáveis com área adequada
- dark/light sem perda de legibilidade

---

## 6) Validação de performance visual

Medir experiência em:

- abertura do dashboard
- troca de conversa
- abertura de modal
- listas grandes

Alertas:

- travamento ao trocar conversa
- flicker de layout
- loading infinito
- atrasos perceptíveis de interação

---

## 7) Consistência entre telas

Comparar visual/UX entre:

- dashboard
- conversa
- contatos
- automações
- relatórios
- configurações

O sistema deve parecer um produto único, não módulos desconectados.

---

## Ordem recomendada de homologação

1. estrutura visual global
2. UX operacional
3. componentes e estados
4. responsividade
5. performance visual
6. consistência entre telas
7. regressão funcional dos fluxos core
8. permissões e segurança por perfil
9. realtime e concorrência

---

## Critério de aceite para layout

Aprovar apenas quando:

- o operador conclui os fluxos essenciais sem ajuda
- o supervisor entende o estado operacional rapidamente
- não há erro visual crítico em telas principais
- o sistema reduz atrito operacional (menos clique, menos busca, menos erro)

## Smoke test final recomendado

Peça para alguém sem contexto do projeto executar:

1. cadastrar contato
2. abrir conversa
3. responder cliente
4. transferir para setor

Se a pessoa conclui sem suporte, a experiência está no caminho certo.
