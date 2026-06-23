<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  status: { type: String, default: 'contato' },
});

const { t } = useI18n();

const steps = computed(() => [
  { key: 'contato', label: t('CONVERSATION_SIDEBAR.VIARI.JOURNEY.CONTATO') },
  {
    key: 'orcamento',
    label: t('CONVERSATION_SIDEBAR.VIARI.JOURNEY.ORCAMENTO'),
  },
  { key: 'sinal', label: t('CONVERSATION_SIDEBAR.VIARI.JOURNEY.SINAL') },
  { key: 'reserva', label: t('CONVERSATION_SIDEBAR.VIARI.JOURNEY.RESERVA') },
  { key: 'embarque', label: t('CONVERSATION_SIDEBAR.VIARI.JOURNEY.EMBARQUE') },
]);

const currentIndex = computed(() =>
  steps.value.findIndex(s => s.key === props.status)
);

const getState = index => {
  if (index < currentIndex.value) return 'done';
  if (index === currentIndex.value) return 'current';
  return 'todo';
};
</script>

<template>
  <div class="px-3 pt-2 pb-1 bg-[#E1F5EE]">
    <div
      class="text-[9px] font-bold uppercase tracking-wider mb-1.5 text-[#0F6E56]"
    >
      {{ $t('CONVERSATION_SIDEBAR.VIARI.JOURNEY_BAR.TITLE') }}
    </div>
    <div class="flex items-center">
      <template v-for="(step, i) in steps" :key="step.key">
        <div class="flex flex-col items-center">
          <!-- Dot -->
          <div
            class="w-5 h-5 rounded-full flex items-center justify-center text-[9px] font-bold"
            :class="{
              'bg-[#1D9E75] text-white': getState(i) === 'done',
              'bg-[#EF9F27] text-white ring-2 ring-[#EF9F27]/30':
                getState(i) === 'current',
              'bg-[#5DCAA5] text-[#0D2B2A] opacity-40': getState(i) === 'todo',
            }"
          >
            {{ getState(i) === 'done' ? '✓' : '●' }}
          </div>
          <!-- Label -->
          <div
            class="text-[8px] mt-0.5 text-center whitespace-nowrap"
            :class="{
              'font-bold text-[#EF9F27]': getState(i) === 'current',
              'font-semibold text-[#0F6E56]': getState(i) !== 'current',
            }"
          >
            {{ step.label }}
          </div>
        </div>
        <!-- Connector line between steps -->
        <div
          v-if="i < steps.length - 1"
          class="flex-1 h-0.5 mb-3"
          :class="{
            'bg-[#1D9E75]': i < currentIndex,
            'bg-[#5DCAA5] opacity-30': i >= currentIndex,
          }"
        />
      </template>
    </div>
  </div>
</template>
