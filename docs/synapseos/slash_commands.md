# Comandos em notas privadas

Comandos que o atendente escreve **dentro de uma nota privada** (aba
amarela do composer). Disparam ações no backend sem precisar sair da
conversa. Todos idempotentes e seguros — se o comando falha, só registra
warning no log, nunca quebra o envio da nota.

## Referência

| Comando | Efeito | Exemplo |
|---|---|---|
| `/ganhei <valor>` | Cria `Lead` + `Deal :won` + `CrmEvent deal_won`. Move lead pra stage `fechado_ganho`. | `/ganhei 38500` |
| `/perdi <valor>` | Idem acima mas `:lost` + stage `perdido`. Valor opcional. | `/perdi` |
| `/agendar YYYY-MM-DD` | Cria `CrmEvent type=appointment` com `scheduled_for`. Move lead de `qualificado` → `negociacao`. | `/agendar 2026-05-15` |
| `/qualificar` | Aplica label `lead_qualificado` + cria `Lead` se não existe + move pra stage `qualificado`. | `/qualificar` |
| `/stage <slug>` | Move o lead direto pra stage. Slugs default: `novo_lead`, `qualificado`, `negociacao`, `fechado_ganho`, `perdido`. | `/stage negociacao` |
| `/tag <slug>` | Aplica label na conversa. Use slugs do contrato (`outbound`, `resgatado_fernanda`, etc). | `/tag resgatado_fernanda` |

## Como funciona

- Comandos são detectados pelo `SynapseosListener#dispatch_slash_command`.
- Só notas **privadas** (não visíveis ao cliente no WhatsApp) são parseadas — mensagens normais de resposta passam intocadas.
- O comando deve estar no **início** da nota (regex `^/comando`).
- Uma nota pode conter só um comando por vez (o primeiro que bater é executado).

## Boas práticas

- Use `/ganhei` e `/perdi` **depois** que você já confirmou o fechamento pelo telefone/WhatsApp — eles encerram o lead.
- Use `/agendar` com a data do test-drive ou visita — alimenta a métrica "Agendamentos" da Ângela no dashboard.
- Use `/qualificar` como substituto do clique em "aplicar label `lead_qualificado`" — mesmo efeito, menos atrito.
- Use `/tag` pra marcar eventos especiais que não têm atalho próprio (ex: `/tag inadimplencia_contato` quando Vitor começar cobrança).

## Troubleshooting

| Sintoma | Causa provável |
|---|---|
| Comando escrito mas nada acontece | Nota não era privada (enviada como resposta ao cliente) |
| `/ganhei 1200.50` não pega valor | Use vírgula ou ponto, mas só um decimal (`1200,50` ou `1200.50`) |
| `/stage foo` sem efeito | Slug não existe nos stages do pipeline — verificar em Settings → Pipeline |
| `/agendar amanhã` não funciona | Formato fixo `YYYY-MM-DD`, não aceita texto humano ainda |
