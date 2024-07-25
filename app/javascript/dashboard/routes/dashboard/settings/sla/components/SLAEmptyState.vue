<script setup>
import BaseEmptyState from './BaseEmptyState.vue';

const emit = defineEmits(['primaryAction']);
const primaryAction = () => emit('primaryAction');
</script>

<template>
  <BaseEmptyState>
    <p class="max-w-xs text-sm font-medium text-center">
      {{ $t('SLA.LIST.404') }}
    </p>
    <woot-button
      color-scheme="primary"
      icon="plus-sign"
      class="px-5 mt-4 rounded-xl"
      @click="primaryAction"
    >
      {{ $t('SLA.ADD_ACTION_LONG') }}
    </woot-button>
  </BaseEmptyState>
</template>
