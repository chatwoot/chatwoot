# Synapsea Connect — Inspeção real do frontend + plano de refatoração por fases

> Objetivo deste documento: cumprir a **fase obrigatória de inspeção** antes da refatoração visual total, mapear a arquitetura real e definir um plano de implementação seguro sem quebrar backend/fluxos.

---

## 1) Stack real encontrada (sem suposição)

### Frontend principal

- **Vue 3** com roteamento via `vue-router` e store legado/pinia.
- Entrypoint principal do dashboard em `app/javascript/entrypoints/dashboard.js`.
- Router central em `app/javascript/dashboard/routes/index.js`.
- Shell global do app em `app/javascript/dashboard/routes/dashboard/Dashboard.vue`.

### Sistema de estilos/design atual

- Base de tokens em SCSS (`app/javascript/dashboard/assets/scss/_next-colors.scss`).
- Mapeamento de cores de tema em `theme/colors.js`.
- UI kit visual concentrado em `app/javascript/dashboard/components-next/**`.
- Forte uso de classes utilitárias e tokens `n-*` no frontend.

### i18n

- Frontend i18n em `app/javascript/dashboard/i18n/locale/*`.
- Arquivo principal de agregação de locale em `app/javascript/dashboard/i18n/locale/en/index.js`.

---

## 2) Mapeamento estrutural do frontend (arquitetura real)

## 2.1 Layout global / navegação

- Shell: `app/javascript/dashboard/routes/dashboard/Dashboard.vue`
- Sidebar: `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`
- Mobile launcher: `app/javascript/dashboard/components-next/sidebar/MobileSidebarLauncher.vue`
- Help global atual: `app/javascript/dashboard/components-next/sidebar/SidebarHelpCenter.vue`
- Context help flutuante: `app/javascript/dashboard/components-next/ContextHelp.vue`

## 2.2 Rotas e módulos críticos

- Roteamento raiz: `app/javascript/dashboard/routes/index.js`
- Rotas dashboard: `app/javascript/dashboard/routes/dashboard/dashboard.routes.js`
- Conversa: `app/javascript/dashboard/routes/dashboard/conversation/**`
- Inbox: `app/javascript/dashboard/routes/dashboard/inbox/**`
- Contatos: `app/javascript/dashboard/routes/dashboard/contacts/**` e componentes relacionados
- Relatórios: `app/javascript/dashboard/routes/dashboard/settings/reports/**`
- Automações: `app/javascript/dashboard/routes/dashboard/settings/automation/**`
- Captain/IA assistiva (área atual mais próxima de “IA Assistente”): `app/javascript/dashboard/routes/dashboard/captain/**`
- Campanhas (base atual para bloco de comunicação/SDR parcial): `app/javascript/dashboard/routes/dashboard/campaigns/**`
- Empresas: `app/javascript/dashboard/routes/dashboard/companies/**`
- Configurações: `app/javascript/dashboard/routes/dashboard/settings/**`

## 2.3 Componentes compartilhados mais relevantes para refatorar base visual

- Botão: `app/javascript/dashboard/components-next/button/Button.vue`
- Input: `app/javascript/dashboard/components-next/input/Input.vue`
- TextArea: `app/javascript/dashboard/components-next/textarea/TextArea.vue`
- Dropdown: `app/javascript/dashboard/components-next/dropdown-menu/DropdownMenu.vue`
- Dialog/Modal: `app/javascript/dashboard/components-next/dialog/Dialog.vue`
- Avatar/Icon/Card layouts e utilitários em `components-next/**`

---

## 3) Telas críticas e impacto operacional

### Prioridade P0 (núcleo operacional)

1. **Conversa** (lista + chat + painel lateral):
   - `app/javascript/dashboard/routes/dashboard/conversation/ConversationView.vue`
   - `app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue`
   - `app/javascript/dashboard/routes/dashboard/conversation/ConversationAction.vue`
2. **Layout global + Sidebar + Top context**:
   - `app/javascript/dashboard/routes/dashboard/Dashboard.vue`
   - `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`
3. **Inbox listagem operacional**:
   - `app/javascript/dashboard/routes/dashboard/inbox/InboxView.vue`
   - `app/javascript/dashboard/routes/dashboard/inbox/InboxList.vue`

### Prioridade P1 (gestão)

4. **Dashboard/Overview**
5. **Contatos**
6. **Relatórios**
7. **Automações**

### Prioridade P2 (expansão premium)

8. **Supervisor (composição via relatórios/visões operacionais atuais)**
9. **SDR (baseando em campaigns + módulos complementares)**

---

## 4) Restrições técnicas e riscos mapeados

