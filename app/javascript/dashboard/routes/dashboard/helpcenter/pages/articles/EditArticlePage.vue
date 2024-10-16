<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import EditArticle from 'dashboard/components-next/HelpCenter/Pages/EditArticlePage/EditArticle.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const { t } = useI18n();

const { articleSlug, portalSlug } = route.params;

const articleById = useMapGetter('articles/articleById');

const article = computed(() => articleById.value(articleSlug));

const isUpdating = ref(false);
const isSaved = ref(false);

const saveArticle = async ({ ...values }) => {
  isUpdating.value = true;
  try {
    await store.dispatch('articles/update', {
      portalSlug,
      articleId: articleSlug,
      ...values,
    });
    isSaved.value = true;
  } catch (error) {
    const errorMessage =
      error?.message || t('HELP_CENTER.EDIT_ARTICLE_PAGE.API.ERROR');
    useAlert(errorMessage);
  } finally {
    setTimeout(() => {
      isUpdating.value = false;
      isSaved.value = true;
    }, 1500);
  }
};

const isCategoryArticles = computed(() => {
  return (
    route.name === 'list_category_articles' ||
    route.name === 'edit_category_article' ||
    route.name === 'list_categories'
  );
});

const goBackToArticles = () => {
  const { tab, categorySlug, locale } = route.params;
  if (isCategoryArticles.value) {
    router.push({
      name: 'list_category_articles',
      params: { categorySlug, locale },
    });
  } else {
    router.push({
      name: 'list_articles',
      params: { tab, categorySlug, locale },
    });
  }
};

const fetchArticleDetails = () => {
  store.dispatch('articles/show', {
    id: articleSlug,
    portalSlug,
  });
};

onMounted(() => {
  fetchArticleDetails();
});
</script>

<template>
  <EditArticle
    :article="article"
    :is-updating="isUpdating"
    :is-saved="isSaved"
    @save-article="saveArticle"
    @go-back="goBackToArticles"
  />
</template>
