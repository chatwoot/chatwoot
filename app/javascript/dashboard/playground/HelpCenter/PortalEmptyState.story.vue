<script setup>
import PortalEmptyState from './PortalEmptyState.vue';
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
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
