<script setup>
import { computed, onMounted, watch } from 'vue';
import ArticleBlock from 'widget/components/pageComponents/Home/Article/ArticleBlock.vue';
import ArticleCardSkeletonLoader from 'widget/components/pageComponents/Home/Article/SkeletonLoader.vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useDarkMode } from 'widget/composables/useDarkMode';
import { getMatchingLocale } from 'shared/helpers/portalHelper';

const store = useStore();
const router = useRouter();
const i18n = useI18n();
const { prefersDarkMode } = useDarkMode();

const portal = computed(() => window.chatwootWebChannel.portal);

const popularArticles = useMapGetter('article/popularArticles');
const articleUiFlags = useMapGetter('article/uiFlags');

const locale = computed(() => {
  const { locale: selectedLocale } = i18n;

  if (!portal.value || !portal.value.config) return null;

  const { allowed_locales: allowedLocales } = portal.value.config;
  return getMatchingLocale(selectedLocale.value, allowedLocales);
});

const fetchArticles = () => {
  if (portal.value && locale.value) {
    store.dispatch('article/fetch', {
      slug: portal.value.slug,
      locale: locale.value,
    });
  }
};

const openArticleInArticleViewer = link => {
  const params = new URLSearchParams({
    show_plain_layout: 'true',
    theme: prefersDarkMode.value ? 'dark' : 'light',
    ...(locale.value && { locale: locale.value }),
  });

  // Combine link with query parameters
  const linkToOpen = `${link}?${params.toString()}`;
  router.push({ name: 'article-viewer', query: { link: linkToOpen } });
};

const viewAllArticles = () => {
  const {
    portal: { slug },
  } = window.chatwootWebChannel;
  openArticleInArticleViewer(`/hc/${slug}/${locale.value}`);
};

const hasArticles = computed(
  () =>
    !articleUiFlags.value.isFetching &&
    !articleUiFlags.value.isError &&
    !!popularArticles.value.length &&
    !!locale.value
);

// Watch for locale changes and refetch articles
watch(locale, (newLocale, oldLocale) => {
  if (newLocale && newLocale !== oldLocale) {
    fetchArticles();
  }
});

onMounted(() => fetchArticles());
</script>

<template>
  <div
    v-if="portal && (articleUiFlags.isFetching || !!popularArticles.length)"
    class="w-full shadow outline-1 outline outline-n-container rounded-xl bg-n-background dark:bg-n-solid-2 px-5 py-4"
  >
    <ArticleBlock
      v-if="hasArticles"
      :articles="popularArticles"
      @view="openArticleInArticleViewer"
      @view-all="viewAllArticles"
    />
    <ArticleCardSkeletonLoader v-if="articleUiFlags.isFetching" />
  </div>
  <div v-else class="hidden" />
</template>
