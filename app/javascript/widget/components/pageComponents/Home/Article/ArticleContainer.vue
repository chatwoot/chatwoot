<script setup>
import { computed, onMounted } from 'vue';
import ArticleBlock from 'widget/components/pageComponents/Home/Article/ArticleBlock.vue';
import ArticleCardSkeletonLoader from 'widget/components/pageComponents/Home/Article/SkeletonLoader.vue';
import { useArticleStore } from 'widget/stores/articleStore';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useDarkMode } from 'widget/composables/useDarkMode';

const store = useArticleStore();
const router = useRouter();
const { prefersDarkMode } = useDarkMode();

const portal = computed(() => window.chatwootWebChannel.portal);

const locale = computed(() => {
  const { locale: selectedLocale } = useI18n();

  const {
    allowed_locales: allowedLocales,
    default_locale: defaultLocale = 'en',
  } = portal.value.config;

  // IMPORTANT: Variation strict locale matching, Follow iso_639_1_code
  // If the exact match of a locale is available in the list of portal locales, return it
  // Else return the default locale. Eg: `es` will not work if `es_ES` is available in the list
  if (allowedLocales.includes(selectedLocale)) {
    return locale;
  }
  return defaultLocale;
});

const fetchArticles = () => {
  if (portal.value && !store.getRecords.length) {
    store.index({ slug: portal.value.slug, locale: locale.value });
  }
};

const openArticleInArticleViewer = link => {
  let linkToOpen = `${link}?show_plain_layout=true`;
  if (prefersDarkMode) {
    linkToOpen = `${linkToOpen}&theme=dark`;
  }
  router.push({ name: 'article-viewer', query: { link: linkToOpen } });
};
const viewAllArticles = () => {
  const {
    portal: { slug },
  } = window.chatwootWebChannel;
  openArticleInArticleViewer(`/hc/${slug}/${locale.value}`);
};

const hasArticles = computed(
  () => !store.getUIFlags.isFetching && !!store.getRecords.length
);

onMounted(() => fetchArticles());
</script>

<template>
  <div
    v-if="portal"
    class="w-full shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2 px-5 py-4"
  >
    <ArticleBlock
      v-if="hasArticles"
      :articles="store.getRecords"
      @view="openArticleInArticleViewer"
      @view-all="viewAllArticles"
    />
    <ArticleCardSkeletonLoader v-else />
  </div>
  <div v-else />
</template>
