<script setup>
import ArticleEmptyState from './ArticleEmptyState.vue';
</script>

<template>
  <Story
    title="Components/HelpCenter/EmptyState/ArticleEmptyState"
    :layout="{ type: 'single', width: '1100px' }"
  >
    <Variant title="Article Empty State">
      <div class="w-full h-full px-20 mx-auto bg-white dark:bg-slate-900">
        <ArticleEmptyState />
      </div>
    </Variant>
  </Story>
</template>
