# Integração Viari ↔ Chatwoot — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrar o sistema Viari (turismo) ao Chatwoot para sincronização automática de clientes, painel lateral com reservas/orçamentos/pagamentos e modal de criação de orçamento com texto WhatsApp automático.

**Architecture:** Plugin nativo seguindo o padrão da integração Shopify. O Chatwoot Rails atua como proxy entre o frontend Vue e a API REST do Viari — a API key nunca vai ao browser. A integração é configurável: URL do Viari e API key ficam armazenados no `Integrations::Hook` e podem ser alterados a qualquer momento pela página de configurações.

**Tech Stack:** Next.js 15 (App Router) + Prisma (Viari), Ruby on Rails + Vue 3 Composition API + Tailwind (Chatwoot)

**Spec:** `docs/superpowers/specs/2026-06-08-viari-chatwoot-integration-design.md`

---

## FASE A — API REST no Viari (Next.js)

---

### Task 1: Campo `apiKey` no Tenant + geração/exibição

**Files:**
- Modify: `/Users/alexandre/Code/viari/prisma/schema.prisma`
- Modify: `/Users/alexandre/Code/viari/src/app/actions/configuracoes.ts`
- Create: `/Users/alexandre/Code/viari/src/app/api/viari/gerar-api-key/route.ts`

- [ ] **Step 1: Adicionar `apiKey` ao model `Tenant` no schema Prisma**

Em `/Users/alexandre/Code/viari/prisma/schema.prisma`, localizar o model `Tenant` e adicionar o campo:

```prisma
model Tenant {
  // ... campos existentes ...
  apiKey    String?  @unique @map("api_key")
  // ...
}
```

- [ ] **Step 2: Criar e aplicar a migration**

```bash
cd /Users/alexandre/Code/viari
npx prisma migrate dev --name add_api_key_to_tenant
```

Saída esperada: `✔ Generated Prisma Client`

- [ ] **Step 3: Criar route para gerar/regenerar a API key**

Criar `/Users/alexandre/Code/viari/src/app/api/viari/gerar-api-key/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth/auth-options'
import { prisma } from '@/lib/prisma'
import { randomBytes } from 'crypto'

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions)
  if (!session?.user?.tenantId) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const apiKey = `viari_${randomBytes(32).toString('hex')}`

  await prisma.tenant.update({
    where: { id: session.user.tenantId },
    data: { apiKey },
  })

  return NextResponse.json({ apiKey })
}
```

- [ ] **Step 4: Commit**

```bash
git add prisma/schema.prisma prisma/migrations src/app/api/viari/gerar-api-key/route.ts
git commit -m "feat(viari-api): add apiKey to Tenant + key generation endpoint"
```

---

### Task 2: Middleware de autenticação da API Viari

**Files:**
- Create: `/Users/alexandre/Code/viari/src/lib/auth/viari-api-key.ts`

- [ ] **Step 1: Criar helper `requireViariApiKey`**

Criar `/Users/alexandre/Code/viari/src/lib/auth/viari-api-key.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export type ViariApiContext = {
  tenantId: string
}

export async function requireViariApiKey(
  req: NextRequest
): Promise<ViariApiContext | NextResponse> {
  const apiKey = req.headers.get('x-viari-api-key')

  if (!apiKey) {
    return NextResponse.json({ error: 'API key required' }, { status: 401 })
  }

  const tenant = await prisma.tenant.findUnique({
    where: { apiKey },
    select: { id: true, status: true },
  })

  if (!tenant || tenant.status === 'cancelado' || tenant.status === 'suspenso') {
    return NextResponse.json({ error: 'Invalid API key' }, { status: 401 })
  }

  return { tenantId: tenant.id }
}

export function isErrorResponse(
  result: ViariApiContext | NextResponse
): result is NextResponse {
  return result instanceof NextResponse
}
```

- [ ] **Step 2: Commit**

```bash
git add src/lib/auth/viari-api-key.ts
git commit -m "feat(viari-api): add API key authentication helper"
```

---

### Task 3: Endpoints de cliente (buscar e criar)

**Files:**
- Create: `/Users/alexandre/Code/viari/src/app/api/viari/clientes/buscar/route.ts`
- Create: `/Users/alexandre/Code/viari/src/app/api/viari/clientes/route.ts`

- [ ] **Step 1: Endpoint de busca de cliente por telefone/email**

Criar `/Users/alexandre/Code/viari/src/app/api/viari/clientes/buscar/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { requireViariApiKey, isErrorResponse } from '@/lib/auth/viari-api-key'
import { prisma } from '@/lib/prisma'
import { calcularStatusJornada } from '@/lib/services/viari-jornada'

export async function GET(req: NextRequest) {
  const ctx = await requireViariApiKey(req)
  if (isErrorResponse(ctx)) return ctx

  const { searchParams } = new URL(req.url)
  const telefone = searchParams.get('telefone')
  const email = searchParams.get('email')

  if (!telefone && !email) {
    return NextResponse.json({ error: 'telefone ou email obrigatório' }, { status: 400 })
  }

  const conditions = []
  if (telefone) conditions.push({ telefone })
  if (email) conditions.push({ email })

  const cliente = await prisma.cliente.findFirst({
    where: {
      tenantId: ctx.tenantId,
      OR: conditions,
    },
    select: {
      id: true, nome: true, telefone: true, email: true,
      hotelHospedado: true, dataChegada: true, dataPartida: true,
    },
  })

  if (!cliente) {
    return NextResponse.json({ encontrado: false })
  }

  const statusJornada = await calcularStatusJornada(ctx.tenantId, cliente.id)

  return NextResponse.json({
    encontrado: true,
    cliente: { ...cliente, statusJornada },
  })
}
```

- [ ] **Step 2: Criar arquivo de serviço para calcular status da jornada**

Criar `/Users/alexandre/Code/viari/src/lib/services/viari-jornada.ts`:

```typescript
import { prisma } from '@/lib/prisma'

export type StatusJornada =
  | 'contato'
  | 'orcamento'
  | 'sinal'
  | 'reserva'
  | 'pago'
  | 'embarque'

export async function calcularStatusJornada(
  tenantId: string,
  clienteId: string
): Promise<StatusJornada> {
  const [orcamentos, reservas] = await Promise.all([
    prisma.orcamento.findMany({
      where: { tenantId, clienteId },
      select: { status: true },
      orderBy: { criadoEm: 'desc' },
      take: 5,
    }),
    prisma.reserva.findMany({
      where: {
        tenantId,
        clienteId,
        status: { notIn: ['cancelada', 'noshow'] },
      },
      select: { status: true, agenda: { select: { dataAgenda: true } } },
      orderBy: { criadoEm: 'desc' },
      take: 5,
    }),
  ])

  if (reservas.length > 0) {
    const hoje = new Date()
    const temEmbarque = reservas.some(
      (r) => r.agenda.dataAgenda <= hoje && r.status === 'checkin'
    )
    if (temEmbarque) return 'embarque'

    const temConfirmada = reservas.some((r) => r.status === 'confirmada')
    if (temConfirmada) return 'reserva'
  }

  if (orcamentos.length > 0) {
    const aprovado = orcamentos.find((o) => o.status === 'aprovado')
    if (aprovado) return 'sinal'

    const ativo = orcamentos.find((o) =>
      ['rascunho', 'enviado', 'visualizado'].includes(o.status)
    )
    if (ativo) return 'orcamento'
  }

  return 'contato'
}
```

- [ ] **Step 3: Endpoint de criação de cliente**

Criar `/Users/alexandre/Code/viari/src/app/api/viari/clientes/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { requireViariApiKey, isErrorResponse } from '@/lib/auth/viari-api-key'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const ctx = await requireViariApiKey(req)
  if (isErrorResponse(ctx)) return ctx

  const body = await req.json()
  const { nome, telefone, email } = body

  if (!nome) {
    return NextResponse.json({ error: 'nome obrigatório' }, { status: 400 })
  }

  const cliente = await prisma.cliente.create({
    data: {
      tenantId: ctx.tenantId,
      nome,
      telefone: telefone ?? null,
      email: email ?? null,
    },
    select: {
      id: true, nome: true, telefone: true, email: true,
      hotelHospedado: true, dataChegada: true, dataPartida: true,
    },
  })

  return NextResponse.json({
    encontrado: false,
    cliente: { ...cliente, statusJornada: 'contato' },
  }, { status: 201 })
}
```

- [ ] **Step 4: Commit**

```bash
git add src/app/api/viari/clientes/ src/lib/services/viari-jornada.ts
git commit -m "feat(viari-api): add client search/create endpoints + jornada service"
```

---

### Task 4: Endpoints de dados do cliente (reservas, orçamentos, pagamentos)

**Files:**
- Create: `/Users/alexandre/Code/viari/src/app/api/viari/clientes/[id]/reservas/route.ts`
- Create: `/Users/alexandre/Code/viari/src/app/api/viari/clientes/[id]/orcamentos/route.ts`
- Create: `/Users/alexandre/Code/viari/src/app/api/viari/clientes/[id]/pagamentos/route.ts`

- [ ] **Step 1: Endpoint de reservas do cliente**

Criar `/Users/alexandre/Code/viari/src/app/api/viari/clientes/[id]/reservas/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { requireViariApiKey, isErrorResponse } from '@/lib/auth/viari-api-key'
import { prisma } from '@/lib/prisma'

const VIARI_URL = process.env.NEXTAUTH_URL ?? ''

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const ctx = await requireViariApiKey(req)
  if (isErrorResponse(ctx)) return ctx

  const { id: clienteId } = await params

  const reservas = await prisma.reserva.findMany({
    where: { tenantId: ctx.tenantId, clienteId },
    orderBy: { criadoEm: 'desc' },
    take: 20,
    select: {
      id: true,
      codigo: true,
      status: true,
      qtdAdt: true, qtdChd: true, qtdInf: true, qtdSen: true, qtdFree: true,
      valorTotal: true,
      agenda: {
        select: {
          dataAgenda: true,
          horarioInicio: true,
          produto: { select: { nome: true } },
        },
      },
    },
  })

  return NextResponse.json({
    reservas: reservas.map((r) => ({
      id: r.id,
      codigo: r.codigo,
      produto: r.agenda.produto.nome,
      dataAgenda: r.agenda.dataAgenda,
      horario: r.agenda.horarioInicio,
      pax: { adt: r.qtdAdt, chd: r.qtdChd, inf: r.qtdInf, sen: r.qtdSen, free: r.qtdFree },
      status: r.status,
      valorTotal: r.valorTotal,
      urlViari: `${VIARI_URL}/reservas/${r.id}`,
    })),
  })
}
```

- [ ] **Step 2: Endpoint de orçamentos do cliente**

Criar `/Users/alexandre/Code/viari/src/app/api/viari/clientes/[id]/orcamentos/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { requireViariApiKey, isErrorResponse } from '@/lib/auth/viari-api-key'
import { prisma } from '@/lib/prisma'

const VIARI_URL = process.env.NEXTAUTH_URL ?? ''

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const ctx = await requireViariApiKey(req)
  if (isErrorResponse(ctx)) return ctx

  const { id: clienteId } = await params

  const orcamentos = await prisma.orcamento.findMany({
    where: { tenantId: ctx.tenantId, clienteId },
    orderBy: { criadoEm: 'desc' },
    take: 20,
    select: {
      id: true, codigo: true, status: true,
      totalCartao: true, totalPix: true, dataValidade: true,
      _count: { select: { itens: true } },
    },
  })

  return NextResponse.json({
    orcamentos: orcamentos.map((o) => ({
      id: o.id,
      codigo: o.codigo,
      status: o.status,
      totalCartao: o.totalCartao,
      totalPix: o.totalPix,
      dataValidade: o.dataValidade,
      itens: o._count.itens,
      urlViari: `${VIARI_URL}/orcamentos/${o.id}`,
    })),
  })
}
```

