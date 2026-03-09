<script setup>
import ArticleCard from './ArticleCard.vue';

const articles = [
  {
    id: 1,
    title: "How to get an SSL certificate for your Help Center's custom domain",
    status: 'draft',
    updatedAt: 1729048936,
    author: {
      name: 'John',
      thumbnail: 'https://i.pravatar.cc/300',
    },
    category: {
      title: 'Marketing',
      slug: 'marketing',
      icon: '📈',
    },
    views: 400,
  },
  {
    id: 2,
    title: 'Setting up your first Help Center portal',
    status: '',
    updatedAt: 1729048936,
    author: {
      name: 'John',
      thumbnail: 'https://i.pravatar.cc/300',
    },
    category: {
      title: 'Development',
      slug: 'development',
      icon: '🛠️',
    },
    views: 1400,
  },
  {
    id: 3,
    title: 'Best practices for organizing your Help Center content',
    status: 'archived',
    updatedAt: 1729048936,
    author: {
      name: 'Fernando',
      thumbnail: 'https://i.pravatar.cc/300',
    },
    category: {
      title: 'Finance',
      slug: 'finance',
      icon: '💰',
    },
    views: 4300,
  },
];

const category = {
  name: 'Marketing',
  slug: 'marketing',
  icon: '📈',
};
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
          :id="article.id"
          :title="article.title"
          :status="article.status"
          :author="article.author"
          :category="category"
          :views="article.views"
          :updated-at="article.updatedAt"
        />
      </div>
    </Variant>
  </Story>
</template>
