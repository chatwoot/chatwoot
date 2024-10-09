<script setup>
import AllArticlesPage from './AllArticlesPage.vue';
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story title="HelpCenter/AllArticlesPage" :layout="{ type: 'single' }">
    <Variant title="All Articles">
      <div class="w-full min-h-screen bg-white dark:bg-slate-900">
        <AllArticlesPage />
      </div>
    </Variant>
  </Story>
</template>
