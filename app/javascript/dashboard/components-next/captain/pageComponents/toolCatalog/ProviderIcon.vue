<script setup>
import { computed } from 'vue';

const props = defineProps({
  providerKey: {
    type: String,
    required: true,
  },
  providerName: {
    type: String,
    required: true,
  },
});

const providerImages = {
  linear: '/dashboard/images/integrations/linear.png',
  shopify: '/dashboard/images/integrations/shopify.png',
  slack: '/dashboard/images/integrations/slack.png',
};

const image = computed(() => providerImages[props.providerKey]);
const initials = computed(() => props.providerName.slice(0, 2).toUpperCase());
</script>

<template>
  <div
    class="flex items-center justify-center size-10 overflow-hidden rounded-xl border border-n-weak bg-n-alpha-1 text-sm font-semibold text-n-slate-12 shrink-0"
  >
    <img
      v-if="image"
      :src="image"
      :alt="providerName"
      class="size-7 object-contain"
    />
    <span v-else aria-hidden="true">{{ initials }}</span>
  </div>
</template>
