<script setup>
import ArticleCard from './ArticleCard.vue';

const articles = [
  {
    variant: 'Draft article',
    title: "How to get an SSL certificate for your Help Center's custom domain",
    status: 'draft',
    updatedAt: '2 days ago',
    author: 'Michael',
    category: '⚡️ Marketing',
    views: 3400,
  },
  {
    variant: 'Published article',
    title: 'Setting up your first Help Center portal',
    status: '',
    updatedAt: '1 week ago',
    author: 'John',
    category: '🛠️ Development',
    views: 400,
  },
  {
    variant: 'Archived article',
    title: 'Best practices for organizing your Help Center content',
    status: 'archived',
    updatedAt: '3 days ago',
    author: 'Fernando',
    category: '💰 Finance',
    views: 400,
  },
  {
    variant: 'Published article',
    title: 'Customizing the appearance of your Help Center',
    status: '',
    updatedAt: '5 days ago',
    author: 'Jane',
    category: '💰 Finance',
    views: 400,
  },
];
</script>

<template>
  <Story
    title="HelpCenter/ArticleCard"
    :layout="{ type: 'grid', width: '500px' }"
  >
    <Variant
      v-for="(article, index) in articles"
      :key="index"
      :title="article.variant"
    >
      <ArticleCard
        :title="article.title"
        :status="article.status"
        :author="article.author"
        :category="article.category"
        :views="article.views"
        :updated-at="article.updatedAt"
      />
    </Variant>
  </Story>
</template>
