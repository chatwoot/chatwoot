<script setup>
import AllLocalesPage from './AllLocalesPage.vue';
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story
    title="HelpCenter/AllLocalesPage"
    :layout="{ type: 'single', width: '100%' }"
  >
    <Variant title="All Locales">
      <AllLocalesPage />
    </Variant>
  </Story>
</template>
