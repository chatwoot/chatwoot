<script setup>
import EmptyStateLayout from 'dashboard/playground/components/EmptyStateLayout.vue';
import ArticleCard from 'dashboard/playground/HelpCenter/ArticleCard.vue';
import CategoryCard from 'dashboard/playground/HelpCenter/CategoryCard.vue';
import LocaleCard from 'dashboard/playground/HelpCenter/LocaleCard.vue';
import ButtonV4 from 'dashboard/playground/components/Button.vue';

const articles = [
  {
    title: "How to get an SSL certificate for your Help Center's custom domain",
    status: 'draft',
    updatedAt: '2 days ago',
    author: 'Michael',
    category: '⚡️ Marketing',
    views: 3400,
  },
  {
    title: 'Setting up your first Help Center portal',
    status: '',
    updatedAt: '1 week ago',
    author: 'John',
    category: '🛠️ Development',
    views: 400,
  },
  {
    title: 'Best practices for organizing your Help Center content',
    status: 'archived',
    updatedAt: '3 days ago',
    author: 'Fernando',
    category: '💰 Finance',
    views: 400,
  },
  {
    title: 'Customizing the appearance of your Help Center',
    status: '',
    updatedAt: '5 days ago',
    author: 'Jane',
    category: '💰 Finance',
    views: 400,
  },
];

const categories = [
  {
    title: 'Getting Started',
    description: 'Essential guides for new users',
    articlesCount: '5',
  },
  {
    title: 'Advanced Features',
    description: 'In-depth tutorials for power users',
    articlesCount: '8',
  },
];

const locales = [
  { name: 'English', isDefault: true },
  { name: 'Spanish', isDefault: false },
  { name: 'Malayalam', isDefault: false },
];
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <EmptyStateLayout>
    <template #empty-state-item>
      <div class="grid grid-cols-2 gap-4">
        <div class="space-y-4">
          <ArticleCard
            v-for="(article, index) in articles"
            :key="`article-${index}`"
            :title="article.title"
            :status="article.status"
            :updated-at="article.updatedAt"
            :author="article.author"
            :category="article.category"
            :views="article.views"
          />
        </div>
        <div class="space-y-4">
          <CategoryCard
            v-for="(category, index) in categories"
            :key="`category-${index}`"
            :title="category.title"
            :description="category.description"
            :articles-count="category.articlesCount"
          />
          <LocaleCard
            v-for="(locale, index) in locales"
            :key="`locale-${index}`"
            :locale="locale.name"
            :is-default="locale.isDefault"
          />
        </div>
      </div>
    </template>
    <template #empty-state>
      <div class="flex flex-col items-center justify-center gap-6">
        <div class="flex flex-col items-center justify-center gap-2">
          <h2
            class="text-3xl font-medium text-center text-slate-900 dark:text-white"
          >
            Help Center
          </h2>
          <p
            class="max-w-lg text-base text-center text-slate-600 dark:text-slate-300"
          >
            Create self-service portals to access articles and information.
            Streamline queries, enhance agent efficiency, and elevate customer
            support.
          </p>
        </div>
        <ButtonV4 variant="default" label="Create Portal" icon="add" />
      </div>
    </template>
  </EmptyStateLayout>
</template>