- [ ] **Step 3: Endpoint de pagamentos do cliente**

Criar `/Users/alexandre/Code/viari/src/app/api/viari/clientes/[id]/pagamentos/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { requireViariApiKey, isErrorResponse } from '@/lib/auth/viari-api-key'
import { prisma } from '@/lib/prisma'

const VIARI_URL = process.env.NEXTAUTH_URL ?? ''

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const ctx = await requireViariApiKey(req)
  if (isErrorResponse(ctx)) return ctx

  const { id: clienteId } = await params

  const pagamentos = await prisma.pagamento.findMany({
    where: {
      tenantId: ctx.tenantId,
      reserva: { clienteId },
    },
    orderBy: { criadoEm: 'desc' },
    take: 20,
    select: {
      id: true,
      valor: true,
      formaPagamento: true,
      status: true,
      criadoEm: true,
      reserva: { select: { codigo: true } },
    },
  })

  return NextResponse.json({
    pagamentos: pagamentos.map((p) => ({
      id: p.id,
      valor: p.valor,
      formaPagamento: p.formaPagamento,
      status: p.status,
      data: p.criadoEm,
      reservaCodigo: p.reserva.codigo,
      urlViari: `${VIARI_URL}/financeiro/pagamentos/${p.id}`,
    })),
  })
}
```

- [ ] **Step 4: Commit**

```bash
git add src/app/api/viari/clientes/
git commit -m "feat(viari-api): add customer data endpoints (reservas, orcamentos, pagamentos)"
```

---

### Task 5: Endpoints de produtos, agendas, tarifas e canais de venda

**Files:**
- Create: `/Users/alexandre/Code/viari/src/app/api/viari/produtos/route.ts`
- Create: `/Users/alexandre/Code/viari/src/app/api/viari/agendas/route.ts`
- Create: `/Users/alexandre/Code/viari/src/app/api/viari/tarifas/vigentes/route.ts`
- Create: `/Users/alexandre/Code/viari/src/app/api/viari/canais-venda/route.ts`

- [ ] **Step 1: Endpoint de produtos ativos**

Criar `/Users/alexandre/Code/viari/src/app/api/viari/produtos/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { requireViariApiKey, isErrorResponse } from '@/lib/auth/viari-api-key'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  const ctx = await requireViariApiKey(req)
  if (isErrorResponse(ctx)) return ctx

  const produtos = await prisma.produto.findMany({
    where: { tenantId: ctx.tenantId, ativo: true },
    select: { id: true, nome: true, tipo: true },
    orderBy: { nome: 'asc' },
  })

  return NextResponse.json({ produtos })
}
```

- [ ] **Step 2: Endpoint de agendas disponíveis**

Criar `/Users/alexandre/Code/viari/src/app/api/viari/agendas/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { requireViariApiKey, isErrorResponse } from '@/lib/auth/viari-api-key'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  const ctx = await requireViariApiKey(req)
  if (isErrorResponse(ctx)) return ctx

  const { searchParams } = new URL(req.url)
  const produtoId = searchParams.get('produtoId')
  const dataInicio = searchParams.get('dataInicio')
  const dataFim = searchParams.get('dataFim')

  if (!produtoId || !dataInicio || !dataFim) {
    return NextResponse.json(
      { error: 'produtoId, dataInicio e dataFim são obrigatórios' },
      { status: 400 }
    )
  }

  const agendas = await prisma.agenda.findMany({
    where: {
      tenantId: ctx.tenantId,
      produtoId,
      situacao: { in: ['aberto'] },
      dataAgenda: {
        gte: new Date(dataInicio),
        lte: new Date(dataFim),
      },
    },
    select: {
      id: true,
      dataAgenda: true,
      horarioInicio: true,
      vagasTotal: true,
      vagasOcupadas: true,
    },
    orderBy: [{ dataAgenda: 'asc' }, { horarioInicio: 'asc' }],
  })

  return NextResponse.json({
    agendas: agendas.map((a) => ({
      id: a.id,
      dataAgenda: a.dataAgenda,
      horario: a.horarioInicio,
      vagasDisponiveis: a.vagasTotal - a.vagasOcupadas,
    })),
  })
}
```

- [ ] **Step 3: Endpoint de tarifas vigentes**

Criar `/Users/alexandre/Code/viari/src/app/api/viari/tarifas/vigentes/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { requireViariApiKey, isErrorResponse } from '@/lib/auth/viari-api-key'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  const ctx = await requireViariApiKey(req)
  if (isErrorResponse(ctx)) return ctx

  const { searchParams } = new URL(req.url)
  const produtoId = searchParams.get('produtoId')
  const data = searchParams.get('data')

  if (!produtoId || !data) {
    return NextResponse.json(
      { error: 'produtoId e data são obrigatórios' },
      { status: 400 }
    )
  }

  const dataRef = new Date(data)

  const tarifas = await prisma.tarifaVenda.findMany({
    where: {
      item: { produto: { id: produtoId, tenantId: ctx.tenantId } },
      vigenciaInicio: { lte: dataRef },
      vigenciaFim: { gte: dataRef },
    },
    select: {
      tipoPax: true,
      valorVenda: true,
      item: { select: { id: true, nome: true } },
      grupoTarifa: { select: { id: true, nome: true } },
    },
  })

  // Agrupa por item: { itemId, itemNome, precos: { ADT: X, CHD: Y, ... } }
  const agrupado: Record<string, { itemId: string; itemNome: string; precos: Record<string, number> }> = {}

  for (const t of tarifas) {
    const key = t.item.id
    if (!agrupado[key]) {
      agrupado[key] = { itemId: t.item.id, itemNome: t.item.nome, precos: {} }
    }
    agrupado[key].precos[t.tipoPax] = Number(t.valorVenda)
  }

  return NextResponse.json({ itens: Object.values(agrupado) })
}
```

- [ ] **Step 4: Endpoint de canais de venda**

Criar `/Users/alexandre/Code/viari/src/app/api/viari/canais-venda/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { requireViariApiKey, isErrorResponse } from '@/lib/auth/viari-api-key'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  const ctx = await requireViariApiKey(req)
  if (isErrorResponse(ctx)) return ctx

  const canais = await prisma.canalVenda.findMany({
    where: { tenantId: ctx.tenantId, ativo: true },
    select: { id: true, nome: true, grupoTarifaId: true },
    orderBy: { nome: 'asc' },
  })

  return NextResponse.json({ canais })
}
```

- [ ] **Step 5: Commit**

```bash
git add src/app/api/viari/produtos/ src/app/api/viari/agendas/ src/app/api/viari/tarifas/ src/app/api/viari/canais-venda/
git commit -m "feat(viari-api): add products, agendas, tarifas and sales channels endpoints"
```

---

### Task 6: Endpoint de criação de orçamento + texto WhatsApp

**Files:**
- Create: `/Users/alexandre/Code/viari/src/app/api/viari/orcamentos/route.ts`
- Create: `/Users/alexandre/Code/viari/src/app/api/viari/orcamentos/[id]/texto-whatsapp/route.ts`
- Create: `/Users/alexandre/Code/viari/src/lib/services/viari-texto-whatsapp.ts`

- [ ] **Step 1: Serviço de geração do texto WhatsApp**

Criar `/Users/alexandre/Code/viari/src/lib/services/viari-texto-whatsapp.ts`:

```typescript
import { prisma } from '@/lib/prisma'

const fmt = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' })

export async function gerarTextoWhatsapp(orcamentoId: string, tenantId: string): Promise<string> {
  const orc = await prisma.orcamento.findFirst({
    where: { id: orcamentoId, tenantId },
    include: {
      cliente: { select: { nome: true, telefone: true } },
      itens: {
        include: {
          produto: { select: { nome: true } },
          detalhes: { select: { itemNome: true, tipoPax: true, valorUnitVenda: true, quantidade: true } },
        },
        orderBy: { criadoEm: 'asc' },
      },
    },
  })

  if (!orc) throw new Error('Orçamento não encontrado')

  const linhasItens: string[] = []
  let contador = 1

  for (const item of orc.itens) {
    for (const detalhe of item.detalhes) {
      if (detalhe.quantidade > 0) {
        linhasItens.push(
          `${contador}° - ${item.produto.nome} ${detalhe.tipoPax} | ${fmt.format(Number(detalhe.valorUnitVenda))} | Pax: ${detalhe.quantidade}`
        )
        contador++
      }
    }
  }

  const totalCartao = Number(orc.totalCartao)
  const totalPix = Number(orc.totalPix)
  const sinalPix = Math.round(totalPix * (Number(orc.percentualSinal) / 100) * 100) / 100
  const restanteCartao = totalCartao - sinalPix
  const restantePix = totalPix - sinalPix

  return [
    `🏠 Orçamento dos passeios:`,
    `Nome: ${orc.cliente.nome}`,
    `📞 Telefone: ${orc.cliente.telefone ?? ''}`,
    ``,
    linhasItens.join('\n'),
    ``,
    `💳 Cartão em até 6x s/ juros`,
    `Preço Total no Cartão: ${fmt.format(totalCartao)}`,
    `Sinal para reserva de vagas (PIX): ${fmt.format(sinalPix)}`,
    `Valor a acertar no dia do 1° passeio: ${fmt.format(restanteCartao)}`,
    ``,
    `✅ PIX`,
    `Preço Total no Pix: ${fmt.format(totalPix)}`,
    `Sinal para reserva de vagas (PIX): ${fmt.format(sinalPix)}`,
    `Valor a acertar no dia do 1° passeio: ${fmt.format(restantePix)}`,
  ].join('\n')
}
```

- [ ] **Step 2: Endpoint de criação de orçamento via API**

Criar `/Users/alexandre/Code/viari/src/app/api/viari/orcamentos/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { requireViariApiKey, isErrorResponse } from '@/lib/auth/viari-api-key'
import { prisma } from '@/lib/prisma'
import { gerarCodigoOrcamento } from '@/lib/utils/orcamento'
import { buscarTarifaVigente } from '@/lib/queries/tarifas'
import { gerarTextoWhatsapp } from '@/lib/services/viari-texto-whatsapp'

const VIARI_URL = process.env.NEXTAUTH_URL ?? ''

export async function POST(req: NextRequest) {
  const ctx = await requireViariApiKey(req)
  if (isErrorResponse(ctx)) return ctx

  const body = await req.json()
  const {
    clienteId, canalVendaId, periodoInicio, periodoFim,
    dataValidade, percentualSinal = 35, descontoManual = 0,
    obsInternas, msgCliente, itens = [],
  } = body

  if (!clienteId || !periodoInicio || !periodoFim || !dataValidade || itens.length === 0) {
    return NextResponse.json({ error: 'Campos obrigatórios ausentes' }, { status: 400 })
  }

  const cliente = await prisma.cliente.findFirst({
    where: { id: clienteId, tenantId: ctx.tenantId },
  })
  if (!cliente) {
    return NextResponse.json({ error: 'Cliente não encontrado' }, { status: 404 })
  }

  const codigo = await gerarCodigoOrcamento(ctx.tenantId)

  // Calcular totais com base nas tarifas vigentes
  let totalBruto = 0
  const itensComValores = await Promise.all(
    itens.map(async (item: any) => {
      const agenda = await prisma.agenda.findFirst({
        where: { id: item.agendaId, tenantId: ctx.tenantId },
        include: { produto: { include: { itens: true } } },
      })
      if (!agenda) throw new Error(`Agenda ${item.agendaId} não encontrada`)

      const detalhes = []
      const paxMap: Record<string, number> = {
        ADT: item.qtdAdt, CHD: item.qtdChd, INF: item.qtdInf,
        SEN: item.qtdSen, FREE: item.qtdFree,
      }

      for (const itemProd of agenda.produto.itens) {
        for (const [tipoPax, qtd] of Object.entries(paxMap)) {
          if (qtd > 0) {
            const tarifa = await buscarTarifaVigente({
              itemProdutoId: itemProd.id,
              tipoPax,
              data: new Date(agenda.dataAgenda),
              canalVendaId,
            })
            const valorUnit = tarifa?.valorVenda ?? 0
            const subtotal = Number(valorUnit) * qtd
            totalBruto += subtotal
            detalhes.push({
              itemProdutoId: itemProd.id,
              itemNome: itemProd.nome,
              tipoPax,
              quantidade: qtd,
              valorUnitVenda: valorUnit,
              valorUnitNet: tarifa?.valorNet ?? 0,
              subtotal,
            })
          }
        }
      }

      return {
        produtoId: agenda.produtoId,
        agendaId: item.agendaId,
        qtdAdt: item.qtdAdt, qtdChd: item.qtdChd, qtdInf: item.qtdInf,
        qtdSen: item.qtdSen, qtdFree: item.qtdFree,
        subtotal: detalhes.reduce((s, d) => s + d.subtotal, 0),
        detalhes: { create: detalhes },
      }
    })
  )

  const desconto = Number(descontoManual)
  const totalCartao = totalBruto
  const totalPix = totalCartao - desconto

  const orcamento = await prisma.orcamento.create({
    data: {
      tenantId: ctx.tenantId,
      clienteId,
      canalVendaId: canalVendaId ?? null,
      codigo,
      status: 'rascunho',
      periodoInicio: new Date(periodoInicio),
      periodoFim: new Date(periodoFim),
      dataValidade: new Date(dataValidade),
      percentualSinal,
      descontoManual: desconto,
      totalBruto,
      totalCartao,
      totalPix,
      obsInternas: obsInternas ?? null,
      msgCliente: msgCliente ?? null,
      itens: { create: itensComValores },
    },
  })

  const textoWhatsapp = await gerarTextoWhatsapp(orcamento.id, ctx.tenantId)

  return NextResponse.json({
    id: orcamento.id,
    codigo: orcamento.codigo,
    textoWhatsapp,
    urlViari: `${VIARI_URL}/orcamentos/${orcamento.id}`,
  }, { status: 201 })
}
```