1. A base tem grande cobertura de rotas/módulos; refatoração “big bang” aumenta risco de regressão visual e operacional.
2. Alguns módulos têm UI legacy + `components-next` convivendo; risco de inconsistência se não houver camada de design system padronizada primeiro.
3. A tela de conversa é altamente sensível (tempo real, ações rápidas, painel lateral); qualquer regressão impacta diretamente operação.
4. Parte de “Supervisor/SDR” ainda não está consolidada como módulo único nativo; precisa evolução incremental sem inventar backend novo.

---

## 5) Plano curto de implementação (fases executáveis)

## Fase 1 — Base visual central (Design System Synapsea)

**Objetivo:** consolidar tokens e componentes de fundação.

- Consolidar tokens de cor/tipografia/spacing/shadow/radius em:
  - `app/javascript/dashboard/assets/scss/_next-colors.scss`
  - `theme/colors.js`
- Alinhar componentes base (`Button`, `Input`, `TextArea`, `Dropdown`, `Dialog`) para padrões Synapsea.
- Definir contratos visuais de estado: hover/focus/active/disabled/loading/error/success.

## Fase 2 — Layout global e navegação

**Objetivo:** deixar a aplicação coesa, premium e operacional.

- Refatorar `Dashboard.vue` (estrutura macro + consistência de conteúdo central).
- Refatorar `Sidebar.vue` e `SidebarHelpCenter.vue` para navegação premium e auto treinamento.
- Ajustar topbar/header operacional.

## Fase 3 — Núcleo operacional (P0)

**Objetivo:** maximizar valor na operação diária.

- Refatorar experiência de conversa (layout tri-coluna funcional quando aplicável).
- Refinar Inbox + ContactPanel + ações rápidas (transferir, atribuir, tags, SLA visual).
- Garantir legibilidade, escaneabilidade e velocidade de uso.

## Fase 4 — Módulos de gestão

**Objetivo:** padronizar visão tática e estratégica.

- Dashboard operacional (métricas-chave, alertas, filas, IA em ação).
- Relatórios e automações com consistência de cards, tabelas e filtros.
- Contatos e empresas com padrão visual único.

## Fase 5 — Módulos premium + hardening

**Objetivo:** fechar experiência proprietária Synapsea Connect.

- Supervisor/torre de controle (com base nos módulos existentes).
- SDR/prospecção (sobre módulos existentes sem quebrar backend).
- Revisão final de responsividade, acessibilidade e performance visual.

---

## 6) Arquivos mínimos candidatos para a refatoração (lote inicial)

### Layout / shell

- `app/javascript/dashboard/routes/dashboard/Dashboard.vue`
- `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`
- `app/javascript/dashboard/components-next/sidebar/SidebarHelpCenter.vue`

### Tokens / tema

- `app/javascript/dashboard/assets/scss/_next-colors.scss`
- `theme/colors.js`

### Componentes base

- `app/javascript/dashboard/components-next/button/Button.vue`
- `app/javascript/dashboard/components-next/input/Input.vue`
- `app/javascript/dashboard/components-next/textarea/TextArea.vue`
- `app/javascript/dashboard/components-next/dialog/Dialog.vue`
- `app/javascript/dashboard/components-next/dropdown-menu/DropdownMenu.vue`

### Telas core

- `app/javascript/dashboard/routes/dashboard/conversation/ConversationView.vue`
- `app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue`
- `app/javascript/dashboard/routes/dashboard/conversation/ConversationAction.vue`
- `app/javascript/dashboard/routes/dashboard/inbox/InboxView.vue`
- `app/javascript/dashboard/routes/dashboard/inbox/InboxList.vue`

### Gestão

- `app/javascript/dashboard/routes/dashboard/settings/reports/**`
- `app/javascript/dashboard/routes/dashboard/settings/automation/**`
- `app/javascript/dashboard/routes/dashboard/campaigns/**`

---

## 7) Definição de execução em rodadas (controle de risco)

### Rodada 1 (esta entrega)

- inspeção real da arquitetura
- mapeamento de arquivos críticos
- plano de implementação em fases

### Rodada 2

- design system + layout global (sidebar/topbar/shell)

### Rodada 3

- telas core (conversa/inbox/contatos)

### Rodada 4

- automações/supervisor/relatórios/SDR + hardening final

---

## 8) Próximo passo recomendado (imediato)

Iniciar **Rodada 2** com escopo fechado:

1. tokens finais Synapsea (sem hardcode disperso),
2. refatoração de `Sidebar.vue` + topbar,
3. padronização de `Button/Input/Dialog`.

Depois, validar visual e operacional antes de avançar para conversa (Rodada 3).
