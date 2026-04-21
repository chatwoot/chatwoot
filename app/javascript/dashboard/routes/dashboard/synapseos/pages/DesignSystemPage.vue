<script setup>
import { ref } from 'vue';
import SynapseButton from 'next/synapseos/SynapseButton.vue';
import SynapseCard from 'next/synapseos/SynapseCard.vue';
import SynapseKpiCard from 'next/synapseos/SynapseKpiCard.vue';
import SynapseStatusPill from 'next/synapseos/SynapseStatusPill.vue';
import SynapseBadge from 'next/synapseos/SynapseBadge.vue';
import SynapseInput from 'next/synapseos/SynapseInput.vue';

const textField = ref('');
const emailField = ref('john@acme.inc');
const errorField = ref('abc');

const tokens = [
  { name: 's-bg', hex: '#F1F3F5', role: 'App background' },
  { name: 's-surface', hex: '#FFFFFF', role: 'Card background' },
  { name: 's-sidebar', hex: '#FAFBFC', role: 'Sidebar shell' },
  { name: 's-subtle', hex: '#F8FAFC', role: 'Row hover' },
  { name: 's-border', hex: '#E2E8F0', role: 'Default border' },
  { name: 's-primary', hex: '#0F172A', role: 'Text primary' },
  { name: 's-secondary', hex: '#475569', role: 'Text secondary' },
  { name: 's-muted', hex: '#64748B', role: 'Text muted (AA)' },
  { name: 's-brand', hex: '#2196F3', role: 'Brand accent / ícone' },
  { name: 's-brand-cta', hex: '#1E88E5', role: 'CTA sólido' },
  { name: 's-brand-soft', hex: '#E3F2FD', role: 'Chip / active bg' },
  { name: 's-success', hex: '#10B981', role: 'Success' },
  { name: 's-warning', hex: '#F59E0B', role: 'Warning' },
  { name: 's-error', hex: '#EF4444', role: 'Error' },
];
</script>

