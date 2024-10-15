<script setup>
import CategoriesPage from './CategoriesPage.vue';

const categories = [
  {
    id: 'getting-started',
    title: '🚀 Getting started',
    description:
      'Learn how to use Chatwoot effectively and make the most of its features to enhance customer support and engagement.',
    articlesCount: '2',
    articles: [
      {
        variant: 'Draft article',
        title:
          "How to get an SSL certificate for your Help Center's custom domain",
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
    ],
  },
  {
    id: 'marketing',
    title: 'Marketing',
    description:
      'Learn how to use Chatwoot effectively and make the most of its features to enhance customer support.',
    articlesCount: '4',
    articles: [
      {
        variant: 'Draft article',
        title:
          "How to get an SSL certificate for your Help Center's custom domain",
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
    ],
  },
  {
    id: 'development',
    title: 'Development',
    description: '',
    articlesCount: '5',
    articles: [
      {
        variant: 'Draft article',
        title:
          "How to get an SSL certificate for your Help Center's custom domain",
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
    ],
  },
  {
    id: 'roadmap',
    title: '🛣️ Roadmap',
    description:
      'Learn how to use Chatwoot effectively and make the most of its features to enhance customer support and engagement.',
    articlesCount: '3',
    articles: [
      {
        variant: 'Draft article',
        title:
          "How to get an SSL certificate for your Help Center's custom domain",
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
        variant: 'Published article',
        title: 'Setting up your first Help Center portal',
        status: '',
        updatedAt: '1 week ago',
        author: 'John',
        category: '🛠️ Development',
        views: 400,
      },
    ],
  },
  {
    id: 'finance',
    title: '💰 Finance',
    description:
      'Learn how to use Chatwoot effectively and make the most of its features to enhance customer support and engagement.',
    articlesCount: '2',
    articles: [
      {
        variant: 'Draft article',
        title:
          "How to get an SSL certificate for your Help Center's custom domain",
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
    ],
  },
];
</script>

<template>
  <Story title="Pages/HelpCenter/CategoryPage" :layout="{ type: 'single' }">
    <Variant title="All Categories">
      <div class="w-full min-h-screen bg-white dark:bg-slate-900">
        <CategoriesPage :categories="categories" />
      </div>
    </Variant>
  </Story>
</template>