- [ ] **Step 3: Endpoint de texto WhatsApp de orçamento existente**

Criar `/Users/alexandre/Code/viari/src/app/api/viari/orcamentos/[id]/texto-whatsapp/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server'
import { requireViariApiKey, isErrorResponse } from '@/lib/auth/viari-api-key'
import { gerarTextoWhatsapp } from '@/lib/services/viari-texto-whatsapp'

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const ctx = await requireViariApiKey(req)
  if (isErrorResponse(ctx)) return ctx

  const { id } = await params

  try {
    const texto = await gerarTextoWhatsapp(id, ctx.tenantId)
    return NextResponse.json({ textoWhatsapp: texto })
  } catch {
    return NextResponse.json({ error: 'Orçamento não encontrado' }, { status: 404 })
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add src/app/api/viari/orcamentos/ src/lib/services/viari-texto-whatsapp.ts
git commit -m "feat(viari-api): add quote creation endpoint + WhatsApp text generation"
```

---

## FASE B — Chatwoot: Foundation (Rails + config)

---

### Task 7: Registrar integração Viari no Chatwoot (apps.yml + i18n)

**Files:**
- Modify: `/Users/alexandre/Code/chatwoot-roteiros/config/integration/apps.yml`
- Modify: `/Users/alexandre/Code/chatwoot-roteiros/config/locales/en.yml`
- Modify: `/Users/alexandre/Code/chatwoot-roteiros/app/javascript/dashboard/i18n/locale/en/integrations.json`
- Modify: `/Users/alexandre/Code/chatwoot-roteiros/app/javascript/dashboard/i18n/locale/en/conversation.json`
- Create: `public/dashboard/images/integrations/viari.png` ← logo (copiar placeholder temporariamente)

- [ ] **Step 1: Adicionar Viari ao apps.yml**

Em `config/integration/apps.yml`, adicionar ao final do arquivo:

```yaml
viari:
  id: viari
  logo: viari.png
  i18n_key: viari
  hook_type: account
  allow_multiple_hooks: false
  settings_json_schema:
    {
      'type': 'object',
      'properties':
        {
          'api_url': { 'type': 'string' },
          'api_key': { 'type': 'string' },
        },
      'required': ['api_url', 'api_key'],
      'additionalProperties': false,
    }
```

- [ ] **Step 2: Adicionar translations backend (en.yml)**

Em `config/locales/en.yml`, dentro do bloco `integration_apps:`, adicionar:

```yaml
    viari:
      name: 'Viari'
      short_description: 'Acesse reservas, orçamentos e pagamentos dos seus clientes no Viari.'
      description: 'Conecte o Viari ao Chatwoot para sincronizar clientes automaticamente, visualizar reservas/orçamentos/pagamentos e criar orçamentos diretamente na conversa.'
```

- [ ] **Step 3: Adicionar translations frontend (en/integrations.json)**

Em `app/javascript/dashboard/i18n/locale/en/integrations.json`, dentro de `INTEGRATION_SETTINGS`, adicionar:

```json
"VIARI": {
  "HEADER": "Viari",
  "CONNECT": {
    "TITLE": "Conectar Viari",
    "API_URL_LABEL": "URL do Viari",
    "API_URL_PLACEHOLDER": "https://viari.portoseguroroteiros.com.br",
    "API_URL_HELP": "Endereço completo do seu sistema Viari",
    "API_KEY_LABEL": "API Key",
    "API_KEY_PLACEHOLDER": "viari_xxxx...",
    "API_KEY_HELP": "Gerada nas configurações do Viari (Configurações → Integrações → API Key)",
    "SUBMIT": "Conectar",
    "CANCEL": "Cancelar"
  },
  "UPDATE": {
    "TITLE": "Atualizar configurações",
    "SUBMIT": "Salvar alterações"
  },
  "DELETE": {
    "TITLE": "Desconectar Viari",
    "MESSAGE": "Tem certeza que deseja desconectar o Viari? O painel lateral deixará de funcionar."
  },
  "CONNECTED": "Conectado",
  "ERROR": "Erro ao conectar com o Viari. Verifique a URL e a API Key.",
  "LABELS_CREATED": "Etiquetas de CRM criadas com sucesso."
}
```

- [ ] **Step 4: Adicionar translations do painel lateral (en/conversation.json)**

Em `app/javascript/dashboard/i18n/locale/en/conversation.json`, dentro de `CONVERSATION_SIDEBAR.ITEMS`, adicionar:

```json
"VIARI_PANEL": "Viari"
```

E adicionar a seção `VIARI` após `SHOPIFY`:

```json
"VIARI": {
  "LOADING": "Carregando dados do Viari...",
  "ERROR": "Erro ao carregar dados do Viari",
  "NOT_LINKED": "Cliente não encontrado no Viari",
  "LINKED": "Vinculado",
  "NEW_QUOTE": "Novo orçamento",
  "OPEN_IN_VIARI": "Abrir no Viari",
  "TABS": {
    "RESERVAS": "Reservas",
    "ORCAMENTOS": "Orçamentos",
    "PAGAMENTOS": "Pagamentos"
  },
  "EMPTY": {
    "RESERVAS": "Nenhuma reserva encontrada",
    "ORCAMENTOS": "Nenhum orçamento encontrado",
    "PAGAMENTOS": "Nenhum pagamento encontrado"
  },
  "JOURNEY": {
    "CONTATO": "Contato",
    "ORCAMENTO": "Orçamento",
    "SINAL": "Sinal",
    "RESERVA": "Reserva",
    "EMBARQUE": "Embarque"
  },
  "MODAL": {
    "TITLE": "Novo Orçamento",
    "STEP1_TITLE": "Dados gerais",
    "STEP2_TITLE": "Produtos",
    "STEP3_TITLE": "Revisão",
    "CLIENT_LABEL": "Cliente",
    "PERIOD_LABEL": "Período",
    "CANAL_LABEL": "Canal de venda",
    "VALIDITY_LABEL": "Validade",
    "SINAL_LABEL": "% de sinal",
    "DISCOUNT_LABEL": "Desconto (R$)",
    "OBS_LABEL": "Observações internas",
    "MSG_LABEL": "Mensagem para o cliente",
    "ADD_ITEM": "Adicionar produto",
    "PRODUCT_LABEL": "Produto",
    "AGENDA_LABEL": "Data / Agenda",
    "PAX_LABEL": "Passageiros por faixa etária",
    "SUBTOTAL": "Subtotal",
    "TOTAL_CARTAO": "Total cartão",
    "TOTAL_PIX": "Total PIX",
    "SINAL_VALUE": "Sinal",
    "ACERTO": "Acerto no 1° passeio",
    "WHATSAPP_PREVIEW": "Texto gerado — será colado na conversa",
    "CONFIRM": "Confirmar e colar na conversa",
    "COPY_TEXT": "Só copiar texto",
    "BACK": "Voltar",
    "NEXT": "Próximo",
    "CREATING": "Criando orçamento...",
    "SUCCESS": "Orçamento criado! Texto colado na conversa.",
    "ERROR": "Erro ao criar orçamento."
  }
}
```

- [ ] **Step 5: Adicionar logo placeholder**

```bash
cp /Users/alexandre/Code/chatwoot-roteiros/public/dashboard/images/integrations/shopify.png \
   /Users/alexandre/Code/chatwoot-roteiros/public/dashboard/images/integrations/viari.png
```

(Substituir pela logo real do Viari quando disponível)

- [ ] **Step 6: Commit**

```bash
git add config/integration/apps.yml config/locales/en.yml \
  app/javascript/dashboard/i18n/locale/en/integrations.json \
  app/javascript/dashboard/i18n/locale/en/conversation.json \
  public/dashboard/images/integrations/viari.png
git commit -m "feat(viari): register Viari integration in apps.yml and add i18n strings"
```

---

### Task 8: Rails proxy controller + rotas

**Files:**
- Create: `app/controllers/api/v1/accounts/integrations/viari_controller.rb`
- Modify: `config/routes.rb`

- [ ] **Step 1: Criar o controller proxy**

Criar `app/controllers/api/v1/accounts/integrations/viari_controller.rb`:

