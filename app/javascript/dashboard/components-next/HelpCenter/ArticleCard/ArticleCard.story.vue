<script setup>
import ArticleCard from './ArticleCard.vue';

const articles = [
  {
    title: "How to get an SSL certificate for your Help Center's custom domain",
    status: 'draft',
    updatedAt: '2 days ago',
    author: 'Michael',
    category: '⚡️ Marketing',
    views: 400,
  },
  {
    title: 'Setting up your first Help Center portal',
    status: '',
    updatedAt: '1 week ago',
    author: 'John',
    category: '🛠️ Development',
    views: 1400,
  },
  {
    title: 'Best practices for organizing your Help Center content',
    status: 'archived',
    updatedAt: '3 days ago',
    author: 'Fernando',
    category: '💰 Finance',
    views: 4300,
  },
];
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story
    title="Components/HelpCenter/ArticleCard"
    :layout="{ type: 'grid', width: '700px' }"
  >
    <Variant title="Article Card">
      <div
        v-for="(article, index) in articles"
        :key="index"
        class="px-20 py-4 bg-white dark:bg-slate-900"
      >
        <ArticleCard
          :title="article.title"
          :status="article.status"
          :author="article.author"
          :category="article.category"
          :views="article.views"
          :updated-at="article.updatedAt"
        />
      </div>
    </Variant>
  </Story>
</template>
