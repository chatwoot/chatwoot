# Caça a Bugs/Issues — Sumário Executivo (2026-07-04)

*Apresentação para decisão. Linguagem de negócio. O detalhe técnico está no doc irmão
`caca_bugs_2026-07-04_plano_tecnico.md`.*

---

## O que foi feito

9 pontos levantados pelo Rodrigo foram investigados **causa-raiz** — não palpite. Cinco frentes rodaram
**em paralelo**, cruzando o código real, a infraestrutura AWS (via acesso de leitura) e a **documentação
oficial** de AWS e Meta. Cada achado tem arquivo/linha ou evidência de CLI por trás. Nada foi alterado:
este material existe para **decidir o que atacar e em que ordem**.

---

## Retrato em uma tela

| # | Ponto | Veredito | Impacto no negócio | Recomendação |
|---|-------|----------|--------------------|--------------|
| 8 | Gestão de IA mostra o gasto caro | O "botão" de esconder **existe e funciona** — só nunca foi **ligado** em produção | Relatório de custo poluído | ✅ Ligar config (imediato) |
| 3 | Ativar agente "pede testar antes" | Não é trava — é layout de botão | Fricção na ativação | ✅ Fazer já (rápido) |
| 4 | Etiqueta do funil cortada | CSS de largura fixa | Leitura ruim no dia a dia | ✅ Fazer já (rápido) |
| 6 | Marcar campanha Meta no Kanban | Anúncio-WhatsApp **já traz o dado**; LP→WhatsApp exige convenção de link | Atribuição de venda por anúncio | ✅ Ganho barato (anúncio) |
| 1b | Guia MS/Google na própria tela | 1 tela cobre os 2 (input estreito + guia à direita) | Onboarding de e-mail sem suporte | 🔵 Planejar (médio) |
| 7 | Atributos usados pelas IAs | IA não enxerga os campos preenchidos | Decisão de IA mais pobre | 🔵 Planejar (médio) |
| 5 | Automações com eventos do Kanban | Eventos existem, mas não ligados ao motor de automação | Automação de funil | 🔵 Planejar (médio) |
| 9 | Fluxo "base primeiro" na criação | Viável, com 1 trava técnica + 3 decisões suas | Onboarding do agente | 🔵 Planejar + decidir |
| 1 | E-mail conta 6 não chega | Recebimento não está montado | Canal de e-mail inoperante | 🟠 Operação (não é código) |
| 2 | Domínio Amazon "pendente" | **Nunca foi criado** no SES + conta em modo restrito | Envio de e-mail frágil | 🟠 Operação + infra |

Legenda: ✅ rápido/decidido · 🔵 projeto de código a planejar · 🟠 operação/infra (fora de PR de código).

---

## As 4 surpresas que o conselho precisa saber

1. **O e-mail e o "domínio pendente" são dois problemas separados.** O teste de e-mail que "funcionou"
   testa só o **envio**. A conversa não aparece porque o **recebimento** nunca foi ligado. Verificar o
   domínio **não resolve** o e-mail não chegar — são trilhos diferentes.

2. **A infraestrutura de e-mail da Amazon simplesmente não existe.** Não é "verificação pendente":
   **nenhum domínio nosso foi cadastrado** no serviço da Amazon, a conta está em **modo restrito
   (sandbox)** e um pedido anterior de liberação foi **negado** (com texto de outro cliente). É um
   trabalho de fundação, não um ajuste.

3. **A "regressão" da Gestão de IA é uma config desligada, não um bug.** No dia 30 construímos exatamente
   o que você pediu: um **corte que esconde o gasto do período caro** da tela (append-only, nada é apagado).
   Ele **está no código e é testado** — mas o **interruptor nunca foi ligado em produção** (a variável de
   ambiente nunca foi setada nem salva). Por isso o gasto caro ainda aparece. **Correção: ligar a variável
   nos 2 ambientes + salvá-la no repositório** pra não sumir de novo. Sem reescrever nada.

