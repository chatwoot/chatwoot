# Stacks de validação para homologação (base sólida)

Este plano organiza a validação do sistema em **stacks independentes e sequenciais**, cobrindo:

1. funcionalidades já existentes (legado),
2. integrações existentes,
3. entregas novas do pacote Synapsea.

A proposta reduz risco de regressão e permite bloquear homologação quando um stack crítico falhar.

---

## Regras globais de homologação

- **Não avançar de stack** se houver falha crítica/alta no stack atual.
- Toda execução deve registrar:
  - ambiente,
  - build/commit,
  - evidências (prints/logs),
  - resultado por cenário.
- **Sem “teste exploratório solto”**: usar checklist com status (`OK`, `AJUSTE`, `ERRO`).
- Prioridade: 
  1. segurança e permissão,
  2. operação de atendimento,
  3. tempo real,
  4. IA/analytics,
  5. acabamento visual.

---

## Escala de severidade

- **Crítica (P0):** impede operação principal (login, abrir conversa, responder, transferir, permissão indevida).
- **Alta (P1):** afeta fluxo essencial com workaround ruim.
- **Média (P2):** impacto moderado, com workaround aceitável.
- **Baixa (P3):** visual/cópia sem impacto funcional.

---

## Critério de saída para homologação

Somente liberar para homologação ampliada quando:

- nenhum erro **P0/P1** aberto nos stacks 1 a 6,
- taxa de sucesso mínima de **95%** dos cenários críticos,
- sem erro JS crítico em console nas telas principais,
- sem regressão de permissão por perfil,
- atualização em tempo real estável nos fluxos de conversa/transferência.

---

## Stack 0 — Base técnica e observabilidade

### Objetivo
Garantir que o ambiente está íntegro antes de validar produto.

### Cobertura
- Subida de serviços (app, workers, DB, cache, realtime, analytics scaffold quando aplicável).
- Logs de app/backend sem erros fatais no boot.
- Assets e bundles sem quebra.
- Healthchecks de serviços.

### Cenários mínimos
- App sobe sem crash.
- Login carrega sem erro de bundle.
- Background jobs processam fila simples.
- Canal realtime conecta e reconecta.

### Bloqueadores
- Falha de boot, migração pendente, erro fatal de asset, timeout contínuo.

---

## Stack 1 — Legado core (sem features novas)

### Objetivo
Provar que os fluxos clássicos continuam íntegros.

### Cobertura
- Login/logout/reset.
- Inbox/conversas (listar, abrir, responder, resolver/reabrir).
- Contatos (criar, editar, buscar, histórico).
- Notas internas e tags.

### Cenários mínimos
- Operador responde conversa ponta a ponta.
- Nota interna não vaza para cliente.
- Busca de contato retorna registros corretos.
- Resolver/reabrir mantém estado consistente.

### Bloqueadores
- Regressão funcional em conversa, contato, nota ou status.

---

## Stack 2 — Integrações existentes (pré-Synapsea)

### Objetivo
Validar integrações que já existiam e não podem regredir.

### Cobertura
- Canais de entrada ativos no projeto (ex.: web widget, APIs, conectores habilitados no ambiente).
- Webhooks/eventos já usados na operação.
- Integrações de CRM/help center/campos customizados já em produção (quando habilitadas).

### Cenários mínimos
- Nova mensagem entra pelo canal e cria/atualiza conversa.
- Eventos esperados são emitidos e recebidos.
- Falha de integração não derruba UI (fallback visível).

### Bloqueadores
- Mensagem não ingressa na fila correta.
- Quebra de contrato de payload já usado.

---

## Stack 3 — Filas, transferência e roteamento operacional

### Objetivo
Validar operação tática de atendimento.

### Cobertura
- Atribuição manual.
- Transferência agente ↔ agente.
- Transferência agente ↔ fila/setor.
- Reenfileiramento e histórico de movimentação.

### Cenários mínimos
- Transferência registra trilha/histórico.
- Destino recebe conversa corretamente.
- Origem deixa de exibir atribuição antiga.
- Conflito de ação simultânea não duplica estado.

### Bloqueadores
- Conversa “sumir” entre origem/destino.
- Estado de atribuição inconsistente.

---

## Stack 4 — Supervisor e operação em tempo real

### Objetivo
Garantir leitura operacional e reação rápida.

### Cobertura
- Visão supervisor (cards e filas).
- Alertas operacionais (SLA/risco/capacidade).
- Redistribuição manual.
- Atualização em tempo real sem refresh.

### Cenários mínimos
- Mudança de status atualiza dashboard supervisor em tempo aceitável.
- Alerta surge e desaparece conforme condição.
- Redistribuição reflete em todas as visões.

