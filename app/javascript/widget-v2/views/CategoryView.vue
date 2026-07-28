<script setup>
import { computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useArticlesStore } from 'widget-v2/stores/articles';
import WidgetHeader from 'widget-v2/components/WidgetHeader.vue';
import ArticleCard from 'widget-v2/components/ArticleCard.vue';
import EmptyState from 'widget-v2/components/EmptyState.vue';
import BaseSpinner from 'widget-v2/components/base/BaseSpinner.vue';

const route = useRoute();
const router = useRouter();
const articlesStore = useArticlesStore();

const category = computed(() =>
  articlesStore.categories.find(item => item.slug === route.params.categorySlug)
);

const section = computed(() =>
  articlesStore.groupedArticles.find(
    item => item.category?.slug === route.params.categorySlug
  )
);

onMounted(() => {
  articlesStore.loadCategories();
  if (!articlesStore.articles.length) articlesStore.search('');
});

const openArticle = article =>
  router.push({ name: 'help-article', params: { slug: article.slug } });
</script>

<template>
  <div class="flex flex-col h-full bg-cw-solid">
    <WidgetHeader
      :title="category?.name || $t('HELP.TITLE')"
      :subtitle="category?.description"
      show-back
    />

    <div class="flex-1 overflow-y-auto scrollbar-thin">
      <div v-if="articlesStore.loading" class="flex justify-center py-8">
        <BaseSpinner />
      </div>
      <template v-else-if="section?.articles.length">
        <ArticleCard
          v-for="article in section.articles"
          :key="article.id"
          :article="article"
          class="border-b border-cw-hairline last:border-b-0"
          @click="openArticle(article)"
        />
      </template>
      <EmptyState
        v-else
        icon="i-ph-book-open"
        :title="$t('HELP.NO_RESULTS_TITLE')"
        :description="$t('HELP.NO_RESULTS_DESCRIPTION')"
      />
    </div>
  </div>
</template>