<template>
  <div class="bg-s-bg min-h-full p-8 space-y-10 overflow-auto">
    <header class="flex flex-col gap-2">
      <h1 class="text-3xl font-bold tracking-tight text-s-primary">Design System</h1>
      <p class="text-sm text-s-muted">
        Preview dos primitivos Synapse OS usados pelos sprints de refactor.
      </p>
    </header>

    <section>
      <h2 class="text-sm font-semibold text-s-secondary uppercase tracking-wider mb-4">
        Color tokens
      </h2>
      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
        <div
          v-for="t in tokens"
          :key="t.name"
          class="bg-s-surface border border-s-border rounded-xl p-3 flex items-center gap-3"
        >
          <span
            class="size-10 rounded-lg border border-s-border shrink-0"
            :style="{ backgroundColor: t.hex }"
          />
          <div class="flex flex-col min-w-0">
            <span class="text-xs font-medium text-s-primary truncate">{{ t.name }}</span>
            <span class="text-[11px] text-s-muted font-mono">{{ t.hex }}</span>
            <span class="text-[11px] text-s-muted truncate">{{ t.role }}</span>
          </div>
        </div>
      </div>
    </section>

    <section>
      <h2 class="text-sm font-semibold text-s-secondary uppercase tracking-wider mb-4">
        Typography
      </h2>
      <SynapseCard padding="loose">
        <div class="flex flex-col gap-4">
          <div class="flex flex-col gap-1">
            <span class="text-xs text-s-muted font-mono">display · 48/700</span>
            <span class="text-5xl font-bold tracking-tight text-s-primary">R$ 125.750</span>
          </div>
          <div class="flex flex-col gap-1">
            <span class="text-xs text-s-muted font-mono">h1 · 30/700</span>
            <span class="text-3xl font-bold tracking-tight text-s-primary">Executive Dashboard</span>
          </div>
          <div class="flex flex-col gap-1">
            <span class="text-xs text-s-muted font-mono">h2 · 24/600</span>
            <span class="text-2xl font-semibold text-s-primary">Pipeline de vendas</span>
          </div>
          <div class="flex flex-col gap-1">
            <span class="text-xs text-s-muted font-mono">h3 · 18/600</span>
            <span class="text-lg font-semibold text-s-primary">Atividade recente</span>
          </div>
          <div class="flex flex-col gap-1">
            <span class="text-xs text-s-muted font-mono">body · 14/400</span>
            <span class="text-sm text-s-secondary">Chatwoot fork branded para mercado BR.</span>
          </div>
          <div class="flex flex-col gap-1">
            <span class="text-xs text-s-muted font-mono">caption · 12/500</span>
            <span class="text-xs font-medium text-s-muted">Última atualização: há 3 min</span>
          </div>
          <div class="flex flex-col gap-1">
            <span class="text-xs text-s-muted font-mono">overline · 11/600 uppercase</span>
            <span class="text-[11px] font-semibold uppercase tracking-wider text-s-muted">
              Receita mensal
            </span>
          </div>
        </div>
      </SynapseCard>
    </section>

    <section>
      <h2 class="text-sm font-semibold text-s-secondary uppercase tracking-wider mb-4">Buttons</h2>
      <SynapseCard>
        <div class="flex flex-col gap-4">
          <div class="flex flex-wrap gap-3">
            <SynapseButton variant="primary" icon="i-lucide-plus">Novo Lead</SynapseButton>
            <SynapseButton variant="outline">Export</SynapseButton>
            <SynapseButton variant="ghost" icon="i-lucide-settings">Config</SynapseButton>
            <SynapseButton variant="danger" icon="i-lucide-trash-2">Excluir</SynapseButton>
            <SynapseButton variant="primary" loading>Salvando…</SynapseButton>
            <SynapseButton variant="primary" disabled>Desabilitado</SynapseButton>
          </div>
          <div class="flex items-end flex-wrap gap-3">
            <SynapseButton size="sm">Small</SynapseButton>
            <SynapseButton size="md">Medium</SynapseButton>
            <SynapseButton size="lg">Large</SynapseButton>
          </div>
        </div>
      </SynapseCard>
    </section>

    <section>
      <h2 class="text-sm font-semibold text-s-secondary uppercase tracking-wider mb-4">
        KPI cards
      </h2>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <SynapseKpiCard
          label="Leads novos"
          value="328"
          icon="i-lucide-target"
          tone="brand"
          :delta="15"
        />
        <SynapseKpiCard
          label="Win rate"
          value="76%"
          icon="i-lucide-trophy"
          tone="success"
          :delta="8.2"
        />
        <SynapseKpiCard
          label="Receita (30d)"
          value="R$ 125.750"
          icon="i-lucide-dollar-sign"
          tone="success"
          :delta="21"
        />
        <SynapseKpiCard
          label="Deals perdidos"
          value="12"
          icon="i-lucide-trending-down"
          tone="error"
          :delta="-3.4"
        />
      </div>
    </section>

    <section>
      <h2 class="text-sm font-semibold text-s-secondary uppercase tracking-wider mb-4">
        Status pills
      </h2>
      <SynapseCard>
        <div class="flex flex-wrap gap-2">
          <SynapseStatusPill tone="success">Ganho</SynapseStatusPill>
          <SynapseStatusPill tone="warning">Aguardando</SynapseStatusPill>
          <SynapseStatusPill tone="error">Perdido</SynapseStatusPill>
          <SynapseStatusPill tone="info">Em negociação</SynapseStatusPill>
          <SynapseStatusPill tone="brand">Qualificado</SynapseStatusPill>
          <SynapseStatusPill tone="neutral">Em pausa</SynapseStatusPill>
        </div>
        <div class="mt-3 flex flex-wrap gap-2">
          <SynapseBadge tone="brand">Novo</SynapseBadge>
          <SynapseBadge tone="success">Ativo</SynapseBadge>
          <SynapseBadge tone="warning">Expira em 3d</SynapseBadge>
          <SynapseBadge tone="error">Falhou</SynapseBadge>
          <SynapseBadge tone="neutral">Arquivado</SynapseBadge>
        </div>
      </SynapseCard>
    </section>

    <section>
      <h2 class="text-sm font-semibold text-s-secondary uppercase tracking-wider mb-4">Inputs</h2>
      <SynapseCard>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <SynapseInput
            v-model="textField"
            label="Nome"
            placeholder="Digite seu nome completo"
            hint="Como aparecerá nos e-mails"
            id="name-field"
          />
          <SynapseInput
            v-model="emailField"
            label="E-mail"
            type="email"
            icon-leading="i-lucide-mail"
            id="email-field"
          />
          <SynapseInput
            v-model="errorField"
            label="CEP"
            error="CEP inválido, verifique o formato"
            id="cep-field"
          />
          <SynapseInput
            label="Desabilitado"
            placeholder="Campo bloqueado"
            disabled
            id="disabled-field"
          />
        </div>
      </SynapseCard>
    </section>

    <section>
      <h2 class="text-sm font-semibold text-s-secondary uppercase tracking-wider mb-4">
        Card anatomy
      </h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <SynapseCard title="Card com título" subtitle="E um subtítulo descritivo">
          <template #actions>
            <SynapseButton variant="ghost" size="sm" icon="i-lucide-more-horizontal" />
          </template>
          <p class="text-sm text-s-secondary leading-relaxed">
            Padding default (p-6), border-s-border, rounded-2xl, shadow-s-sm → hover shadow-s-md.
            Usado em toda tela de entrada (Dashboard, Settings, Reports).
          </p>
          <template #footer>
            <div class="flex justify-end gap-2">
              <SynapseButton variant="outline" size="sm">Cancelar</SynapseButton>
              <SynapseButton size="sm">Salvar</SynapseButton>
            </div>
          </template>
        </SynapseCard>
        <SynapseCard interactive padding="tight">
          <div class="flex items-center gap-3">
            <span class="inline-flex size-10 rounded-lg bg-s-brand-soft items-center justify-center">
              <span class="i-lucide-zap size-5 text-s-brand" />
            </span>
            <div class="flex flex-col">
              <span class="text-sm font-semibold text-s-primary">Card interativo</span>
              <span class="text-xs text-s-muted">padding tight + hover shadow</span>
            </div>
          </div>
        </SynapseCard>
      </div>
    </section>
  </div>
</template>
