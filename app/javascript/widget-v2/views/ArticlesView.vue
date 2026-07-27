<script setup>
import { onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useArticlesStore } from 'widget-v2/stores/articles';
import WidgetHeader from 'widget-v2/components/WidgetHeader.vue';
import ArticleCard from 'widget-v2/components/ArticleCard.vue';
import EmptyState from 'widget-v2/components/EmptyState.vue';
import BaseSpinner from 'widget-v2/components/base/BaseSpinner.vue';

const router = useRouter();
const articlesStore = useArticlesStore();

const query = ref('');
let debounceTimer = null;

const onSearch = () => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => articlesStore.search(query.value), 300);
};

onMounted(() => {
  if (!articlesStore.articles.length) articlesStore.search('');
});

const openArticle = article =>
  router.push({ name: 'help-article', params: { slug: article.slug } });
</script>

<template>
  <div class="flex flex-col h-full bg-cw-background">
    <WidgetHeader :title="$t('HELP.TITLE')" />

    <div class="px-4 py-3 border-b border-cw-border">
      <label
        class="flex items-center gap-2 h-10 px-3 rounded-token-sm bg-cw-muted transition-shadow focus-within:ring-2 focus-within:ring-cw-primary"
      >
        <span class="i-lucide-search text-cw-text-faint" />
        <input
          v-model="query"
          type="search"
          :placeholder="$t('HELP.SEARCH_PLACEHOLDER')"
          class="flex-1 text-sm bg-transparent text-cw-text placeholder:text-cw-text-faint outline-none border-none"
          @input="onSearch"
        />
      </label>
    </div>

    <div class="flex-1 overflow-y-auto scrollbar-thin">
      <div v-if="articlesStore.loading" class="flex justify-center py-8">
        <BaseSpinner />
      </div>
      <template v-else-if="articlesStore.articles.length">
        <ArticleCard
          v-for="article in articlesStore.articles"
          :key="article.id"
          :article="article"
          class="border-b border-cw-border last:border-b-0"
          @click="openArticle(article)"
        />
      </template>
      <EmptyState
        v-else
        icon="i-lucide-book-open"
        :title="$t('HELP.NO_RESULTS_TITLE')"
        :description="$t('HELP.NO_RESULTS_DESCRIPTION')"
      />
    </div>
  </div>
</template>
