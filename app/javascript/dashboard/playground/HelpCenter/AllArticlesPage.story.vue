<script setup>
import AllArticlesPage from './AllArticlesPage.vue';
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story
    title="HelpCenter/AllArticlesPage"
    :layout="{ type: 'single', width: '100%' }"
  >
    <Variant title="All Articles">
      <AllArticlesPage />
    </Variant>
  </Story>
</template>
