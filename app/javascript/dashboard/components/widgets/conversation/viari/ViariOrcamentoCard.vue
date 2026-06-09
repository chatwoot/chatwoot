<script setup>
import { computed } from 'vue';

const props = defineProps({
  orcamento: { type: Object, required: true },
});

// Tailwind bg + text class pairs for each status badge
const STATUS_CLASSES = {
  rascunho: 'bg-slate-100 text-slate-400',
  enviado: 'bg-[#EF9F27]/10 text-[#EF9F27]',
  visualizado: 'bg-indigo-100 text-indigo-500',
  aprovado: 'bg-[#1D9E75]/10 text-[#1D9E75]',
  convertido: 'bg-[#0F6E56]/10 text-[#0F6E56]',
  recusado: 'bg-red-100 text-red-500',
  expirado: 'bg-slate-100 text-slate-400',
  cancelado: 'bg-red-100 text-red-500',
};

const fmt = new Intl.NumberFormat('pt-BR', {
  style: 'currency',
  currency: 'BRL',
});

const formatDate = d =>
  new Date(d).toLocaleDateString('pt-BR', {
    timeZone: 'UTC',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });

const statusClasses = computed(
  () => STATUS_CLASSES[props.orcamento.status] ?? 'bg-slate-100 text-slate-400'
);
</script>

<template>
  <div
    class="rounded-lg p-2.5 text-[11px] relative bg-[#f8fffe] border border-[#b2dfd0] border-l-[3px] border-l-[#EF9F27]"
  >
    <a
      :href="orcamento.urlViari"
      target="_blank"
      rel="noopener noreferrer"
      class="absolute top-2 right-2 text-[10px] text-[#1D9E75] opacity-50 hover:opacity-100"
      :title="$t('CONVERSATION_SIDEBAR.VIARI.OPEN_IN_VIARI')"
    >
      {{ $t('CONVERSATION_SIDEBAR.VIARI.OPEN_LINK_ICON') }}
    </a>
    <div class="font-bold pr-4 text-[#0D2B2A]">{{ orcamento.codigo }}</div>
    <div class="text-[#0F6E56]">
      {{ orcamento.itens }}
      {{ $t('CONVERSATION_SIDEBAR.VIARI.PRODUCTS_SUFFIX') }}
      {{ $t('CONVERSATION_SIDEBAR.VIARI.SEPARATOR') }}
      {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.VALIDITY_LABEL') }}
      {{ formatDate(orcamento.dataValidade) }}
    </div>
    <div class="flex justify-between items-center mt-1.5">
      <span
        class="text-[9px] px-1.5 py-0.5 rounded-full font-bold"
        :class="statusClasses"
      >
        {{ orcamento.status }}
      </span>
      <div class="text-right">
        <div class="font-bold text-[#0D2B2A]">
          {{ fmt.format(orcamento.totalCartao) }}
        </div>
        <div class="text-[9px] text-[#1D9E75]">
          {{ $t('CONVERSATION_SIDEBAR.VIARI.PIX_LABEL') }}
          {{ fmt.format(orcamento.totalPix) }}
        </div>
      </div>
    </div>
  </div>
</template>
