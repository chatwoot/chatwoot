<script setup>
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert, useTrack } from 'dashboard/composables';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { getArticleStatus } from 'dashboard/helper/portalHelper.js';
import wootConstants from 'dashboard/constants/globals';

import ArticleCard from 'dashboard/components-next/HelpCenter/ArticleCard/ArticleCard.vue';

defineProps({
  articles: {
    type: Array,
    required: true,
  },
});

const { ARTICLE_STATUS_TYPES } = wootConstants;

const router = useRouter();
const route = useRoute();
const store = useStore();
const { t } = useI18n();

const getCategoryById = useMapGetter('categories/categoryById');

const openArticle = id => {
  router.push({ name: 'edit_article', params: { articleSlug: id } });
};

const getCategory = categoryId => {
  return getCategoryById.value(categoryId) || { name: '', icon: '' };
};

const getStatusMessage = (status, isSuccess) => {
  const messageType = isSuccess ? 'SUCCESS' : 'ERROR';
  const statusMap = {
    [ARTICLE_STATUS_TYPES.PUBLISH]: 'PUBLISH_ARTICLE',
    [ARTICLE_STATUS_TYPES.ARCHIVE]: 'ARCHIVE_ARTICLE',
    [ARTICLE_STATUS_TYPES.DRAFT]: 'DRAFT_ARTICLE',
  };

  return statusMap[status]
    ? t(`HELP_CENTER.${statusMap[status]}.API.${messageType}`)
    : '';
};

const updateMeta = () => {
  const { portalSlug, locale } = route.params;
  return store.dispatch('portals/show', { portalSlug, locale });
};

const handleArticleAction = async (action, { status, id }) => {
  let alertMessage = '';
  const { portalSlug } = route.params;
  try {
    if (action === 'delete') {
      await store.dispatch('articles/delete', {
        portalSlug,
        articleId: id,
      });
      alertMessage = t('HELP_CENTER.DELETE_ARTICLE.API.SUCCESS_MESSAGE');
    } else {
      await store.dispatch('articles/update', {
        portalSlug,
        articleId: id,
        status,
      });
      alertMessage = getStatusMessage(status, true);

      if (status === ARTICLE_STATUS_TYPES.ARCHIVE) {
        useTrack(PORTALS_EVENTS.ARCHIVE_ARTICLE, { uiFrom: 'header' });
      } else if (status === ARTICLE_STATUS_TYPES.PUBLISH) {
        useTrack(PORTALS_EVENTS.PUBLISH_ARTICLE);
      }
    }

    await updateMeta();
  } catch (error) {
    alertMessage =
      error?.message ||
      (action === 'delete'
        ? t('HELP_CENTER.DELETE_ARTICLE.API.ERROR_MESSAGE')
        : getStatusMessage(status, false));
  } finally {
    useAlert(alertMessage);
  }
};

const updateArticle = ({ action, value, id }) => {
  const status = action !== 'delete' ? getArticleStatus(value) : null;
  handleArticleAction(action, { status, id });
};
</script>

<template>
  <ul role="list" class="w-full h-full space-y-4">
    <ArticleCard
      v-for="article in articles"
      :id="article.id"
      :key="article.id"
      :title="article.title"
      :status="article.status"
      :author="article.author"
      :category="getCategory(article.category.id)"
      :views="article.views || 0"
      :updated-at="article.updated_at"
      @open-article="openArticle"
      @article-action="updateArticle"
    />
  </ul>
</template>
