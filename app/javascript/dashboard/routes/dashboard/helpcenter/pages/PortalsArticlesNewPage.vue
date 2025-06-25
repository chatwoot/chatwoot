<script setup>
import { ref, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert, useTrack } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import ArticleEditor from 'dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticleEditor.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const { t } = useI18n();

const { portalSlug } = route.params;

const selectedAuthorId = ref(null);
const selectedCategoryId = ref(null);

const currentUserId = useMapGetter('getCurrentUserID');
const categories = useMapGetter('categories/allCategories');

const categoryId = computed(() => categories.value[0]?.id || null);

const article = ref({});
const isUpdating = ref(false);
const isSaved = ref(false);

const setAuthorId = authorId => {
  selectedAuthorId.value = authorId;
};

const setCategoryId = newCategoryId => {
  selectedCategoryId.value = newCategoryId;
};

const createNewArticle = async ({ title, content }) => {
  if (title) article.value.title = title;
  if (content) article.value.content = content;

  if (!article.value.title || !article.value.content) return;

  isUpdating.value = true;
  try {
    const { locale } = route.params;
    const articleId = await store.dispatch('articles/create', {
      portalSlug,
      content: article.value.content,
      title: article.value.title,
      locale: locale,
      authorId: selectedAuthorId.value || currentUserId.value,
      categoryId: selectedCategoryId.value || categoryId.value,
    });

    useTrack(PORTALS_EVENTS.CREATE_ARTICLE, { locale });

    router.replace({
      name: 'portals_articles_edit',
      params: {
        articleSlug: articleId,
        portalSlug,
        locale,
      },
    });
  } catch (error) {
    const errorMessage =
      error?.message || t('HELP_CENTER.EDIT_ARTICLE_PAGE.API.ERROR');
    useAlert(errorMessage);
  } finally {
    isUpdating.value = false;
  }
};

const goBackToArticles = () => {
  const { tab, categorySlug, locale } = route.params;
  router.push({
    name: 'portals_articles_index',
    params: { tab, categorySlug, locale },
  });
};
</script>

<template>
  <ArticleEditor
    :article="article"
    :is-updating="isUpdating"
    :is-saved="isSaved"
    @save-article="createNewArticle"
    @go-back="goBackToArticles"
    @set-author="setAuthorId"
    @set-category="setCategoryId"
  />
</template>