```ruby
class Api::V1::Accounts::Integrations::ViariController < Api::V1::Accounts::BaseController
  before_action :fetch_hook
  before_action :fetch_contact, only: %i[customer reservas orcamentos pagamentos]

  # GET — busca ou cria o cliente no Viari pelo contato do Chatwoot
  def customer
    contact = Current.account.contacts.find_by(id: params[:contact_id])
    return render json: { error: 'Contact not found' }, status: :not_found unless contact

    viari_cliente_id = contact.additional_attributes&.dig('viari_cliente_id')

    if viari_cliente_id
      return render json: { encontrado: true, clienteId: viari_cliente_id }
    end

    # Busca no Viari por telefone/e-mail
    query = {}
    query[:telefone] = contact.phone_number if contact.phone_number.present?
    query[:email] = contact.email if contact.email.present?

    response = viari_get('/api/viari/clientes/buscar', query)

    if response[:encontrado]
      persist_viari_id(contact, response[:cliente][:id])
      return render json: response
    end

    # Cria no Viari
    body = { nome: contact.name, telefone: contact.phone_number, email: contact.email }.compact
    created = viari_post('/api/viari/clientes', body)
    persist_viari_id(contact, created[:cliente][:id])
    render json: created
  end

  def reservas
    render json: viari_get("/api/viari/clientes/#{viari_cliente_id}/reservas")
  end

  def orcamentos
    render json: viari_get("/api/viari/clientes/#{viari_cliente_id}/orcamentos")
  end

  def pagamentos
    render json: viari_get("/api/viari/clientes/#{viari_cliente_id}/pagamentos")
  end

  def produtos
    render json: viari_get('/api/viari/produtos')
  end

  def agendas
    render json: viari_get('/api/viari/agendas', {
      produtoId: params[:produtoId],
      dataInicio: params[:dataInicio],
      dataFim: params[:dataFim]
    }.compact)
  end

  def tarifas
    render json: viari_get('/api/viari/tarifas/vigentes', {
      produtoId: params[:produtoId],
      data: params[:data]
    }.compact)
  end

  def canais_venda
    render json: viari_get('/api/viari/canais-venda')
  end

  def create_orcamento
    render json: viari_post('/api/viari/orcamentos', params.except(:account_id, :format).permit!.to_h)
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def texto_whatsapp
    render json: viari_get("/api/viari/orcamentos/#{params[:orcamento_id]}/texto-whatsapp")
  end

  def destroy
    @hook.destroy!
    head :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def fetch_hook
    @hook = Integrations::Hook.find_by!(account: Current.account, app_id: 'viari')
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Viari not configured' }, status: :not_found
  end

  def fetch_contact
    # contact_id param is required for contact-scoped actions
    return if params[:contact_id].blank?

    @contact = Current.account.contacts.find_by(id: params[:contact_id])
    render json: { error: 'Contact not found' }, status: :not_found unless @contact
  end

  def viari_cliente_id
    @contact&.additional_attributes&.dig('viari_cliente_id') ||
      render(json: { error: 'Contact not linked to Viari' }, status: :unprocessable_entity)
  end

  def persist_viari_id(contact, id)
    attrs = (contact.additional_attributes || {}).merge('viari_cliente_id' => id)
    contact.update_columns(additional_attributes: attrs)
  end

  def api_url
    @hook.settings['api_url'].to_s.chomp('/')
  end

  def api_key
    @hook.settings['api_key'].to_s
  end

  def viari_headers
    {
      'Content-Type' => 'application/json',
      'X-Viari-Api-Key' => api_key
    }
  end

  def viari_get(path, query = {})
    uri = URI("#{api_url}#{path}")
    uri.query = URI.encode_www_form(query) if query.any?
    response = Net::HTTP.get_response(uri, viari_headers)
    JSON.parse(response.body, symbolize_names: true)
  rescue StandardError => e
    raise "Viari API error: #{e.message}"
  end

  def viari_post(path, body = {})
    uri = URI("#{api_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    request = Net::HTTP::Post.new(uri.path, viari_headers)
    request.body = body.to_json
    response = http.request(request)
    JSON.parse(response.body, symbolize_names: true)
  rescue StandardError => e
    raise "Viari API error: #{e.message}"
  end
end
```

- [ ] **Step 2: Adicionar rotas**

Em `config/routes.rb`, dentro do bloco `namespace :integrations` (onde estão `:shopify`, `:linear`), adicionar:

```ruby
resource :viari, controller: 'viari', only: [:destroy] do
  collection do
    get :customer
    get :reservas
    get :orcamentos
    get :pagamentos
    get :produtos
    get :agendas
    get :tarifas
    get :canais_venda
    post :create_orcamento
    get 'texto_whatsapp/:orcamento_id', action: :texto_whatsapp
  end
end
```

- [ ] **Step 3: Verificar que as rotas existem**

```bash
bundle exec rails routes | grep viari
```

Saída esperada: linhas com `customer`, `reservas`, `orcamentos`, `pagamentos`, `produtos`, `agendas`, `tarifas`, `canais_venda`, `create_orcamento`, `texto_whatsapp`.

- [ ] **Step 4: Commit**

```bash
git add app/controllers/api/v1/accounts/integrations/viari_controller.rb config/routes.rb
git commit -m "feat(viari): add Rails proxy controller and routes"
```

---

### Task 9: JS API client

**Files:**
- Create: `app/javascript/dashboard/api/integrations/viari.js`

- [ ] **Step 1: Criar o client JS**

Criar `app/javascript/dashboard/api/integrations/viari.js`:

```js
/* global axios */
import ApiClient from '../ApiClient'

class ViariAPI extends ApiClient {
  constructor() {
    super('integrations/viari', { accountScoped: true })
  }

  getCustomer(contactId) {
    return axios.get(`${this.url}/customer`, { params: { contact_id: contactId } })
  }

  getReservas(contactId) {
    return axios.get(`${this.url}/reservas`, { params: { contact_id: contactId } })
  }

  getOrcamentos(contactId) {
    return axios.get(`${this.url}/orcamentos`, { params: { contact_id: contactId } })
  }

  getPagamentos(contactId) {
    return axios.get(`${this.url}/pagamentos`, { params: { contact_id: contactId } })
  }

  getProdutos() {
    return axios.get(`${this.url}/produtos`)
  }

  getAgendas(produtoId, dataInicio, dataFim) {
    return axios.get(`${this.url}/agendas`, {
      params: { produtoId, dataInicio, dataFim },
    })
  }

  getTarifas(produtoId, data) {
    return axios.get(`${this.url}/tarifas`, { params: { produtoId, data } })
  }

  getCanaisVenda() {
    return axios.get(`${this.url}/canais_venda`)
  }

  criarOrcamento(payload) {
    return axios.post(`${this.url}/create_orcamento`, payload)
  }

  getTextoWhatsapp(orcamentoId) {
    return axios.get(`${this.url}/texto_whatsapp/${orcamentoId}`)
  }
}

export default new ViariAPI()
```

- [ ] **Step 2: Commit**

```bash
git add app/javascript/dashboard/api/integrations/viari.js
git commit -m "feat(viari): add JavaScript API client"
```

---

### Task 10: Página de configurações (URL + API key — conectar/editar/desconectar)

**Files:**
- Create: `app/javascript/dashboard/routes/dashboard/settings/integrations/Viari.vue`

- [ ] **Step 1: Criar a página de configurações**

Criar `app/javascript/dashboard/routes/dashboard/settings/integrations/Viari.vue`:

```vue
<script setup>
import { ref, computed, onMounted } from 'vue'
import { useFunctionGetter, useMapGetter, useStore } from 'dashboard/composables/store'
import { useI18n } from 'vue-i18n'
import Integration from './Integration.vue'
import integrationAPI from 'dashboard/api/integrations'
import Input from 'dashboard/components-next/input/Input.vue'
import Dialog from 'dashboard/components-next/dialog/Dialog.vue'
import Button from 'dashboard/components-next/button/Button.vue'
import SettingsLayout from '../SettingsLayout.vue'
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue'

const store = useStore()
const { t } = useI18n()
const dialogRef = ref(null)
const integrationLoaded = ref(false)
const isSubmitting = ref(false)
const isEditing = ref(false)

const apiUrl = ref('')
const apiKey = ref('')
const apiUrlError = ref('')
const apiKeyError = ref('')

const integration = useFunctionGetter('integrations/getIntegration', 'viari')
const uiFlags = useMapGetter('integrations/getUIFlags')

const integrationAction = computed(() =>
  integration.value.enabled ? 'disconnect' : 'connect'
)

const dialogTitle = computed(() =>
  isEditing.value
    ? t('INTEGRATION_SETTINGS.VIARI.UPDATE.TITLE')
    : t('INTEGRATION_SETTINGS.VIARI.CONNECT.TITLE')
)

const openDialog = (editing = false) => {
  isEditing.value = editing
  apiUrlError.value = ''
  apiKeyError.value = ''
  if (editing) {
    const hook = integration.value
    apiUrl.value = hook.settings?.api_url ?? ''
    apiKey.value = hook.settings?.api_key ?? ''
  } else {
    apiUrl.value = ''
    apiKey.value = ''
  }
  dialogRef.value?.open()
}

const validateForm = () => {
  let valid = true
  if (!apiUrl.value.startsWith('http')) {
    apiUrlError.value = 'Informe uma URL válida (ex: https://viari.portoseguroroteiros.com.br)'
    valid = false
  }
  if (apiKey.value.length < 10) {
    apiKeyError.value = 'API Key inválida'
    valid = false
  }
  return valid
}

const handleSubmit = async () => {
  if (!validateForm()) return

  isSubmitting.value = true
  try {
    if (isEditing.value) {
      await integrationAPI.updateHook(integration.value.id, {
        settings: { api_url: apiUrl.value, api_key: apiKey.value },
      })
    } else {
      await integrationAPI.createHook({
        app_id: 'viari',
        settings: { api_url: apiUrl.value, api_key: apiKey.value },
      })
    }
    await store.dispatch('integrations/get', 'viari')
    dialogRef.value?.close()
  } catch (e) {
    apiUrlError.value = t('INTEGRATION_SETTINGS.VIARI.ERROR')
  } finally {
    isSubmitting.value = false
  }
}

const handleClose = () => {
  apiUrl.value = ''
  apiKey.value = ''
  apiUrlError.value = ''
  apiKeyError.value = ''
}

onMounted(async () => {
  await store.dispatch('integrations/get', 'viari')
  integrationLoaded.value = true
})
</script>

<template>
  <SettingsLayout :is-loading="!integrationLoaded">
    <template #header>
      <BaseSettingsHeader
        :title="t('INTEGRATION_SETTINGS.VIARI.HEADER')"
        description=""
        :back-button-label="t('INTEGRATION_SETTINGS.HEADER')"
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-6">
        <Integration
          :integration-id="integration.id"
          :integration-logo="integration.logo"
          :integration-name="integration.name"
          :integration-description="integration.description"
          :integration-enabled="integration.enabled"
          :integration-action="integrationAction"
          :delete-confirmation-text="{
            title: t('INTEGRATION_SETTINGS.VIARI.DELETE.TITLE'),
            message: t('INTEGRATION_SETTINGS.VIARI.DELETE.MESSAGE'),
          }"
        >
          <template #action>
            <div class="flex gap-2">
              <Button
                v-if="!integration.enabled"
                teal
                :label="t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT')"
                @click="openDialog(false)"
              />
              <Button
                v-else
                ghost
                :label="t('INTEGRATION_SETTINGS.VIARI.UPDATE.SUBMIT')"
                @click="openDialog(true)"
              />
            </div>
          </template>
        </Integration>

        <Dialog
          ref="dialogRef"
          :title="dialogTitle"
          :is-loading="isSubmitting"
          @confirm="handleSubmit"
          @close="handleClose"
        >
          <div class="flex flex-col gap-4">
            <Input
              v-model="apiUrl"
              :label="t('INTEGRATION_SETTINGS.VIARI.CONNECT.API_URL_LABEL')"
              :placeholder="t('INTEGRATION_SETTINGS.VIARI.CONNECT.API_URL_PLACEHOLDER')"
              :message="apiUrlError || t('INTEGRATION_SETTINGS.VIARI.CONNECT.API_URL_HELP')"
              :message-type="apiUrlError ? 'error' : 'info'"
            />
            <Input
              v-model="apiKey"
              :label="t('INTEGRATION_SETTINGS.VIARI.CONNECT.API_KEY_LABEL')"
              :placeholder="t('INTEGRATION_SETTINGS.VIARI.CONNECT.API_KEY_PLACEHOLDER')"
              :message="apiKeyError || t('INTEGRATION_SETTINGS.VIARI.CONNECT.API_KEY_HELP')"
              :message-type="apiKeyError ? 'error' : 'info'"
              type="password"
            />
          </div>
        </Dialog>
      </div>
    </template>
  </SettingsLayout>
</template>
```

- [ ] **Step 2: Registrar a rota da página de settings**

Em `app/javascript/dashboard/routes/dashboard/settings/integrations/`, verificar o arquivo de rotas de integrações (normalmente em `index.js` ou no router de settings) e adicionar:

```js
{
  path: 'viari',
  name: 'settings_integrations_viari',
  component: () => import('./Viari.vue'),
}
```

Buscar onde Shopify está registrado com:
```bash
grep -rn "Shopify\|shopify" /Users/alexandre/Code/chatwoot-roteiros/app/javascript/dashboard/routes/dashboard/settings/ --include="*.js" | grep -v node_modules | head -10
```

- [ ] **Step 3: Commit**

```bash
git add app/javascript/dashboard/routes/dashboard/settings/integrations/Viari.vue
git commit -m "feat(viari): add settings page with configurable URL and API key"
```

