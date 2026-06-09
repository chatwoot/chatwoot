<script setup>
import { computed } from 'vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  formData: { type: Object, required: true },
  isCreating: { type: Boolean, default: false },
  createError: { type: String, default: '' },
});
const emit = defineEmits(['confirm', 'back']);

const fmt = new Intl.NumberFormat('pt-BR', {
  style: 'currency',
  currency: 'BRL',
});

const fmtDate = d =>
  d
    ? new Date(d + 'T00:00:00').toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
      })
    : '';

const periodRange = computed(
  () =>
    `${fmtDate(props.formData.periodoInicio)} - ${fmtDate(props.formData.periodoFim)}`
);

const validityValue = computed(() => fmtDate(props.formData.dataValidade));

const sinalValue = computed(() => `${props.formData.percentualSinal}%`);

const descontoValue = computed(() => fmt.format(props.formData.descontoManual));

const productCount = computed(() => props.formData.itens?.length ?? 0);

const previewTexto = computed(() => {
  const itens = props.formData.itens ?? [];
  const pax = itens.reduce(
    (sum, item) =>
      sum +
      item.qtdAdt +
      item.qtdChd +
      item.qtdInf +
      item.qtdSen +
      item.qtdFree,
    0
  );
  return [
    `${itens.length} produto(s) • ${pax} pax`,
    `Período: ${fmtDate(props.formData.periodoInicio)} – ${fmtDate(props.formData.periodoFim)}`,
    `Sinal: ${props.formData.percentualSinal}%`,
  ].join('\n');
});
</script>

<template>
  <div class="p-5 space-y-4">
    <!-- Summary card -->
    <div class="rounded-lg p-3 bg-[#E1F5EE]">
      <div
        class="text-[10px] font-bold uppercase tracking-wide mb-2 text-[#0F6E56]"
      >
        {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.SUMMARY') }}
      </div>
      <div class="grid grid-cols-2 gap-x-4 gap-y-1 text-[11px] text-[#0D2B2A]">
        <div>
          <span class="font-bold">{{
            $t('CONVERSATION_SIDEBAR.VIARI.MODAL.PERIOD_LABEL')
          }}</span>
          {{ periodRange }}
        </div>
        <div>
          <span class="font-bold">{{
            $t('CONVERSATION_SIDEBAR.VIARI.MODAL.VALIDITY_LABEL')
          }}</span>
          {{ validityValue }}
        </div>
        <div>
          <span class="font-bold">{{
            $t('CONVERSATION_SIDEBAR.VIARI.MODAL.SINAL_LABEL')
          }}</span>
          {{ sinalValue }}
        </div>
        <div>
          <span class="font-bold">{{
            $t('CONVERSATION_SIDEBAR.VIARI.MODAL.DISCOUNT_DISPLAY')
          }}</span>
          {{ descontoValue }}
        </div>
        <div>
          <span class="font-bold">{{
            $t('CONVERSATION_SIDEBAR.VIARI.MODAL.PRODUCTS_COUNT')
          }}</span>
          {{ productCount }}
        </div>
      </div>
    </div>

    <!-- WhatsApp preview card -->
    <div class="rounded-lg p-3 bg-[#0D2B2A]">
      <div
        class="text-[10px] font-bold uppercase tracking-wide mb-2 text-[#5DCAA5]"
      >
        {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.WHATSAPP_PREVIEW') }}
      </div>
      <pre
        class="text-[11px] whitespace-pre-wrap font-mono text-[#E1F5EE] leading-relaxed"
      >
        {{ previewTexto }}
      </pre>
      <p class="text-[10px] mt-2 text-[#5DCAA5] opacity-70">
        {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.WHATSAPP_NOTE') }}
      </p>
    </div>

    <!-- Error -->
    <p v-if="createError" class="text-[11px] text-red-500 text-center">
      {{ createError }}
    </p>

    <!-- Buttons -->
    <div class="flex justify-between pt-3 border-t border-[#b2dfd0]">
      <button
        class="px-4 py-2 rounded text-sm font-bold border border-[#b2dfd0] text-[#0F6E56]"
        :disabled="isCreating"
        @click="emit('back')"
      >
        {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.BACK') }}
      </button>
      <button
        class="px-4 py-2 rounded text-sm font-bold text-white bg-[#25D366] flex items-center gap-2 disabled:opacity-50"
        :disabled="isCreating"
        @click="emit('confirm')"
      >
        <Spinner v-if="isCreating" :size="14" class="text-white" />
        {{
          isCreating
            ? $t('CONVERSATION_SIDEBAR.VIARI.MODAL.CREATING')
            : $t('CONVERSATION_SIDEBAR.VIARI.MODAL.CONFIRM')
        }}
      </button>
    </div>
  </div>
</template>
