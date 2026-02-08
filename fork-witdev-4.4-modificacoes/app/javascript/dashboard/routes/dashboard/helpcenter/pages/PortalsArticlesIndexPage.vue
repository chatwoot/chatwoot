<script setup>
import { computed, ref, onMounted, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import allLocales from 'shared/constants/locales.js';
import { getArticleStatus } from 'dashboard/helper/portalHelper.js';
import ArticlesPage from 'dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticlesPage.vue';

const route = useRoute();
const store = useStore();

const pageNumber = ref(1);

const articles = useMapGetter('articles/allArticles');
const categories = useMapGetter('categories/allCategories');
const meta = useMapGetter('articles/getMeta');
const portalMeta = useMapGetter('portals/getMeta');
const currentUserId = useMapGetter('getCurrentUserID');
const getPortalBySlug = useMapGetter('portals/portalBySlug');

const selectedPortalSlug = computed(() => route.params.portalSlug);
const selectedCategorySlug = computed(() => route.params.categorySlug);
const status = computed(() => getArticleStatus(route.params.tab));

const author = computed(() =>
  route.params.tab === 'mine' ? currentUserId.value : null
);

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

const fetchArticles = ({ pageNumber: pageNumberParam } = {}) => {
  store.dispatch('articles/index', {
    pageNumber: pageNumberParam || pageNumber.value,
    portalSlug: selectedPortalSlug.value,
    locale: activeLocale.value,
    status: status.value,
    authorId: author.value,
    categorySlug: selectedCategorySlug.value,
  });
};

const onPageChange = pageNumberParam => {
  fetchArticles({ pageNumber: pageNumberParam });
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

onMounted(() => {
  fetchArticles();
});

watch(
  () => route.params,
  () => {
    pageNumber.value = 1;
    fetchArticles();
  },
  { deep: true, immediate: true }
);
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
      :portal-meta="portalMeta"
      :is-category-articles="isCategoryArticles"
      @page-change="onPageChange"
      @fetch-portal="fetchPortalAndItsCategories"
    />
  </div>
</template>
