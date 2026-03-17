# Synapsea Connect — Playbook de execução no Codex

Este documento organiza a execução no Codex na ordem correta para reduzir regressões e evitar refactors caóticos.

## Princípios

- Fundação antes de acabamento: **inspeção → base visual → layout → telas críticas → QA**.
- Não alterar backend/endpoints/modelos sem necessidade.
- Entregas por fase, com escopo fechado e validação antes de avançar.
- Sempre pedir ao Codex: **inspecionar arquivos reais**, **apresentar plano curto** e só então implementar.

## Ordem de execução recomendada

1. Inspeção do repositório
2. Design system + tokens
3. Layout global
4. Tela de conversa
5. Torre de controle / supervisor
6. Dashboard executivo
7. Automações / SDR / relatórios
8. Harmonização visual global
9. QA / homologação
10. Congelamento para produção

## Fase 0 — Preparação

- Criar branch dedicada de redesign.
- Garantir que o projeto sobe localmente.
- Rodar build/lint/testes do estado atual.
- Capturar screenshots de baseline.
- Definir branding oficial (nome, logo, favicon, paleta mínima).
- Definir prioridade de telas.

## Fase 1 — Inspeção obrigatória

Objetivo: mapear a estrutura real antes de editar.

Checklist:
- Stack de frontend real.
- Layout global, sidebar, topbar.
- Tela de conversa (lista/chat/composer/painel lateral).
- Dashboard atual (operacional e executivo).
- Componentes compartilhados, i18n e estilos globais.
- Menor conjunto de arquivos para alteração segura.

Critério para avançar:
- Plano claro com caminhos reais de arquivos.
- Sem “chute” de nomes.
- Sem proposta de “reescrever tudo”.

## Fase 2 — Design system + tokens

Objetivo: unificar base visual.

Entregáveis:
- Tokens: cor, tipografia, espaçamento, raio, estados.
- Bases reutilizáveis: botão, input, card, badge, tabs, modal, tabela, empty states.

Critério para avançar:
- Consistência visual e estados completos.
- Sem hardcode espalhado.
- Sem duplicação desnecessária.

## Fase 3 — Layout global

Objetivo: consolidar esqueleto do produto.

Escopo:
- Sidebar, topbar, containers, headers de página, grid principal, responsividade base.

Critério para avançar:
- Navegação íntegra (incluindo permissões).
- Layout estável em 1366px e desktop.
- Sem telas híbridas (metade antiga, metade nova).

## Fase 4 — Tela de conversa (prioridade máxima)

Objetivo: transformar em estação de trabalho operacional.

Rodadas:
- 4.1 inspeção + plano da conversa
- 4.2 lista/header/chat/composer
- 4.3 painel lateral/IA/histórico/refino

Validação mínima:
- abrir/trocar conversa rápido
- responder mensagem
- transferir (agente/setor)
- aplicar tag
- usar sugestão IA e editar antes de enviar
- anexos/notas internas/histórico intactos

## Fase 5 — Torre de controle / Supervisor

Rodadas:
- 5.1 inspeção + plano
- 5.2 métricas, filas, capacidade
- 5.3 alertas, IA, redistribuição, atividade recente

Critério para avançar:
- Gargalos visíveis em segundos.
- Alertas claros sem poluição.

## Fase 6 — Dashboard executivo

Rodadas:
- 6.1 inspeção + plano
- 6.2 KPIs + comercial + operação/SLA
- 6.3 IA/eficiência + riscos + resumo executivo

Critério para avançar:
- Hierarquia executiva clara “acima da dobra”.
- Relação entre operação, comercial e IA evidente.

## Fase 7 — Módulos secundários premium

Ordem recomendada:
1. Automações
2. Relatórios
3. SDR
4. Contatos
5. Configurações

Regra: um módulo por vez (inspeção → plano → implementação → ajuste fino).

## Fase 8 — Harmonização global

Checklist de uniformização:
- espaçamento
- cabeçalhos
- botões
- cards
- tabelas
- estados
- remoção de CSS redundante

## Fase 9 — QA / Homologação

Ordem sugerida:
1. Ambiente/build
2. Branding/navegação
3. Layout global
4. Conversa
5. Filas/transferência
6. Supervisor
7. Dashboard executivo
8. Automações
9. IA
10. Relatórios
11. Permissões
12. Responsividade
13. Tempo real
14. Casos de borda

Bloqueadores para produção:
- login
- conversa
- transferência
- permissões
- supervisor

## Fase 10 — Congelamento de release

- Criar branch de release.
- Documentar alterações finais.
- Registrar riscos de manutenção.
- Capturar screenshots finais.
- Preparar checklist de rollback.
- Criar tag da versão.

## Template de solicitação para cada rodada no Codex

Use este formato:

1. **Inspecione primeiro**
2. **Mostre plano curto**
3. **Implemente só este bloco**
4. **Liste arquivos alterados**
5. **Explique riscos**
6. **Não mexa fora do escopo**

### Frase padrão (cole ao final de toda rodada)

> Não implemente tudo de uma vez.  
> Primeiro inspecione os arquivos reais do repositório relacionados a este módulo.  
> Depois apresente um plano curto.  
> Só então altere os arquivos estritamente necessários.  
> Evite mudanças fora do escopo desta etapa.  
> Ao final, liste exatamente os arquivos alterados e os componentes criados/refatorados.

## Ordem exata dos prompts

1. Refatoração gráfica geral — inspeção + plano
2. Refatoração gráfica geral — design system + layout global
3. Tela de conversa completa
4. Torre de controle / supervisor
5. Dashboard executivo
6. Automações
7. Relatórios
8. SDR
9. Harmonização visual global
10. Correções finais pós-QA

## Sinais de alerta (interromper e revisar)

- Alteração de backend sem necessidade.
- Duplicação de telas em vez de refatoração.
- Criação excessiva de componentes sem reuso.
- Queda de performance na conversa.
- Quebra de permissões/menu.
- Responsividade degradada.

## Regra de passagem entre fases

Só avançar se a fase atual estiver:
- compilando
- navegável
- consistente
- sem regressão grave
- visualmente aprovada

## Resumo executivo do plano

Prioridade prática:
1. Conversa
2. Layout global
3. Supervisor
4. Dashboard executivo
5. Automações / relatórios / SDR

Pergunta-guia em todas as fases:

> O usuário (operador/gestor/diretor) entende, decide e age mais rápido com esta versão?
