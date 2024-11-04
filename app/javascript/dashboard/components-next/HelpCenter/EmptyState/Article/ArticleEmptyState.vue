<script setup>
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ArticleCard from 'dashboard/components-next/HelpCenter/ArticleCard/ArticleCard.vue';
import articleContent from 'dashboard/components-next/HelpCenter/EmptyState/Portal/portalEmptyStateContent.js';

defineProps({
  title: {
    type: String,
    default: '',
  },
  subtitle: {
    type: String,
    default: '',
  },
  showButton: {
    type: Boolean,
    default: true,
  },
  buttonLabel: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['click']);

const onClick = () => {
  emit('click');
};
</script>

<template>
  <EmptyStateLayout :title="title" :subtitle="subtitle">
    <template #empty-state-item>
      <div class="grid grid-cols-1 gap-4 p-px overflow-hidden">
        <ArticleCard
          v-for="(article, index) in articleContent.slice(0, 5)"
          :id="article.id"
          :key="`article-${index}`"
          :title="article.title"
          :status="article.status"
          :updated-at="article.updatedAt"
          :author="article.author"
          :category="article.category"
          :views="article.views"
        />
      </div>
    </template>
    <template #actions>
      <div v-if="showButton">
        <Button :label="buttonLabel" icon="i-lucide-plus" @click="onClick" />
      </div>
    </template>
  </EmptyStateLayout>
</template>
