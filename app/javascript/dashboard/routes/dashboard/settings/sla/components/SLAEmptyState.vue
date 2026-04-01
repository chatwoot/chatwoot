<script setup>
import BaseEmptyState from './BaseEmptyState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['primaryAction']);
const primaryAction = () => emit('primaryAction');
</script>

<template>
  <BaseEmptyState>
    <p class="max-w-xs text-sm font-medium text-center">
      {{ $t('SLA.LIST.404') }}
    </p>
    <NextButton
      solid
      teal
      lg
      icon="i-lucide-plus"
      class="mt-4 rounded-xl font-bold shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.4)] active:scale-[0.98]"
      :label="$t('SLA.ADD_ACTION_LONG')"
      @click="primaryAction"
    />
  </BaseEmptyState>
</template>
