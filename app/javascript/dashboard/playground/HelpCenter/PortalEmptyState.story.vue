<script setup>
import { ref } from 'vue';
import PortalEmptyState from './PortalEmptyState.vue';
</script>

<template>
  <Story
    title="HelpCenter/PortalEmptyState"
    :layout="{ type: 'grid', width: '100%' }"
  >
    <Variant title="Portal Empty State with dialog">
      <PortalEmptyState />
    </Variant>
  </Story>
</template>

<script>
export default {
  parameters: {
    layout: 'fullscreen',
  },
};
</script>
