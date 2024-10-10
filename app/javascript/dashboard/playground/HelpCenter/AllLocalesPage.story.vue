<script setup>
import AllLocalesPage from './AllLocalesPage.vue';
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story title="HelpCenter/AllLocalesPage" :layout="{ type: 'single' }">
    <Variant title="All Locales">
      <div class="w-full min-h-screen bg-white dark:bg-slate-900">
        <AllLocalesPage />
      </div>
    </Variant>
  </Story>
</template>
