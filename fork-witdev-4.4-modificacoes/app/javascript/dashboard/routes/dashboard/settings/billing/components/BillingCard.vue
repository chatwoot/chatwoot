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
    class="rounded-xl shadow-sm border border-n-weak bg-n-solid-2 py-5 space-y-5"
  >
    <BillingHeader :title :description class="px-5">
      <slot name="action" />
    </BillingHeader>
    <slot />
  </div>
</template>
