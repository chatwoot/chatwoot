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

const categoryId = computed(() => {
  const { categorySlug } = route.params;
  if (categorySlug) {
    const matched = categories.value?.find(c => c.slug === categorySlug);
    if (matched) return matched.id;
  }
  return categories.value[0]?.id || null;
});

const isCategoryArticles = computed(
  () => route.name === 'portals_categories_articles_new'
);

const article = ref({});
const isUpdating = ref(false);
const isSaved = ref(false);

const setAuthorId = authorId => {
  selectedAuthorId.value = authorId;
};

const setCategoryId = newCategoryId => {
  selectedCategoryId.value = newCategoryId;
};

// Nothing to save to until the create returns an id; keep edits local and let
// createNewArticle save them.
const saveArticle = values => Object.assign(article.value, values);

const currentArticle = () => ({
  title: article.value.title,
  content: article.value.content,
  author_id: selectedAuthorId.value || currentUserId.value,
  category_id: selectedCategoryId.value || categoryId.value,
});

// Save what changed while the create request ran, since the edit page opens
// with the stored article.
const saveEditsMadeWhileCreating = async (articleId, saved) => {
  const latest = currentArticle();
  if (Object.keys(latest).every(key => latest[key] === saved[key])) return;

  await store.dispatch('articles/update', { portalSlug, articleId, ...latest });
  await saveEditsMadeWhileCreating(articleId, latest);
};

const createNewArticle = async ({ title, content }) => {
  if (title) article.value.title = title;
  if (content) article.value.content = content;

  if (!article.value.title || isUpdating.value) return;

  isUpdating.value = true;
  try {
    const { locale } = route.params;
    const created = currentArticle();
    const articleId = await store.dispatch('articles/create', {
      portalSlug,
      title: created.title,
      content: created.content,
      locale: locale,
      authorId: created.author_id,
      categoryId: created.category_id,
    });

    useTrack(PORTALS_EVENTS.CREATE_ARTICLE, { locale });

    // The article exists now, so open it even if saving the later edits fails;
    // staying here would create it again on the next title blur.
    await saveEditsMadeWhileCreating(articleId, created).catch(error =>
      useAlert(error?.message || t('HELP_CENTER.EDIT_ARTICLE_PAGE.API.ERROR'))
    );

    const resolvedCategoryId = currentArticle().category_id;
    const resolvedSlug = categories.value?.find(
      c => c.id === resolvedCategoryId
    )?.slug;
    const startedFromCategorySlug = route.params.categorySlug;

    await router.replace({
      name: isCategoryArticles.value
        ? 'portals_categories_articles_edit'
        : 'portals_articles_edit',
      params: {
        articleSlug: articleId,
        portalSlug,
        locale,
        ...(startedFromCategorySlug
          ? { categorySlug: resolvedSlug || startedFromCategorySlug }
          : {}),
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
  if (isCategoryArticles.value) {
    router.push({
      name: 'portals_categories_articles_index',
      params: { categorySlug, locale },
    });
  } else {
    router.push({
      name: 'portals_articles_index',
      params: { tab, categorySlug, locale },
    });
  }
};
</script>

<template>
  <ArticleEditor
    :article="article"
    :is-updating="isUpdating"
    :is-saved="isSaved"
    @create-article="createNewArticle"
    @save-article="saveArticle"
    @go-back="goBackToArticles"
    @set-author="setAuthorId"
    @set-category="setCategoryId"
  />
</template>
