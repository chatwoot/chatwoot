<script setup>
import ArticleEmptyState from './ArticleEmptyState.vue';
</script>

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

<script>
export default {
  parameters: {
    layout: 'fullscreen',
  },
};
</script>
