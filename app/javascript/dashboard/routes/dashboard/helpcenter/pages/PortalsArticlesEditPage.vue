<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useEventListener } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { useAlert, useTrack } from 'dashboard/composables';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import {
  buildPortalArticleURL,
  ARTICLE_STATUSES,
} from 'dashboard/helper/portalHelper';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { rendersIdentically } from 'dashboard/helper/articleDiffHelper';
import ArticlesAPI from 'dashboard/api/helpCenter/articles';

import ArticleEditor from 'dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticleEditor.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const { t } = useI18n();

const { articleSlug, portalSlug } = route.params;

const articleById = useMapGetter('articles/articleById');

const article = computed(() => articleById.value(articleSlug));

const portalBySlug = useMapGetter('portals/portalBySlug');

const portal = computed(() => portalBySlug.value(portalSlug));

const isUpdating = ref(false);
const isSaved = ref(false);
const hasNewerVersion = ref(false);
const articleEditorRef = ref(null);

const articleLink = computed(() => {
  const { slug: categorySlug, locale: categoryLocale } = article.value.category;
  const { slug: articleSlugValue } = article.value;
  const portalCustomDomain = portal.value?.custom_domain;
  return buildPortalArticleURL(
    portalSlug,
    categorySlug,
    categoryLocale,
    articleSlugValue,
    portalCustomDomain
  );
});

// On a published article, title/content edits stage into draft_* columns (kept
// off the live site). Anywhere else they save straight to the live record — and
// we drop any leftover draft (e.g. left behind when the card/bulk menu moved a
// published article to draft) so a later publish can't resurrect stale content.
const stageDraftFields = values => {
  if (article.value?.status !== ARTICLE_STATUSES.PUBLISHED) {
    const hasStaleDraft =
      article.value?.draftTitle != null || article.value?.draftContent != null;
    if (!hasStaleDraft) return values;
    // The editor is showing the staged draft, so promote both fields to the live
    // record (the field being autosaved wins) before dropping the drafts —
    // otherwise saving one field would snap the other back to the old live value.
    return {
      ...values,
      title: values.title ?? article.value.draftTitle ?? article.value.title,
      content:
        values.content ?? article.value.draftContent ?? article.value.content,
      draft_title: null,
      draft_content: null,
    };
  }

  const staged = { ...values };
  ['title', 'content'].forEach(field => {
    if (field in staged) {
      staged[`draft_${field}`] = staged[field];
      delete staged[field];
    }
  });

  // Clear the draft when it matches the live version (a revert, or a body edit
  // the renderer ignores like a blank line) so it doesn't leave a "pending
  // changes" badge with nothing to compare. The title is shown as raw escaped
  // text, so compare it exactly; only the body is Markdown, so compare its render.
  const liveTitle = article.value.title ?? '';
  const liveContent = article.value.content ?? '';
  const nextTitle = staged.draft_title ?? article.value.draftTitle ?? liveTitle;
  const nextContent =
    staged.draft_content ?? article.value.draftContent ?? liveContent;
  if (nextTitle === liveTitle && rendersIdentically(liveContent, nextContent)) {
    staged.draft_title = null;
    staged.draft_content = null;
  }

  return staged;
};

const saveArticle = async ({ ...values }) => {
  isUpdating.value = true;
  try {
    await store.dispatch('articles/update', {
      portalSlug,
      articleId: articleSlug,
      ...stageDraftFields(values),
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
    route.name === 'portals_categories_articles_index' ||
    route.name === 'portals_categories_articles_edit' ||
    route.name === 'portals_categories_index'
  );
});

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

const fetchArticleDetails = () => {
  store.dispatch('articles/show', {
    id: articleSlug,
    portalSlug,
  });
};

// Compare without touching the store, which can reseed the editor before the
// user asks. Draft autosaves skip updated_at, so the draft fields are compared
// too. Skip while our own save settles, or it would look like a remote edit.
const checkForNewerVersion = async () => {
  if (document.visibilityState !== 'visible') return;
  if (!article.value?.id || isUpdating.value) return;
  const { data } = await ArticlesAPI.getArticle({
    id: articleSlug,
    portalSlug,
  });
  const { updated_at, draft_title, draft_content } = data.payload;
  const { updatedAt, draftTitle, draftContent } = article.value;
  if (
    updated_at !== updatedAt ||
    draft_title !== draftTitle ||
    draft_content !== draftContent
  ) {
    hasNewerVersion.value = true;
  }
};

const loadLatestVersion = async () => {
  await store.dispatch('articles/show', { id: articleSlug, portalSlug });
  articleEditorRef.value.syncLocalState();
  hasNewerVersion.value = false;
};

useEventListener(document, 'visibilitychange', checkForNewerVersion);

const previewArticle = () => {
  window.open(articleLink.value, '_blank');
  useTrack(PORTALS_EVENTS.PREVIEW_ARTICLE, {
    status: article.value?.status,
  });
};

onMounted(fetchArticleDetails);
</script>

<template>
  <ArticleEditor
    ref="articleEditorRef"
    :has-newer-version="hasNewerVersion"
    :article="article"
    :is-updating="isUpdating"
    :is-saved="isSaved"
    @save-article="saveArticle"
    @preview-article="previewArticle"
    @go-back="goBackToArticles"
    @reload-article="loadLatestVersion"
  />
</template>
