<script setup>
import ArticleCard from './ArticleCard.vue';

defineProps({
  articles: {
    type: Array,
    required: true,
  },
});
</script>

<template>
  <ul role="list" class="w-full h-full min-h-screen pt-6 space-y-4">
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