4. **A atribuição de campanha do Meta: metade é de graça, metade exige convenção.** Vendas que chegam por
   **anúncio click-to-WhatsApp já trazem** os dados da campanha — só estamos jogando fora (ganho barato).
   Mas o caminho **tráfego → landing page → botão WhatsApp** é um clique "orgânico": o Meta **não manda
   nada**. Para atribuir esse, o **marketing precisa embutir um código no link** da LP (convenção). **Google
   não tem por onde entrar** hoje — precisaria de canal novo.

---

## Plano em 3 ondas

**Onda 0 — Imediato (sem código):** ligar a variável que esconde o gasto caro na Gestão de IA (8). Resolve
hoje, sem deploy — só uma configuração de ambiente (com backup antes).

**Onda A — Ganhos rápidos (dias, baixo risco):** ativar agente (3), etiqueta do funil (4), campanha
anúncio→Kanban (6-CTWA), salvar a config do custo no repo (8). Entram juntos num deploy só.

**Onda B — Projetos de código (1–2 semanas):** guia MS/Google na tela (1b), IA enxergar atributos (7),
automação por evento de Kanban (5), campanha LP→WhatsApp (6, após marketing padronizar os links), fluxo
"base primeiro" na criação (9 — **depende de 3 decisões suas**).

**Onda C — Operação/Infra (não é código):** ligar o recebimento de e-mail da conta 6 (1) e montar do zero
os domínios na Amazon + sair do modo restrito (2). Cada passo de DNS/infra pede seu 🟢.

---

## Mockups para aprovar

**Telas desenhadas (visual real do Chat2You):** https://claude.ai/code/artifact/3aab7347-df40-44e9-9163-ceeb8d967bb7
— onboarding e-mail Microsoft e Google (guia passo-a-passo na tela), fluxo "base primeiro" (2 estados +
botão Pular), etiqueta do funil (antes/depois). **Aprove ou peça ajuste antes de eu implementar.**

## Decisões já fechadas nesta rodada

- **E-mail (1):** recebimento por **IMAP (MS/Google/provedor)** — Amazon é só para disparo em massa. ✅
- **SES (2):** montar **do zero em us-east-1**. **Confirmado por pesquisa:** o mesmo domínio pode ser aprovado
  em **mais de uma conta AWS** (autonomia + hub2you) **e** conviver com o **RD Station** do cliente — cada um
  com seus próprios registros, num SPF só mesclado. O risco a vigiar é o limite de 10 consultas do SPF. ✅
- **Custo IA (8):** data-limite **30/jun** confirmada. ✅
- **Base primeiro (9):** vale para **interno e externo**; só quando pediu "com base"; **botão Pular** se desistir. ✅
- **Meta (6):** deixar o modelo **preparado para os dois** (anúncio-WhatsApp automático + campanha de tráfego
  via código no link). **Google fora** por ora. ✅

## Ainda preciso de você

1. **SES:** me passa a credencial da conta AWS da **Autonomia** (para referência real) ou **sigo do zero**?
2. **Onda 0:** autoriza eu **ligar a variável do custo (P8)** nos 2 ambientes agora (com backup antes)?
3. **Campanha de tráfego (6):** confirma que o **marketing vai padronizar os links** da landing page com o
   código de campanha? (sem isso, só o anúncio-WhatsApp é automático).
4. **Mockups:** aprova as 4 telas como estão, ou ajusto alguma?

---

## O que já foi entregue nesta sessão (contexto)

- **PR #119** — confirmação + aviso ao apagar material da base (a "lixeira que parecia não fazer nada").
- **PR #118 (no ar)** — conhecimento geral liberado, "não sei" honesto, chunking de FAQ, sem travessão.

*Próximo passo: sua aprovação deste plano → abrimos as issues e atacamos a Onda A.*
