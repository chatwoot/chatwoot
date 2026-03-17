<script setup>
import ClientPanel from './conversation/ClientPanel.vue';

defineProps({
  contact: {
    type: Object,
    default: () => ({}),
  },
});
</script>

<template>
  <ClientPanel :contact="contact" />
</template>
