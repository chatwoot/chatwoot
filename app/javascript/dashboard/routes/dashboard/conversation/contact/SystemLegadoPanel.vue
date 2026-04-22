<script setup>
// CUSTOMIZAÇÃO_SYNAPSEOS: painel lateral "Dados do Sistema Legado"
// renderiza os 3 atributos customizados populados pelas integrações Syonet/NBS.
import { computed } from 'vue';

const props = defineProps({
  contact: {
    type: Object,
    default: () => ({}),
  },
});

const customAttributes = computed(() => props.contact?.custom_attributes || {});

const ultimaRevisaoRaw = computed(() => customAttributes.value.ultima_revisao);
const carroAtualRaw = computed(() => customAttributes.value.carro_atual);
const propensaoTrocaRaw = computed(() => customAttributes.value.propensao_troca);

const formatDate = value => {
  if (!value) return '';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value);
  const day = String(date.getDate()).padStart(2, '0');
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const year = date.getFullYear();
  return `${day}/${month}/${year}`;
};

const formatPercent = value => {
  if (value === null || value === undefined || value === '') return '';
  const num = Number(value);
  if (Number.isNaN(num)) return String(value);
  return `${num}%`;
};

const ultimaRevisao = computed(() => formatDate(ultimaRevisaoRaw.value));
const carroAtual = computed(() => carroAtualRaw.value || '');
const propensaoTroca = computed(() => formatPercent(propensaoTrocaRaw.value));

const hasAnyValue = computed(
  () => !!ultimaRevisao.value || !!carroAtual.value || !!propensaoTroca.value
);
</script>

<template>
  <section
    class="flex flex-col gap-3 p-4 mx-2 mb-3 border rounded-lg bg-s-surface border-s-border"
  >
    <header class="flex items-center gap-2">
      <span class="i-lucide-database text-s-brand text-base" />
      <h4 class="m-0 text-sm font-medium text-s-primary">
        {{ $t('CONVERSATION_SIDEBAR.SYSTEM_LEGADO.TITLE') }}
      </h4>
    </header>
    <div v-if="hasAnyValue" class="flex flex-col gap-2">
      <div class="flex items-center justify-between gap-3">
        <span class="text-xs text-s-muted">
          {{ $t('CONVERSATION_SIDEBAR.SYSTEM_LEGADO.ULTIMA_REVISAO') }}
        </span>
        <span class="text-sm font-semibold text-s-primary text-right truncate">
          {{ ultimaRevisao || '—' }}
        </span>
      </div>
      <div class="flex items-center justify-between gap-3">
        <span class="text-xs text-s-muted">
          {{ $t('CONVERSATION_SIDEBAR.SYSTEM_LEGADO.CARRO_ATUAL') }}
        </span>
        <span class="text-sm font-semibold text-s-primary text-right truncate">
          {{ carroAtual || '—' }}
        </span>
      </div>
      <div class="flex items-center justify-between gap-3">
        <span class="text-xs text-s-muted">
          {{ $t('CONVERSATION_SIDEBAR.SYSTEM_LEGADO.PROPENSAO_TROCA') }}
        </span>
        <span class="text-sm font-semibold text-s-primary text-right truncate">
          {{ propensaoTroca || '—' }}
        </span>
      </div>
    </div>
    <p v-else class="m-0 text-xs text-s-muted">
      {{ $t('CONVERSATION_SIDEBAR.SYSTEM_LEGADO.EMPTY') }}
    </p>
  </section>
</template>
