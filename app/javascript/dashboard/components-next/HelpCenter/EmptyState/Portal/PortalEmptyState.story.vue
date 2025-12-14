<script setup>
import PortalEmptyState from './PortalEmptyState.vue';
</script>

<template>
  <Story
    title="Components/HelpCenter/EmptyState/PortalEmptyState"
    :layout="{ type: 'single', width: '1100px' }"
  >
    <Variant title="Portal Empty State">
      <div class="w-full h-full px-20 mx-auto bg-n-background">
        <PortalEmptyState />
      </div>
    </Variant>
  </Story>
</template>