---

## FASE C — Chatwoot: Painel lateral

---

### Task 11: ViariPanel — container principal + auto-sync

**Files:**
- Create: `app/javascript/dashboard/components/widgets/conversation/viari/ViariPanel.vue`

- [ ] **Step 1: Criar o container principal**

Criar `app/javascript/dashboard/components/widgets/conversation/viari/ViariPanel.vue`:

```vue
<script setup>
import { ref, watch, computed } from 'vue'
import { useStore, useFunctionGetter } from 'dashboard/composables/store'
import ViariJourneyBar from './ViariJourneyBar.vue'
import ViariTabs from './ViariTabs.vue'
import ViariOrcamentoModal from './ViariOrcamentoModal.vue'
import ViariAPI from 'dashboard/api/integrations/viari'
import Spinner from 'dashboard/components-next/spinner/Spinner.vue'

const props = defineProps({
  contactId: { type: [Number, String], required: true },
  conversationId: { type: [Number, String], required: true },
})

const store = useStore()
const contact = useFunctionGetter('contacts/getContact', props.contactId)

const loading = ref(true)
const error = ref('')
const clienteData = ref(null)
const showModal = ref(false)

const statusJornada = computed(() => clienteData.value?.cliente?.statusJornada ?? 'contato')
const viariClienteId = computed(() => clienteData.value?.cliente?.id ?? null)

const VIARI_LABELS = [
  'viari-vinculado', 'orcamento-enviado', 'orcamento-aprovado',
  'aguardando-sinal', 'reserva-confirmada', 'pago-completo',
  'orcamento-perdido', 'concluido',
]

const JORNADA_LABEL_MAP = {
  contato: 'viari-vinculado',
  orcamento: 'orcamento-enviado',
  sinal: 'aguardando-sinal',
  reserva: 'reserva-confirmada',
  pago: 'pago-completo',
  embarque: 'concluido',
}

const applyLabels = async (status) => {
  const label = JORNADA_LABEL_MAP[status]
  if (!label) return
  try {
    const conversation = store.getters.getSelectedChat
    const currentLabels = conversation?.labels ?? []
    const labelsWithoutViari = currentLabels.filter((l) => !VIARI_LABELS.includes(l))
    const newLabels = [...labelsWithoutViari, label]
    await store.dispatch('conversations/update', {
      id: props.conversationId,
      labels: newLabels,
    })
  } catch {
    // labels are best-effort
  }
}

const loadCustomer = async () => {
  loading.value = true
  error.value = ''
  try {
    const response = await ViariAPI.getCustomer(props.contactId)
    clienteData.value = response.data
    await applyLabels(statusJornada.value)
  } catch (e) {
    error.value = e.response?.data?.error || 'CONVERSATION_SIDEBAR.VIARI.ERROR'
  } finally {
    loading.value = false
  }
}

watch(
  () => props.contactId,
  () => loadCustomer(),
  { immediate: true }
)
</script>

<template>
  <div class="viari-panel">
    <!-- Header -->
    <div class="flex items-center justify-between px-3 py-2"
         style="background:#0D2B2A;">
      <div class="flex items-center gap-2">
        <span class="text-base">🏖️</span>
        <span class="text-sm font-bold" style="color:#5DCAA5;">Viari</span>
        <span v-if="!loading && !error"
              class="text-[9px] px-1.5 py-0.5 rounded-full font-semibold"
              style="background:#1D9E75; color:#E1F5EE;">
          {{ $t('CONVERSATION_SIDEBAR.VIARI.LINKED') }}
        </span>
      </div>
      <button
        v-if="!loading && !error"
        class="text-[10px] font-bold px-2 py-1 rounded"
        style="background:#1D9E75; color:white;"
        @click="showModal = true"
      >
        + {{ $t('CONVERSATION_SIDEBAR.VIARI.NEW_QUOTE') }}
      </button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex justify-center items-center py-4"
         style="background:white;">
      <Spinner size="24" style="color:#1D9E75;" />
    </div>

    <!-- Error -->
    <div v-else-if="error" class="text-center py-3 text-sm"
         style="background:white; color:#ef4444;">
      {{ $t('CONVERSATION_SIDEBAR.VIARI.ERROR') }}
    </div>

    <!-- Content -->
    <template v-else>
      <ViariJourneyBar :status="statusJornada" />
      <ViariTabs
        :contact-id="contactId"
        :viari-cliente-id="viariClienteId"
      />
    </template>

    <!-- Modal -->
    <ViariOrcamentoModal
      v-if="showModal"
      :contact-id="contactId"
      :viari-cliente-id="viariClienteId"
      :conversation-id="conversationId"
      @close="showModal = false"
      @created="loadCustomer"
    />
  </div>
</template>
```

- [ ] **Step 2: Commit**

```bash
git add app/javascript/dashboard/components/widgets/conversation/viari/ViariPanel.vue
git commit -m "feat(viari): add ViariPanel main container with auto-sync"
```

---

### Task 12: ViariJourneyBar + ViariCrmLabels

**Files:**
- Create: `app/javascript/dashboard/components/widgets/conversation/viari/ViariJourneyBar.vue`

- [ ] **Step 1: Criar barra de jornada do cliente**

Criar `app/javascript/dashboard/components/widgets/conversation/viari/ViariJourneyBar.vue`:

```vue
<script setup>
import { computed } from 'vue'

const props = defineProps({
  status: { type: String, default: 'contato' },
})

const steps = [
  { key: 'contato', label: 'Contato' },
  { key: 'orcamento', label: 'Orçamento' },
  { key: 'sinal', label: 'Sinal' },
  { key: 'reserva', label: 'Reserva' },
  { key: 'embarque', label: 'Embarque' },
]

const currentIndex = computed(() =>
  steps.findIndex((s) => s.key === props.status)
)

const getState = (index) => {
  if (index < currentIndex.value) return 'done'
  if (index === currentIndex.value) return 'current'
  return 'todo'
}
</script>

<template>
  <div class="px-3 pt-2 pb-1" style="background:#E1F5EE;">
    <div class="text-[9px] font-bold uppercase tracking-wider mb-1.5"
         style="color:#0F6E56;">
      Jornada do cliente
    </div>
    <div class="flex items-center">
      <template v-for="(step, i) in steps" :key="step.key">
        <div class="flex flex-col items-center">
          <!-- Dot -->
          <div
            class="w-5 h-5 rounded-full flex items-center justify-center text-[9px] font-bold"
            :style="{
              background: getState(i) === 'done' ? '#1D9E75'
                        : getState(i) === 'current' ? '#EF9F27'
                        : '#5DCAA5',
              color: getState(i) === 'done' ? 'white'
                   : getState(i) === 'current' ? '#0D2B2A'
                   : '#0D2B2A',
              opacity: getState(i) === 'todo' ? '0.4' : '1',
              boxShadow: getState(i) === 'current' ? '0 0 0 3px rgba(239,159,39,0.3)' : 'none',
            }"
          >
            {{ getState(i) === 'done' ? '✓' : '●' }}
          </div>
          <!-- Label -->
          <div
            class="text-[8px] font-semibold mt-0.5 text-center"
            :style="{
              color: getState(i) === 'current' ? '#EF9F27' : '#0F6E56',
              fontWeight: getState(i) === 'current' ? '700' : '600',
            }"
          >
            {{ step.label }}
          </div>
        </div>
        <!-- Connector line -->
        <div
          v-if="i < steps.length - 1"
          class="flex-1 h-0.5 mb-3"
          :style="{
            background: i < currentIndex ? '#1D9E75' : '#5DCAA5',
            opacity: i < currentIndex ? '1' : '0.3',
          }"
        />
      </template>
    </div>
  </div>
</template>
```

- [ ] **Step 2: Commit**

```bash
git add app/javascript/dashboard/components/widgets/conversation/viari/ViariJourneyBar.vue
git commit -m "feat(viari): add journey progress bar component"
```

---

### Task 13: ViariTabs + cards de reservas, orçamentos e pagamentos

**Files:**
- Create: `app/javascript/dashboard/components/widgets/conversation/viari/ViariTabs.vue`
- Create: `app/javascript/dashboard/components/widgets/conversation/viari/ViariReservaCard.vue`
- Create: `app/javascript/dashboard/components/widgets/conversation/viari/ViariOrcamentoCard.vue`
- Create: `app/javascript/dashboard/components/widgets/conversation/viari/ViariPagamentoCard.vue`

- [ ] **Step 1: Criar ViariTabs**

Criar `app/javascript/dashboard/components/widgets/conversation/viari/ViariTabs.vue`:

```vue
<script setup>
import { ref, watch } from 'vue'
import ViariReservaCard from './ViariReservaCard.vue'
import ViariOrcamentoCard from './ViariOrcamentoCard.vue'
import ViariPagamentoCard from './ViariPagamentoCard.vue'
import ViariAPI from 'dashboard/api/integrations/viari'
import Spinner from 'dashboard/components-next/spinner/Spinner.vue'

const props = defineProps({
  contactId: { type: [Number, String], required: true },
  viariClienteId: { type: String, default: null },
})

const activeTab = ref('reservas')
const tabs = ['reservas', 'orcamentos', 'pagamentos']

const data = ref({ reservas: [], orcamentos: [], pagamentos: [] })
const loading = ref({ reservas: false, orcamentos: false, pagamentos: false })
const loaded = ref({ reservas: false, orcamentos: false, pagamentos: false })

const fetchTab = async (tab) => {
  if (loaded.value[tab] || !props.viariClienteId) return
  loading.value[tab] = true
  try {
    const apiMap = {
      reservas: () => ViariAPI.getReservas(props.contactId),
      orcamentos: () => ViariAPI.getOrcamentos(props.contactId),
      pagamentos: () => ViariAPI.getPagamentos(props.contactId),
    }
    const response = await apiMap[tab]()
    data.value[tab] = response.data[tab] ?? []
    loaded.value[tab] = true
  } catch {
    data.value[tab] = []
  } finally {
    loading.value[tab] = false
  }
}

watch(activeTab, (tab) => fetchTab(tab), { immediate: true })
watch(() => props.viariClienteId, () => {
  loaded.value = { reservas: false, orcamentos: false, pagamentos: false }
  fetchTab(activeTab.value)
})
</script>

<template>
  <div style="background:white;">
    <!-- Tab bar -->
    <div class="flex border-b" style="border-color:#b2dfd0;">
      <button
        v-for="tab in tabs"
        :key="tab"
        class="px-3 py-2 text-[11px] font-semibold capitalize"
        :style="{
          color: activeTab === tab ? '#1D9E75' : '#0F6E56',
          borderBottom: activeTab === tab ? '2px solid #1D9E75' : '2px solid transparent',
          opacity: activeTab === tab ? '1' : '0.6',
        }"
        @click="activeTab = tab"
      >
        {{ $t(`CONVERSATION_SIDEBAR.VIARI.TABS.${tab.toUpperCase()}`) }}
      </button>
    </div>

    <!-- Tab content -->
    <div class="px-3 py-2 space-y-2">
      <div v-if="loading[activeTab]" class="flex justify-center py-3">
        <Spinner size="20" style="color:#1D9E75;" />
      </div>
      <template v-else-if="data[activeTab].length > 0">
        <ViariReservaCard
          v-if="activeTab === 'reservas'"
          v-for="item in data.reservas"
          :key="item.id"
          :reserva="item"
        />
        <ViariOrcamentoCard
          v-if="activeTab === 'orcamentos'"
          v-for="item in data.orcamentos"
          :key="item.id"
          :orcamento="item"
        />
        <ViariPagamentoCard
          v-if="activeTab === 'pagamentos'"
          v-for="item in data.pagamentos"
          :key="item.id"
          :pagamento="item"
        />
      </template>
      <p v-else class="text-center text-[11px] py-3" style="color:#0F6E56; opacity:0.6;">
        {{ $t(`CONVERSATION_SIDEBAR.VIARI.EMPTY.${activeTab.toUpperCase()}`) }}
      </p>
    </div>
  </div>
</template>
```

