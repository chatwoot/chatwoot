<script setup>
import PortalEmptyState from './PortalEmptyState.vue';
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story
    title="Components/HelpCenter/EmptyState/PortalEmptyState"
    :layout="{ type: 'single', width: '1100px' }"
  >
    <Variant title="Portal Empty State">
      <div class="w-full h-full px-20 mx-auto bg-white dark:bg-slate-900">
        <PortalEmptyState />
      </div>
    </Variant>
  </Story>
</template>
