<script setup>
import { computed } from 'vue';

const props = defineProps({
  reserva: { type: Object, required: true },
});

// Tailwind bg + text class pairs for each status badge
const STATUS_CLASSES = {
  confirmada: 'bg-[#1D9E75]/10 text-[#1D9E75]',
  pendente: 'bg-[#EF9F27]/10 text-[#EF9F27]',
  checkin: 'bg-indigo-100 text-indigo-500',
  concluida: 'bg-[#0F6E56]/10 text-[#0F6E56]',
  cancelada: 'bg-red-100 text-red-500',
  noshow: 'bg-slate-100 text-slate-400',
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

const paxLabel = computed(() => {
  const parts = [];
  if (props.reserva.pax.adt) parts.push(`${props.reserva.pax.adt} ADT`);
  if (props.reserva.pax.chd) parts.push(`${props.reserva.pax.chd} CHD`);
  if (props.reserva.pax.inf) parts.push(`${props.reserva.pax.inf} INF`);
  if (props.reserva.pax.sen) parts.push(`${props.reserva.pax.sen} SEN`);
  return parts.join(' + ');
});

const statusClasses = computed(
  () => STATUS_CLASSES[props.reserva.status] ?? 'bg-slate-100 text-slate-400'
);
</script>

<template>
  <div
    class="rounded-lg p-2.5 text-[11px] relative bg-[#f8fffe] border border-[#b2dfd0] border-l-[3px] border-l-[#1D9E75]"
  >
    <!-- External link -->
    <a
      :href="reserva.urlViari"
      target="_blank"
      rel="noopener noreferrer"
      class="absolute top-2 right-2 text-[10px] text-[#1D9E75] opacity-50 hover:opacity-100"
      :title="$t('CONVERSATION_SIDEBAR.VIARI.OPEN_IN_VIARI')"
    >
      {{ $t('CONVERSATION_SIDEBAR.VIARI.OPEN_LINK_ICON') }}
    </a>

    <div class="font-bold pr-4 text-[#0D2B2A]">{{ reserva.produto }}</div>
    <div class="mt-0.5 text-[#0F6E56]">
      {{ formatDate(reserva.dataAgenda)
      }}<template v-if="reserva.horario">
        {{ $t('CONVERSATION_SIDEBAR.VIARI.SEPARATOR') }}{{ reserva.horario }}
      </template>
      <template v-if="paxLabel">
        {{ $t('CONVERSATION_SIDEBAR.VIARI.SEPARATOR') }}{{ paxLabel }}
      </template>
    </div>
    <div class="flex justify-between items-center mt-1.5">
      <span
        class="text-[9px] px-1.5 py-0.5 rounded-full font-bold"
        :class="statusClasses"
      >
        {{ reserva.status }}
      </span>
      <span class="font-bold text-[#0D2B2A]">{{
        fmt.format(reserva.valorTotal)
      }}</span>
    </div>
  </div>
</template>