- [ ] **Step 2: Criar ViariReservaCard**

Criar `app/javascript/dashboard/components/widgets/conversation/viari/ViariReservaCard.vue`:

```vue
<script setup>
const props = defineProps({
  reserva: { type: Object, required: true },
})

const STATUS_COLOR = {
  confirmada: '#1D9E75',
  pendente: '#EF9F27',
  checkin: '#6366f1',
  concluida: '#0F6E56',
  cancelada: '#ef4444',
  noshow: '#94a3b8',
}

const fmt = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' })

const formatDate = (d) => new Date(d).toLocaleDateString('pt-BR', { timeZone: 'UTC', day: '2-digit', month: '2-digit', year: 'numeric' })

const paxLabel = (pax) => {
  const parts = []
  if (pax.adt) parts.push(`${pax.adt} ADT`)
  if (pax.chd) parts.push(`${pax.chd} CHD`)
  if (pax.inf) parts.push(`${pax.inf} INF`)
  if (pax.sen) parts.push(`${pax.sen} SEN`)
  return parts.join(' + ')
}
</script>

<template>
  <div class="rounded-lg p-2.5 text-[11px] relative"
       style="border: 1px solid #b2dfd0; border-left: 3px solid #1D9E75; background:#f8fffe;">
    <!-- Link externo -->
    <a
      :href="reserva.urlViari"
      target="_blank"
      rel="noopener"
      class="absolute top-2 right-2 text-[10px] opacity-50 hover:opacity-100"
      style="color:#1D9E75;"
      :title="$t('CONVERSATION_SIDEBAR.VIARI.OPEN_IN_VIARI')"
    >↗</a>

    <div class="font-bold pr-4" style="color:#0D2B2A;">{{ reserva.produto }}</div>
    <div class="mt-0.5" style="color:#0F6E56;">
      {{ formatDate(reserva.dataAgenda) }}
      <span v-if="reserva.horario"> · {{ reserva.horario }}</span>
      <span v-if="paxLabel(reserva.pax)"> · {{ paxLabel(reserva.pax) }}</span>
    </div>
    <div class="flex justify-between items-center mt-1.5">
      <span class="text-[9px] px-1.5 py-0.5 rounded-full font-bold"
            :style="{ background: STATUS_COLOR[reserva.status] + '20', color: STATUS_COLOR[reserva.status] }">
        {{ reserva.status }}
      </span>
      <span class="font-bold" style="color:#0D2B2A;">{{ fmt.format(reserva.valorTotal) }}</span>
    </div>
  </div>
</template>
```

- [ ] **Step 3: Criar ViariOrcamentoCard**

Criar `app/javascript/dashboard/components/widgets/conversation/viari/ViariOrcamentoCard.vue`:

```vue
<script setup>
const props = defineProps({
  orcamento: { type: Object, required: true },
})

const STATUS_COLOR = {
  rascunho: '#94a3b8',
  enviado: '#EF9F27',
  visualizado: '#6366f1',
  aprovado: '#1D9E75',
  convertido: '#0F6E56',
  recusado: '#ef4444',
  expirado: '#94a3b8',
  cancelado: '#ef4444',
}

const fmt = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' })
const formatDate = (d) => new Date(d).toLocaleDateString('pt-BR', { timeZone: 'UTC', day: '2-digit', month: '2-digit', year: 'numeric' })
</script>

<template>
  <div class="rounded-lg p-2.5 text-[11px] relative"
       style="border: 1px solid #b2dfd0; border-left: 3px solid #EF9F27; background:#f8fffe;">
    <a
      :href="orcamento.urlViari"
      target="_blank"
      rel="noopener"
      class="absolute top-2 right-2 text-[10px] opacity-50 hover:opacity-100"
      style="color:#1D9E75;"
    >↗</a>
    <div class="font-bold pr-4" style="color:#0D2B2A;">{{ orcamento.codigo }}</div>
    <div style="color:#0F6E56;">
      {{ orcamento.itens }} produto(s) · validade {{ formatDate(orcamento.dataValidade) }}
    </div>
    <div class="flex justify-between items-center mt-1.5">
      <span class="text-[9px] px-1.5 py-0.5 rounded-full font-bold"
            :style="{ background: STATUS_COLOR[orcamento.status] + '20', color: STATUS_COLOR[orcamento.status] }">
        {{ orcamento.status }}
      </span>
      <div class="text-right">
        <div class="font-bold" style="color:#0D2B2A;">{{ fmt.format(orcamento.totalCartao) }}</div>
        <div class="text-[9px]" style="color:#1D9E75;">PIX {{ fmt.format(orcamento.totalPix) }}</div>
      </div>
    </div>
  </div>
</template>
```

- [ ] **Step 4: Criar ViariPagamentoCard**

Criar `app/javascript/dashboard/components/widgets/conversation/viari/ViariPagamentoCard.vue`:

```vue
<script setup>
const props = defineProps({
  pagamento: { type: Object, required: true },
})

const fmt = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' })
const formatDate = (d) => new Date(d).toLocaleDateString('pt-BR', { timeZone: 'UTC', day: '2-digit', month: '2-digit', year: 'numeric' })
</script>

<template>
  <div class="rounded-lg p-2.5 text-[11px] relative"
       style="border: 1px solid #b2dfd0; border-left: 3px solid #5DCAA5; background:#f8fffe;">
    <a
      :href="pagamento.urlViari"
      target="_blank"
      rel="noopener"
      class="absolute top-2 right-2 text-[10px] opacity-50 hover:opacity-100"
      style="color:#1D9E75;"
    >↗</a>
    <div class="font-bold pr-4" style="color:#0D2B2A;">{{ pagamento.formaPagamento }}</div>
    <div style="color:#0F6E56;">{{ formatDate(pagamento.data) }} · {{ pagamento.reservaCodigo }}</div>
    <div class="flex justify-between items-center mt-1.5">
      <span class="text-[9px] px-1.5 py-0.5 rounded-full font-bold"
            style="background: #E1F5EE; color: #0F6E56;">
        {{ pagamento.status }}
      </span>
      <span class="font-bold" style="color:#1D9E75;">{{ fmt.format(pagamento.valor) }}</span>
    </div>
  </div>
</template>
```

- [ ] **Step 5: Commit**

```bash
git add app/javascript/dashboard/components/widgets/conversation/viari/
git commit -m "feat(viari): add tabs component and reservation/quote/payment cards"
```

---

### Task 14: Integrar ViariPanel ao ContactPanel

**Files:**
- Modify: `app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue`

- [ ] **Step 1: Importar e registrar ViariPanel no ContactPanel**

Em `app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue`, adicionar junto aos imports existentes:

```js
import ViariPanel from 'dashboard/components/widgets/conversation/viari/ViariPanel.vue'
```

Adicionar junto a `shopifyIntegration`:

```js
const viariIntegration = useFunctionGetter('integrations/getIntegration', 'viari')
const isViariEnabled = computed(() => viariIntegration.value.enabled)
```

- [ ] **Step 2: Adicionar o accordion item no template**

No template do `ContactPanel.vue`, após o bloco do Shopify (`<AccordionItem` com `SHOPIFY_ORDERS`), adicionar:

```vue
<AccordionItem
  v-if="isViariEnabled"
  :title="$t('CONVERSATION_SIDEBAR.ITEMS.VIARI_PANEL')"
  :is-open="isContactSidebarItemOpen('viari_panel')"
  @toggle="toggleSidebarUIState({ key: 'viari_panel' })"
>
  <ViariPanel
    :contact-id="contact.id"
    :conversation-id="conversationId"
  />
</AccordionItem>
```

- [ ] **Step 3: Adicionar a key ao sidebarItemsOrder default**

Buscar onde `conversationSidebarItemsOrder` é definido com os defaults e adicionar `viari_panel` à lista. Pesquisar:

```bash
grep -rn "viari_panel\|shopify\|sidebarItems" /Users/alexandre/Code/chatwoot-roteiros/app/javascript/dashboard/composables/useUISettings.js | head -20
```

Adicionar `'viari_panel'` na lista de items padrão da sidebar.

- [ ] **Step 4: Carregar a integração Viari no store ao iniciar**

Verificar onde `integrations/get` é disparado para `shopify` no `ContactPanel` ou nos componentes pai e garantir que `viari` também é carregado:

```bash
grep -n "integrations/get\|shopify" /Users/alexandre/Code/chatwoot-roteiros/app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue | head -10
```

Se houver um `onMounted` carregando integrações, adicionar `store.dispatch('integrations/get', 'viari')` junto.

- [ ] **Step 5: Commit**

```bash
git add app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue
git commit -m "feat(viari): wire ViariPanel into ContactPanel sidebar accordion"
```

---

## FASE D — Modal de criação de orçamento

---

### Task 15: ViariOrcamentoModal — Step 1 (dados gerais)

**Files:**
- Create: `app/javascript/dashboard/components/widgets/conversation/viari/ViariOrcamentoModal.vue`
- Create: `app/javascript/dashboard/components/widgets/conversation/viari/ViariModalStep1.vue`

- [ ] **Step 1: Criar o container do modal com estado compartilhado**

Criar `app/javascript/dashboard/components/widgets/conversation/viari/ViariOrcamentoModal.vue`:

```vue
<script setup>
import { ref } from 'vue'
import { useStore, useFunctionGetter } from 'dashboard/composables/store'
import ViariModalStep1 from './ViariModalStep1.vue'
import ViariModalStep2 from './ViariModalStep2.vue'
import ViariModalStep3 from './ViariModalStep3.vue'
import ViariAPI from 'dashboard/api/integrations/viari'

const props = defineProps({
  contactId: { type: [Number, String], required: true },
  viariClienteId: { type: String, required: true },
  conversationId: { type: [Number, String], required: true },
})

const emit = defineEmits(['close', 'created'])
const store = useStore()
const contact = useFunctionGetter('contacts/getContact', props.contactId)

const currentStep = ref(1)
const isCreating = ref(false)
const createError = ref('')

// Dados compartilhados entre as 3 etapas
const formData = ref({
  // Etapa 1
  canalVendaId: '',
  periodoInicio: '',
  periodoFim: '',
  dataValidade: '',
  percentualSinal: 35,
  descontoManual: 0,
  obsInternas: '',
  msgCliente: '',
  // Etapa 2
  itens: [],
})

const handleStep1Next = (data) => {
  Object.assign(formData.value, data)
  currentStep.value = 2
}

const handleStep2Next = (itens) => {
  formData.value.itens = itens
  currentStep.value = 3
}

const handleConfirm = async () => {
  isCreating.value = true
  createError.value = ''
  try {
    const payload = {
      clienteId: props.viariClienteId,
      ...formData.value,
    }
    const response = await ViariAPI.criarOrcamento(payload)
    const { textoWhatsapp } = response.data

    // Cola o texto na caixa de mensagem da conversa
    // O store draftMessages usa a key 'draft-{id}-REPLY'
    store.dispatch('draftMessages/set', {
      key: `draft-${props.conversationId}-REPLY`,
      message: textoWhatsapp,
    })

    emit('created')
    emit('close')
  } catch (e) {
    createError.value = e.response?.data?.error || 'CONVERSATION_SIDEBAR.VIARI.MODAL.ERROR'
  } finally {
    isCreating.value = false
  }
}
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center"
       style="background: rgba(0,0,0,0.6);">
    <div class="rounded-xl overflow-hidden shadow-2xl"
         style="width: 680px; max-height: 90vh; background:white; display:flex; flex-direction:column;">

      <!-- Header -->
      <div class="flex items-center justify-between px-5 py-3.5"
           style="background:#0D2B2A;">
        <div class="flex items-center gap-3">
          <span class="text-lg">🏖️</span>
          <div>
            <div class="text-sm font-bold" style="color:#5DCAA5;">
              {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.TITLE') }}
            </div>
            <div class="text-[11px]" style="color:#94a3b8;">
              {{ contact.name }} · {{ contact.phone_number }}
            </div>
          </div>
        </div>
        <button class="text-lg font-light" style="color:#5DCAA5;"
                @click="$emit('close')">✕</button>
      </div>

      <!-- Steps nav -->
      <div class="flex items-center px-5 py-2.5" style="background:#E1F5EE;">
        <template v-for="(label, i) in [
          $t('CONVERSATION_SIDEBAR.VIARI.MODAL.STEP1_TITLE'),
          $t('CONVERSATION_SIDEBAR.VIARI.MODAL.STEP2_TITLE'),
          $t('CONVERSATION_SIDEBAR.VIARI.MODAL.STEP3_TITLE'),
        ]" :key="i">
          <div class="flex items-center gap-1.5 text-[11px] font-semibold"
               :style="{ color: currentStep > i+1 ? '#0F6E56' : currentStep === i+1 ? '#1D9E75' : '#0F6E56',
                         opacity: currentStep >= i+1 ? '1' : '0.4' }">
            <div class="w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-extrabold"
                 :style="{ background: currentStep > i+1 ? '#0F6E56' : currentStep === i+1 ? '#1D9E75' : '#5DCAA5',
                           color: 'white' }">
              {{ currentStep > i+1 ? '✓' : i+1 }}
            </div>
            {{ label }}
          </div>
          <div v-if="i < 2" class="flex-1 h-px mx-2" style="background:#5DCAA5; opacity:0.4;" />
        </template>
      </div>

      <!-- Step content -->
      <div class="flex-1 overflow-y-auto">
        <ViariModalStep1
          v-if="currentStep === 1"
          :initial-data="formData"
          @next="handleStep1Next"
        />
        <ViariModalStep2
          v-else-if="currentStep === 2"
          :periodo-inicio="formData.periodoInicio"
          :periodo-fim="formData.periodoFim"
          :canal-venda-id="formData.canalVendaId"
          :percentual-sinal="formData.percentualSinal"
          :desconto-manual="formData.descontoManual"
          :initial-itens="formData.itens"
          @next="handleStep2Next"
          @back="currentStep = 1"
        />
        <ViariModalStep3
          v-else-if="currentStep === 3"
          :form-data="formData"
          :contact="contact"
          :is-creating="isCreating"
          :error="createError"
          @confirm="handleConfirm"
          @back="currentStep = 2"
        />
      </div>

    </div>
  </div>
</template>
```

