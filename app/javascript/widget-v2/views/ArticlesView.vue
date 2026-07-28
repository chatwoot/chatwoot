<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useArticlesStore } from 'widget-v2/stores/articles';
import WidgetHeader from 'widget-v2/components/WidgetHeader.vue';
import ArticleCard from 'widget-v2/components/ArticleCard.vue';
import EmptyState from 'widget-v2/components/EmptyState.vue';
import BaseSpinner from 'widget-v2/components/base/BaseSpinner.vue';

const router = useRouter();
const { t } = useI18n();
const articlesStore = useArticlesStore();

const query = ref('');
let debounceTimer = null;

const isSearching = computed(() => Boolean(articlesStore.searchQuery));
const categories = computed(() =>
  [...articlesStore.categories]
    .sort((a, b) => (a.position || 0) - (b.position || 0))
    .filter(category => category.meta?.articles_count)
);

const onSearch = () => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => articlesStore.search(query.value), 300);
};

onMounted(() => {
  articlesStore.loadCategories();
  // Articles back the search results and per-category lists.
  if (!articlesStore.articles.length) articlesStore.search('');
});

const categorySubtitle = category =>
  category.description || t('HELP.ARTICLE_COUNT', category.meta.articles_count);

// Search results carry no slug, only a link ("hc/<portal>/articles/<slug>").
const openArticle = article =>
  router.push({
    name: 'help-article',
    params: { slug: article.slug || article.link?.split('/').pop() },
  });

const openCategory = category =>
  router.push({
    name: 'help-category',
    params: { categorySlug: category.slug },
  });
</script>

<template>
  <div class="flex flex-col h-full bg-cw-solid">
    <WidgetHeader :title="$t('HELP.TITLE')" />

    <div class="px-4 py-3 border-b border-cw-hairline">
      <label
        class="flex items-center gap-2 h-10 px-3 rounded-token-sm bg-cw-muted transition-shadow focus-within:ring-[3px] focus-within:ring-cw-ring"
      >
        <span class="i-ph-magnifying-glass text-cw-text-faint" />
        <input
          v-model="query"
          type="search"
          :placeholder="$t('HELP.SEARCH_PLACEHOLDER')"
          class="flex-1 text-base bg-transparent text-cw-text placeholder:text-cw-text-faint outline-none border-none"
          @input="onSearch"
        />
      </label>
    </div>

    <div class="flex-1 overflow-y-auto scrollbar-thin pb-20">
      <div v-if="articlesStore.loading" class="flex justify-center py-8">
        <BaseSpinner />
      </div>

      <template v-else-if="isSearching">
        <template v-if="articlesStore.articles.length">
          <ArticleCard
            v-for="article in articlesStore.articles"
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
      </template>

      <template v-else-if="categories.length">
        <button
          v-for="category in categories"
          :key="category.slug"
          type="button"
          class="group flex items-center w-full gap-3.5 row-pad text-left transition-colors bg-cw-solid hover:bg-cw-surface border-b border-cw-hairline last:border-b-0 outline-none focus-visible:ring-[3px] focus-visible:ring-inset focus-visible:ring-cw-ring"
          @click="openCategory(category)"
        >
          <span
            class="flex items-center justify-center w-9 h-9 rounded-full bg-cw-muted text-cw-text-muted"
          >
            <span v-if="category.icon" class="text-base leading-none">
              {{ category.icon }}
            </span>
            <span v-else class="i-ph-folder-simple text-sm" />
          </span>
          <span class="flex-1 min-w-0">
            <span class="block text-sm font-520 text-cw-text truncate">
              {{ category.name }}
            </span>
            <span class="block mt-0.5 text-xs text-cw-text-muted truncate">
              {{ categorySubtitle(category) }}
            </span>
          </span>
          <span
            class="i-ph-caret-right shrink-0 text-cw-text-faint transition-transform group-hover:translate-x-0.5"
          />
        </button>
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
