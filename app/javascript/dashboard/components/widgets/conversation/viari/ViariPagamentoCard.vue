<script setup>
defineProps({
  pagamento: { type: Object, required: true },
});

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
</script>

<template>
  <div
    class="rounded-lg p-2.5 text-[11px] relative bg-[#f8fffe] border border-[#b2dfd0] border-l-[3px] border-l-[#5DCAA5]"
  >
    <a
      :href="pagamento.urlViari"
      target="_blank"
      rel="noopener noreferrer"
      class="absolute top-2 right-2 text-[10px] text-[#1D9E75] opacity-50 hover:opacity-100"
      :title="$t('CONVERSATION_SIDEBAR.VIARI.OPEN_IN_VIARI')"
    >
      {{ $t('CONVERSATION_SIDEBAR.VIARI.OPEN_LINK_ICON') }}
    </a>
    <div class="font-bold pr-4 text-[#0D2B2A]">
      {{ pagamento.formaPagamento }}
    </div>
    <div class="text-[#0F6E56]">
      {{ formatDate(pagamento.data)
      }}{{ $t('CONVERSATION_SIDEBAR.VIARI.SEPARATOR')
      }}{{ pagamento.reservaCodigo }}
    </div>
    <div class="flex justify-between items-center mt-1.5">
      <span
        class="text-[9px] px-1.5 py-0.5 rounded-full font-bold bg-[#E1F5EE] text-[#0F6E56]"
      >
        {{ pagamento.status }}
      </span>
      <span class="font-bold text-[#1D9E75]">{{
        fmt.format(pagamento.valor)
      }}</span>
    </div>
  </div>
</template>
