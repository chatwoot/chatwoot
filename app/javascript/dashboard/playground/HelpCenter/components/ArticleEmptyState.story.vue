<script setup>
import ArticleEmptyState from './ArticleEmptyState.vue';
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story
    title="HelpCenter/ArticleEmptyState"
    :layout="{ type: 'grid', width: '100%' }"
  >
    <Variant title="Article Empty State">
      <ArticleEmptyState />
    </Variant>
  </Story>
</template>
