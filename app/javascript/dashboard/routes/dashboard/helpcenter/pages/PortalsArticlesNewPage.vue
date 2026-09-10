<script setup>
import { ref, computed, onBeforeUnmount } from 'vue';
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
let draftRevision = 0;
let persistedRevision = 0;
let createdArticleId = null;
let isPageActive = true;

onBeforeUnmount(() => {
  isPageActive = false;
});

const updateArticleDraft = ({ title, content }) => {
  let hasChanges = false;

  if (title !== undefined && article.value.title !== title) {
    article.value.title = title;
    hasChanges = true;
  }

  if (content !== undefined && article.value.content !== content) {
    article.value.content = content;
    hasChanges = true;
  }

  if (hasChanges) draftRevision += 1;
};

const setAuthorId = authorId => {
  if (selectedAuthorId.value === authorId) return;
  selectedAuthorId.value = authorId;
  draftRevision += 1;
};

const setCategoryId = newCategoryId => {
  if (selectedCategoryId.value === newCategoryId) return;
  selectedCategoryId.value = newCategoryId;
  draftRevision += 1;
};

const currentArticlePayload = () => ({
  title: article.value.title,
  content: article.value.content,
  authorId: selectedAuthorId.value || currentUserId.value,
  categoryId: selectedCategoryId.value || categoryId.value,
});

const syncPendingChanges = async articleId => {
  if (persistedRevision >= draftRevision) return;

  const revision = draftRevision;
  const {
    title,
    content,
    authorId,
    categoryId: currentCategoryId,
  } = currentArticlePayload();

  await store.dispatch('articles/update', {
    portalSlug,
    articleId,
    title,
    content,
    author_id: authorId,
    category_id: currentCategoryId,
  });
  persistedRevision = revision;
  await syncPendingChanges(articleId);
};

const createNewArticle = async ({ title, content }) => {
  updateArticleDraft({ title, content });

  if (!article.value.title || isUpdating.value) return;

  isUpdating.value = true;
  try {
    const { locale } = route.params;
    if (!createdArticleId) {
      const revision = draftRevision;
      createdArticleId = await store.dispatch('articles/create', {
        portalSlug,
        locale,
        ...currentArticlePayload(),
      });
      persistedRevision = revision;
      useTrack(PORTALS_EVENTS.CREATE_ARTICLE, { locale });
    }

    await syncPendingChanges(createdArticleId);
    if (!isPageActive) return;

    const { categoryId: resolvedCategoryId } = currentArticlePayload();

    const resolvedSlug = categories.value?.find(
      c => c.id === resolvedCategoryId
    )?.slug;
    const startedFromCategorySlug = route.params.categorySlug;

    await router.replace({
      name: isCategoryArticles.value
        ? 'portals_categories_articles_edit'
        : 'portals_articles_edit',
      params: {
        articleSlug: createdArticleId,
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
    @update-article-draft="updateArticleDraft"
    @go-back="goBackToArticles"
    @set-author="setAuthorId"
    @set-category="setCategoryId"
  />
</template>
