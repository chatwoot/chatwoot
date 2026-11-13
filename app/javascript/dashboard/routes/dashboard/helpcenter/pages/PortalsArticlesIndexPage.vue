<script setup>
import { computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import allLocales from 'shared/constants/locales.js';
import { getArticleStatus } from 'dashboard/helper/portalHelper.js';
import ArticlesPage from 'dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticlesPage.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();

const searchQuery = computed(() => route.query.search || '');

const allArticles = useMapGetter('articles/allArticles');
const articlesSortedByPosition = useMapGetter(
  'articles/allArticlesSortedByPosition'
);
const categories = useMapGetter('categories/allCategories');
const meta = useMapGetter('articles/getMeta');
const portalMeta = useMapGetter('portals/getMeta');
const currentUserId = useMapGetter('getCurrentUserID');
const getPortalBySlug = useMapGetter('portals/portalBySlug');

const selectedPortalSlug = computed(() => route.params.portalSlug);
const selectedCategorySlug = computed(() => route.params.categorySlug);
const status = computed(() => getArticleStatus(route.params.tab));

const author = computed(() => {
  // Preserve existing links to the Mine tab.
  if (route.params.tab === 'mine') return String(currentUserId.value);
  return route.query.author_id || '';
});

const activeLocale = computed(() => route.params.locale);
const portal = computed(() => getPortalBySlug.value(selectedPortalSlug.value));
const allowedLocales = computed(() => {
  if (!portal.value) {
    return [];
  }
  const { allowed_locales: allAllowedLocales } = portal.value.config;
  return allAllowedLocales.map(locale => {
    return {
      id: locale.code,
      name: allLocales[locale.code],
      code: locale.code,
    };
  });
});

const defaultPortalLocale = computed(() => {
  return portal.value?.meta?.default_locale;
});

const selectedLocaleInPortal = computed(() => {
  return route.params.locale || defaultPortalLocale.value;
});

const isCategoryArticles = computed(() => {
  return (
    route.name === 'portals_categories_articles_index' ||
    route.name === 'portals_categories_articles_edit' ||
    route.name === 'portals_categories_index'
  );
});

// Use position-sorted articles for category views and categories filter view (where drag reorder is enabled)
const articles = computed(() =>
  isCategoryArticles.value ? articlesSortedByPosition.value : allArticles.value
);

const fetchArticles = (pageNumber = 1) =>
  store.dispatch('articles/index', {
    pageNumber,
    portalSlug: selectedPortalSlug.value,
    locale: activeLocale.value,
    status: status.value,
    authorId: author.value || undefined,
    categorySlug: selectedCategorySlug.value,
    query: searchQuery.value || undefined,
  });

const onSearch = query => {
  router.replace({
    query: { ...route.query, search: query || undefined },
  });
};

const fetchPortalAndItsCategories = async locale => {
  await store.dispatch('portals/index');
  const selectedPortalParam = {
    portalSlug: selectedPortalSlug.value,
    locale: locale || selectedLocaleInPortal.value,
  };
  store.dispatch('portals/show', selectedPortalParam);
  store.dispatch('categories/index', selectedPortalParam);
  store.dispatch('agents/get');
};

watch([() => route.params, author, searchQuery], () => fetchArticles(), {
  immediate: true,
});
</script>

<template>
  <div class="w-full h-full">
    <ArticlesPage
      v-if="portal"
      :articles="articles"
      :portal-name="portal.name"
      :categories="categories"
      :allowed-locales="allowedLocales"
      :meta="meta"
      :author-id="author"
      :portal-meta="portalMeta"
      :is-category-articles="isCategoryArticles"
      @page-change="fetchArticles"
      @search="onSearch"
      @fetch-portal="fetchPortalAndItsCategories"
      @refresh-articles="fetchArticles"
    />
  </div>
</template>