- [ ] **Step 2: Criar ViariModalStep1**

Criar `app/javascript/dashboard/components/widgets/conversation/viari/ViariModalStep1.vue`:

```vue
<script setup>
import { ref, onMounted } from 'vue'
import ViariAPI from 'dashboard/api/integrations/viari'

const props = defineProps({
  initialData: { type: Object, required: true },
})
const emit = defineEmits(['next'])

const canais = ref([])
const form = ref({
  canalVendaId: props.initialData.canalVendaId ?? '',
  periodoInicio: props.initialData.periodoInicio ?? '',
  periodoFim: props.initialData.periodoFim ?? '',
  dataValidade: props.initialData.dataValidade ?? '',
  percentualSinal: props.initialData.percentualSinal ?? 35,
  descontoManual: props.initialData.descontoManual ?? 0,
  obsInternas: props.initialData.obsInternas ?? '',
  msgCliente: props.initialData.msgCliente ?? '',
})
const errors = ref({})

const validate = () => {
  errors.value = {}
  if (!form.value.periodoInicio) errors.value.periodoInicio = 'Obrigatório'
  if (!form.value.periodoFim) errors.value.periodoFim = 'Obrigatório'
  if (!form.value.dataValidade) errors.value.dataValidade = 'Obrigatório'
  return Object.keys(errors.value).length === 0
}

const handleNext = () => {
  if (validate()) emit('next', { ...form.value })
}

onMounted(async () => {
  try {
    const response = await ViariAPI.getCanaisVenda()
    canais.value = response.data.canais ?? []
  } catch { /* ignora — canal é opcional */ }
})
</script>

<template>
  <div class="p-5 space-y-4">
    <div class="grid grid-cols-2 gap-4">
      <div>
        <label class="block text-[10px] font-bold uppercase tracking-wide mb-1" style="color:#0F6E56;">
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.PERIOD_LABEL') }} início *
        </label>
        <input v-model="form.periodoInicio" type="date" class="w-full px-3 py-1.5 text-sm rounded border"
               :class="errors.periodoInicio ? 'border-red-400' : 'border-[#b2dfd0]'"
               style="background:#f8fffe; color:#0D2B2A;" />
        <p v-if="errors.periodoInicio" class="text-[10px] text-red-500 mt-0.5">{{ errors.periodoInicio }}</p>
      </div>
      <div>
        <label class="block text-[10px] font-bold uppercase tracking-wide mb-1" style="color:#0F6E56;">
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.PERIOD_LABEL') }} fim *
        </label>
        <input v-model="form.periodoFim" type="date" class="w-full px-3 py-1.5 text-sm rounded border"
               :class="errors.periodoFim ? 'border-red-400' : 'border-[#b2dfd0]'"
               style="background:#f8fffe; color:#0D2B2A;" />
        <p v-if="errors.periodoFim" class="text-[10px] text-red-500 mt-0.5">{{ errors.periodoFim }}</p>
      </div>
      <div>
        <label class="block text-[10px] font-bold uppercase tracking-wide mb-1" style="color:#0F6E56;">
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.VALIDITY_LABEL') }} *
        </label>
        <input v-model="form.dataValidade" type="date" class="w-full px-3 py-1.5 text-sm rounded border"
               :class="errors.dataValidade ? 'border-red-400' : 'border-[#b2dfd0]'"
               style="background:#f8fffe; color:#0D2B2A;" />
        <p v-if="errors.dataValidade" class="text-[10px] text-red-500 mt-0.5">{{ errors.dataValidade }}</p>
      </div>
      <div>
        <label class="block text-[10px] font-bold uppercase tracking-wide mb-1" style="color:#0F6E56;">
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.CANAL_LABEL') }}
        </label>
        <select v-model="form.canalVendaId" class="w-full px-3 py-1.5 text-sm rounded border border-[#b2dfd0]"
                style="background:#f8fffe; color:#0D2B2A;">
          <option value="">Selecionar...</option>
          <option v-for="c in canais" :key="c.id" :value="c.id">{{ c.nome }}</option>
        </select>
      </div>
      <div>
        <label class="block text-[10px] font-bold uppercase tracking-wide mb-1" style="color:#0F6E56;">
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.SINAL_LABEL') }} (%)
        </label>
        <input v-model.number="form.percentualSinal" type="number" min="0" max="100"
               class="w-full px-3 py-1.5 text-sm rounded border border-[#b2dfd0]"
               style="background:#f8fffe; color:#0D2B2A;" />
      </div>
      <div>
        <label class="block text-[10px] font-bold uppercase tracking-wide mb-1" style="color:#0F6E56;">
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.DISCOUNT_LABEL') }}
        </label>
        <input v-model.number="form.descontoManual" type="number" min="0"
               class="w-full px-3 py-1.5 text-sm rounded border border-[#b2dfd0]"
               style="background:#f8fffe; color:#0D2B2A;" />
      </div>
    </div>
    <div>
      <label class="block text-[10px] font-bold uppercase tracking-wide mb-1" style="color:#0F6E56;">
        {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.OBS_LABEL') }}
      </label>
      <textarea v-model="form.obsInternas" rows="2"
                class="w-full px-3 py-1.5 text-sm rounded border border-[#b2dfd0] resize-none"
                style="background:#f8fffe; color:#0D2B2A;" />
    </div>

    <div class="flex justify-end pt-2 border-t" style="border-color:#b2dfd0;">
      <button class="px-4 py-2 rounded text-sm font-bold text-white"
              style="background:#1D9E75;"
              @click="handleNext">
        {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.NEXT') }} →
      </button>
    </div>
  </div>
</template>
```

- [ ] **Step 3: Commit**

```bash
git add app/javascript/dashboard/components/widgets/conversation/viari/ViariOrcamentoModal.vue \
        app/javascript/dashboard/components/widgets/conversation/viari/ViariModalStep1.vue
git commit -m "feat(viari): add quote modal container and step 1 (general data)"
```

---

### Task 16: ViariModalStep2 — produtos, agendas, PAX e preços

**Files:**
- Create: `app/javascript/dashboard/components/widgets/conversation/viari/ViariModalStep2.vue`

- [ ] **Step 1: Criar ViariModalStep2**

Criar `app/javascript/dashboard/components/widgets/conversation/viari/ViariModalStep2.vue`:

