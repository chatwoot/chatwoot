<script setup>
import BillingHeader from './BillingHeader.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div
    class="rounded-xl border border-outline-variant/15 bg-surface-container shadow-[0_2px_8px_rgba(5,20,39,0.4)] py-5 space-y-5"
  >
    <BillingHeader :title :description class="px-5">
      <slot name="action" />
    </BillingHeader>
    <slot />
  </div>
</template>