### Bloqueadores
- Painel congelado, números incoerentes ou atualização tardia crítica.

---

## Stack 5 — Automações

### Objetivo
Validar previsibilidade e segurança operacional das regras.

### Cobertura
- CRUD de automações.
- Gatilhos e condições (AND/OR, tags, fila, prioridade quando disponível).
- Ações (tag, nota, transferir, atribuir, mensagem).
- Logs de execução/erro.

### Cenários mínimos
- Regra dispara no gatilho correto.
- Não entra em loop.
- Prioridade entre regras respeitada.
- Logs mostram conversa afetada e status.

### Bloqueadores
- Loop de automação.
- Ação indevida em massa sem controle.

---

## Stack 6 — Features novas Synapsea (UI + operação)

### Objetivo
Validar estritamente o pacote novo sem mascarar problemas com legado.

### Cobertura
- Branding/tokenização aplicada com consistência.
- Ajuda contextual por rota.
- Painéis de inteligência de contato e copilot.
- Cartão/visão de analytics adicionados.

### Cenários mínimos
- Novos componentes renderizam sem quebrar telas existentes.
- Conteúdo contextual condiz com fluxo real.
- IA assistiva não bloqueia operação quando falha.
- Layout mantém hierarquia visual e não polui ação principal.

### Bloqueadores
- UI nova impedir resposta/transferência.
- Conteúdo enganoso que induza erro operacional.

---

## Stack 7 — Permissões e segurança por perfil

### Objetivo
Evitar exposição de dados e ações indevidas.

### Cobertura
- Operador, supervisor, admin e perfis setoriais.
- Proteção por rota e endpoint.
- Ações críticas com validação de escopo.

### Cenários mínimos
- Perfil sem acesso recebe bloqueio em backend (não só ocultação de botão).
- Perfil supervisor acessa operação sem privilégios administrativos indevidos.

### Bloqueadores
- Escalada de privilégio.
- Exposição de dado sensível entre setores.

---

## Stack 8 — Relatórios, IA analítica e consistência de números

### Objetivo
Validar confiança dos dados para decisão.

### Cobertura
- Relatórios fixos e filtros combinados.
- Coerência entre volumes operacionais e relatórios.
- Perguntas em linguagem natural (quando habilitado).

### Cenários mínimos
- Totais de conversas/SLA batem com base operacional.
- Filtros por período/fila/agente/canal funcionam em conjunto.
- Falha analítica mostra erro tratável sem quebrar tela.

### Bloqueadores
- Números incoerentes sem rastreabilidade.
- Insight com dado claramente inválido.

---

## Stack 9 — Performance visual, responsividade e acessibilidade

### Objetivo
Garantir usabilidade real de produção.

### Cobertura
- Resoluções: 1920, 1366, 768, e mobile quando aplicável.
- Estados visuais: hover/focus/disabled/loading/error.
- Acessibilidade básica (contraste, foco teclado, legibilidade).
- Performance percebida (troca de conversa, modal, listas grandes).

### Cenários mínimos
- Sem overflow crítico em modal/tabela.
- Sem “flicker” excessivo em navegação central.
- Foco visível e navegação por teclado funcional nos fluxos críticos.

### Bloqueadores
- Layout quebrado em resolução operacional padrão.
- Lentidão severa em ação essencial (responder/transferir).

---

## Ordem obrigatória de execução

1. Stack 0 (base técnica)
2. Stack 1 (legado core)
3. Stack 2 (integrações existentes)
4. Stack 3 (filas/transferência)
5. Stack 4 (supervisor/realtime)
6. Stack 5 (automações)
7. Stack 6 (novas features Synapsea)
8. Stack 7 (permissões)
9. Stack 8 (analytics/IA)
10. Stack 9 (qualidade visual/performance)

---

## Template de evidência por stack

Use uma tabela por stack:

| Stack | Módulo | Cenário | Esperado | Resultado | Severidade | Evidência |
|------|--------|---------|----------|-----------|------------|-----------|
| 3 | Transferência | Agente A → Fila Financeiro | Conversa aparece no destino e histórico salvo | OK | - | link print/log |
| 5 | Automações | Gatilho mensagem recebida + tag | Tag aplicada uma única vez | AJUSTE | P2 | link print/log |
| 7 | Permissões | Operador acessa rota admin por URL | Bloqueado 403 | ERRO | P0 | link print/log |

---

## Gate final (go/no-go)

- **GO para homologação:** nenhum P0/P1 nos stacks 1–7 e dados confiáveis no stack 8.
- **GO restrito (homologação ampliada):** apenas P2/P3 sem impacto em operação.
- **NO-GO:** qualquer falha em login, conversa, transferência, permissão, automação core ou atualização em tempo real.
