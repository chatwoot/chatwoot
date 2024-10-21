<script setup>
import ArticleCard from 'dashboard/components-next/HelpCenter/ArticleCard/ArticleCard.vue';

defineProps({
  articles: {
    type: Array,
    required: true,
  },
});
</script>

<template>
  <ul role="list" class="w-full h-full space-y-4">
    <ArticleCard
      v-for="article in articles"
      :key="article.title"
      :title="article.title"
      :status="article.status"
      :author="article.author"
      :category="article.category"
      :views="article.views"
      :updated-at="article.updatedAt"
    />
  </ul>
</template>