```vue
<script setup>
import { ref, computed, onMounted } from 'vue'
import ViariAPI from 'dashboard/api/integrations/viari'

const props = defineProps({
  periodoInicio: { type: String, required: true },
  periodoFim: { type: String, required: true },
  canalVendaId: { type: String, default: '' },
  percentualSinal: { type: Number, default: 35 },
  descontoManual: { type: Number, default: 0 },
  initialItens: { type: Array, default: () => [] },
})
const emit = defineEmits(['next', 'back'])

const PAX_TYPES = ['ADT', 'CHD', 'INF', 'SEN', 'FREE']
const fmt = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' })

const produtos = ref([])
const itens = ref(props.initialItens.length ? props.initialItens : [newItem()])

function newItem() {
  return {
    produtoId: '',
    agendaId: '',
    agendas: [],
    tarifas: [],
    qtdAdt: 0, qtdChd: 0, qtdInf: 0, qtdSen: 0, qtdFree: 0,
  }
}

const addItem = () => itens.value.push(newItem())
const removeItem = (i) => itens.value.splice(i, 1)

const onProdutoChange = async (item) => {
  item.agendaId = ''
  item.agendas = []
  item.tarifas = []
  if (!item.produtoId) return
  try {
    const r = await ViariAPI.getAgendas(item.produtoId, props.periodoInicio, props.periodoFim)
    item.agendas = r.data.agendas ?? []
  } catch { item.agendas = [] }
}

const onAgendaChange = async (item) => {
  item.tarifas = []
  if (!item.agendaId) return
  const agenda = item.agendas.find((a) => a.id === item.agendaId)
  if (!agenda) return
  try {
    const r = await ViariAPI.getTarifas(item.produtoId, agenda.dataAgenda)
    item.tarifas = r.data.itens ?? []
  } catch { item.tarifas = [] }
}

const getPreco = (item, tipoPax) => {
  for (const itarifa of item.tarifas) {
    if (itarifa.precos[tipoPax] !== undefined) return itarifa.precos[tipoPax]
  }
  return null
}

const subtotal = (item) => {
  let s = 0
  for (const pax of PAX_TYPES) {
    const qtd = item[`qtd${pax.charAt(0) + pax.slice(1).toLowerCase()}`]
    const preco = getPreco(item, pax) ?? 0
    s += qtd * preco
  }
  return s
}

const totalCartao = computed(() =>
  itens.value.reduce((sum, item) => sum + subtotal(item), 0)
)
const totalPix = computed(() => totalCartao.value - props.descontoManual)
const valorSinal = computed(() =>
  Math.round(totalPix.value * (props.percentualSinal / 100) * 100) / 100
)
const acerto = computed(() => totalPix.value - valorSinal.value)

const handleNext = () => {
  const valid = itens.value.every((item) => item.produtoId && item.agendaId)
  if (!valid) return
  // Serializa itens com qtd por faixa no formato que o backend espera
  const payload = itens.value.map((item) => ({
    produtoId: item.produtoId,
    agendaId: item.agendaId,
    qtdAdt: item.qtdAdt,
    qtdChd: item.qtdChd,
    qtdInf: item.qtdInf,
    qtdSen: item.qtdSen,
    qtdFree: item.qtdFree,
  }))
  emit('next', payload)
}

onMounted(async () => {
  try {
    const r = await ViariAPI.getProdutos()
    produtos.value = r.data.produtos ?? []
  } catch { /* silencioso */ }
})
</script>

<template>
  <div class="p-5">
    <!-- Info período -->
    <div class="flex gap-4 text-[11px] px-3 py-2 rounded mb-3"
         style="background:#E1F5EE; color:#0F6E56;">
      <span>📅 <strong>Período:</strong> {{ periodoInicio }} – {{ periodoFim }}</span>
    </div>

    <div class="flex items-center justify-between mb-3">
      <span class="text-[11px] font-bold uppercase tracking-wide" style="color:#0F6E56;">
        Itens do orçamento
      </span>
      <button class="text-[10px] font-bold px-2 py-1 rounded text-white"
              style="background:#1D9E75;"
              @click="addItem">
        + Adicionar produto
      </button>
    </div>

    <div v-for="(item, i) in itens" :key="i"
         class="rounded-lg p-3 mb-3"
         style="border: 1px solid #b2dfd0; border-left: 3px solid #1D9E75; background:#f8fffe;">
      <div class="flex items-center justify-between mb-2">
        <span class="text-[10px] font-bold" style="color:#1D9E75;">ITEM {{ i + 1 }}</span>
        <button v-if="itens.length > 1"
                class="text-[10px] px-2 py-0.5 rounded"
                style="background:#fee2e2; color:#ef4444;"
                @click="removeItem(i)">
          ✕ remover
        </button>
      </div>

      <div class="grid grid-cols-2 gap-3 mb-3">
        <div>
          <label class="block text-[10px] font-bold uppercase mb-1" style="color:#0F6E56;">Produto</label>
          <select v-model="item.produtoId"
                  class="w-full px-2 py-1.5 text-[11px] rounded border border-[#b2dfd0]"
                  style="background:white; color:#0D2B2A;"
                  @change="onProdutoChange(item)">
            <option value="">Selecionar...</option>
            <option v-for="p in produtos" :key="p.id" :value="p.id">{{ p.nome }}</option>
          </select>
        </div>
        <div>
          <label class="block text-[10px] font-bold uppercase mb-1" style="color:#0F6E56;">Data / Agenda</label>
          <select v-model="item.agendaId"
                  class="w-full px-2 py-1.5 text-[11px] rounded border border-[#b2dfd0]"
                  style="background:white; color:#0D2B2A;"
                  :disabled="!item.produtoId"
                  @change="onAgendaChange(item)">
            <option value="">Selecionar...</option>
            <option v-for="a in item.agendas" :key="a.id" :value="a.id">
              {{ new Date(a.dataAgenda).toLocaleDateString('pt-BR', { timeZone: 'UTC' }) }}
              {{ a.horario ? '· ' + a.horario : '' }}
              · {{ a.vagasDisponiveis }} vagas
            </option>
          </select>
        </div>
      </div>

      <label class="block text-[10px] font-bold uppercase mb-1.5" style="color:#0F6E56;">PAX por faixa</label>
      <div class="grid grid-cols-5 gap-1.5">
        <div v-for="pax in PAX_TYPES" :key="pax" class="text-center">
          <div class="text-[9px] font-bold mb-1" style="color:#0F6E56;">{{ pax }}</div>
          <input
            v-model.number="item[`qtd${pax.charAt(0) + pax.slice(1).toLowerCase()}`]"
            type="number" min="0"
            class="w-full text-center px-1 py-1 text-[11px] rounded border border-[#b2dfd0]"
            style="background:white; color:#0D2B2A;"
          />
          <div v-if="getPreco(item, pax) !== null"
               class="text-[9px] mt-0.5" style="color:#94a3b8;">
            {{ fmt.format(getPreco(item, pax)) }}
          </div>
        </div>
      </div>

      <div class="text-right mt-2 text-[11px] font-bold" style="color:#1D9E75;">
        Subtotal: {{ fmt.format(subtotal(item)) }}
      </div>
    </div>

    <!-- Totals -->
    <div class="rounded-lg p-3 mt-2" style="background:#E1F5EE;">
      <div class="flex justify-between text-[11px] mb-1" style="color:#0F6E56;">
        <span>Total cartão</span><span>{{ fmt.format(totalCartao) }}</span>
      </div>
      <div class="flex justify-between text-[11px] mb-1 font-bold" style="color:#1D9E75;">
        <span>Total PIX</span><span>{{ fmt.format(totalPix) }}</span>
      </div>
      <div class="flex items-center gap-2 mt-1.5">
        <span class="text-[10px] font-bold px-2 py-0.5 rounded-full"
              style="background:#EF9F27; color:#0D2B2A;">
          Sinal ({{ percentualSinal }}%): {{ fmt.format(valorSinal) }}
        </span>
        <span class="text-[10px]" style="color:#0F6E56;">
          → Acerto: {{ fmt.format(acerto) }}
        </span>
      </div>
    </div>

    <div class="flex justify-between pt-3 border-t mt-3" style="border-color:#b2dfd0;">
      <button class="px-4 py-2 rounded text-sm font-bold border"
              style="border-color:#b2dfd0; color:#0F6E56;"
              @click="$emit('back')">
        ← Voltar
      </button>
      <button class="px-4 py-2 rounded text-sm font-bold text-white"
              style="background:#1D9E75;"
              @click="handleNext">
        Revisar →
      </button>
    </div>
  </div>
</template>
```

- [ ] **Step 2: Commit**

```bash
git add app/javascript/dashboard/components/widgets/conversation/viari/ViariModalStep2.vue
git commit -m "feat(viari): add quote modal step 2 (products, agendas, PAX, prices)"
```

---

### Task 17: ViariModalStep3 — revisão e cola texto WhatsApp

**Files:**
- Create: `app/javascript/dashboard/components/widgets/conversation/viari/ViariModalStep3.vue`

- [ ] **Step 1: Criar ViariModalStep3**

Criar `app/javascript/dashboard/components/widgets/conversation/viari/ViariModalStep3.vue`:

```vue
<script setup>
import { computed } from 'vue'
import Spinner from 'dashboard/components-next/spinner/Spinner.vue'

const props = defineProps({
  formData: { type: Object, required: true },
  contact: { type: Object, required: true },
  isCreating: { type: Boolean, default: false },
  error: { type: String, default: '' },
})
const emit = defineEmits(['confirm', 'back'])

const fmt = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' })
const fmtDate = (d) =>
  d ? new Date(d).toLocaleDateString('pt-BR', { timeZone: 'UTC', day: '2-digit', month: '2-digit', year: 'numeric' }) : ''

// Preview local do texto WhatsApp (calculado no frontend antes de criar)
// O texto definitivo vem do Viari — este é apenas para visualização
const previewTexto = computed(() => {
  const itens = props.formData.itens ?? []
  if (!itens.length) return ''

  const linhas = []
  return [
    `🏠 Orçamento dos passeios:`,
    `Nome: ${props.contact.name}`,
    `📞 Telefone: ${props.contact.phone_number ?? ''}`,
    ``,
    `[${itens.length} produto(s) selecionado(s)]`,
    ``,
    `💳 Cartão e PIX serão calculados pelo Viari.`,
    `Sinal: ${props.formData.percentualSinal}%`,
  ].join('\n')
})
</script>

<template>
  <div class="p-5">
    <!-- Resumo -->
    <div class="rounded-lg p-3 mb-4" style="background:#E1F5EE;">
      <div class="text-[10px] font-bold uppercase tracking-wide mb-2" style="color:#0F6E56;">
        Resumo
      </div>
      <div class="grid grid-cols-2 gap-x-4 gap-y-1 text-[11px]" style="color:#0D2B2A;">
        <div><strong>Período:</strong> {{ fmtDate(formData.periodoInicio) }} – {{ fmtDate(formData.periodoFim) }}</div>
        <div><strong>Validade:</strong> {{ fmtDate(formData.dataValidade) }}</div>
        <div><strong>Sinal:</strong> {{ formData.percentualSinal }}%</div>
        <div><strong>Desconto PIX:</strong> {{ fmt.format(formData.descontoManual) }}</div>
        <div><strong>Produtos:</strong> {{ formData.itens?.length ?? 0 }}</div>
      </div>
    </div>

    <!-- WhatsApp preview -->
    <div class="rounded-lg p-3" style="background:#0D2B2A;">
      <div class="text-[10px] font-bold uppercase tracking-wide mb-2 flex items-center gap-1.5"
           style="color:#5DCAA5;">
        📱 {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.WHATSAPP_PREVIEW') }}
      </div>
      <pre class="text-[11px] whitespace-pre-wrap font-mono"
           style="color:#E1F5EE; line-height:1.7;">{{ previewTexto }}</pre>
      <p class="text-[10px] mt-2" style="color:#5DCAA5; opacity:0.7;">
        ℹ️ O texto final com valores exatos será gerado pelo Viari ao confirmar.
      </p>
    </div>

    <p v-if="error" class="text-[11px] text-red-500 mt-3 text-center">
      {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.ERROR') }}
    </p>

    <div class="flex justify-between pt-3 border-t mt-4" style="border-color:#b2dfd0;">
      <button class="px-4 py-2 rounded text-sm font-bold border"
              style="border-color:#b2dfd0; color:#0F6E56;"
              :disabled="isCreating"
              @click="$emit('back')">
        ← Editar produtos
      </button>
      <button
        class="px-4 py-2 rounded text-sm font-bold text-white flex items-center gap-2"
        style="background:#25D366;"
        :disabled="isCreating"
        @click="$emit('confirm')"
      >
        <Spinner v-if="isCreating" size="14" class="text-white" />
        {{ isCreating
          ? $t('CONVERSATION_SIDEBAR.VIARI.MODAL.CREATING')
          : $t('CONVERSATION_SIDEBAR.VIARI.MODAL.CONFIRM') }}
      </button>
    </div>
  </div>
</template>
```

- [ ] **Step 2: Confirmar store de drafts**

```bash
grep -n "draftMessages" /Users/alexandre/Code/chatwoot-roteiros/app/javascript/dashboard/store/index.js | head -5
```

Saída esperada: `draftMessages` registrado como módulo do Vuex. O action usado em `ViariOrcamentoModal.vue` é `draftMessages/set` com `{ key: 'draft-{id}-REPLY', message: '...' }` — já está correto.

- [ ] **Step 3: Commit**

```bash
git add app/javascript/dashboard/components/widgets/conversation/viari/ViariModalStep3.vue
git commit -m "feat(viari): add quote modal step 3 (review + WhatsApp paste)"
```

---

## Verificação Final

- [ ] **Viari:** Subir o servidor de desenvolvimento (`npm run dev`) e acessar `http://localhost:3000`
- [ ] **Viari:** Testar endpoint `GET /api/viari/clientes/buscar?telefone=+5521999990000` com header `X-Viari-Api-Key: <key>` via curl/Insomnia
- [ ] **Chatwoot:** Rodar `bundle exec rails routes | grep viari` e confirmar que todas as rotas aparecem
- [ ] **Chatwoot:** Subir o servidor (`pnpm dev`) e navegar para Configurações → Integrações → Viari
- [ ] **Chatwoot:** Preencher URL + API Key e clicar em Conectar — verificar que o hook é criado
- [ ] **Chatwoot:** Abrir uma conversa — verificar que o painel Viari aparece no accordion lateral
- [ ] **Chatwoot:** Clicar em "+ Novo orçamento" — verificar que o modal abre
- [ ] **Chatwoot:** Percorrer as 3 etapas do modal e confirmar — verificar que o texto é colado na conversa

---

## Dependências entre Fases

```
Fase A (Viari API) → Fase B (Rails proxy + config) → Fase C (Sidebar) → Fase D (Modal)
```

As Fases A e B podem ser desenvolvidas em paralelo por pessoas diferentes, pois a Fase B só precisa da URL base para configurar o proxy — os testes reais dependem da Fase A estar rodando.
</content>
