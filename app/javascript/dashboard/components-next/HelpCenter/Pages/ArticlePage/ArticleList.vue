<script setup>
import { computed, ref } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert, useTrack } from 'dashboard/composables';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { getArticleStatus } from 'dashboard/helper/portalHelper.js';
import wootConstants from 'dashboard/constants/globals';

import ArticleCard from 'dashboard/components-next/HelpCenter/ArticleCard/ArticleCard.vue';
import DraggableReorderList from 'dashboard/components-next/DraggableReorderList/DraggableReorderList.vue';

const props = defineProps({
  articles: {
    type: Array,
    required: true,
  },
  isCategoryArticles: {
    type: Boolean,
    default: false,
  },
  selectedArticleIds: {
    type: Set,
    default: () => new Set(),
  },
  isSearching: {
    type: Boolean,
    default: false,
  },
  currentPage: {
    type: Number,
    default: 1,
  },
  totalPages: {
    type: Number,
    default: 1,
  },
});

const emit = defineEmits([
  'translateArticle',
  'toggleSelect',
  'navigatePage',
  'dragging',
]);

const { ARTICLE_STATUS_TYPES } = wootConstants;

const router = useRouter();
const route = useRoute();
const store = useStore();
const { t } = useI18n();

const hoveredArticleId = ref(null);

const dragEnabled = computed(() => {
  const canReorder = props.articles?.length > 1 || props.totalPages > 1;
  return (
    props.isCategoryArticles &&
    !props.isSearching &&
    canReorder &&
    props.selectedArticleIds.size === 0
  );
});

const hasBulkSelection = computed(() => props.selectedArticleIds.size > 0);

const shouldShowSelectionControl = id => {
  return hoveredArticleId.value === id || hasBulkSelection.value;
};

const handleCardHover = (isHovered, id) => {
  hoveredArticleId.value = isHovered ? id : null;
};

const getCategoryById = useMapGetter('categories/categoryById');

const getCategory = categoryId => {
  return getCategoryById.value(categoryId) || { name: '', icon: '' };
};

const openArticle = id => {
  const { tab, categorySlug, locale } = route.params;
  if (props.isCategoryArticles) {
    router.push({
      name: 'portals_categories_articles_edit',
      params: { articleSlug: id },
    });
  } else {
    router.push({
      name: 'portals_articles_edit',
      params: {
        articleSlug: id,
        tab,
        categorySlug,
        locale,
      },
    });
  }
};

const onReorder = async positionsHash => {
  const [movedId] = Object.keys(positionsHash);
  // A same-page reorder updates optimistically in the store, so it needs no
  // refetch. Only a cross-page drop must refresh, to pull the moved article
  // onto this page in its new spot.
  const isCrossPage = !props.articles.some(
    article => String(article.id) === movedId
  );
  try {
    await store.dispatch('articles/reorder', {
      reorderedGroup: positionsHash,
      portalSlug: route.params.portalSlug,
    });
    if (isCrossPage) emit('navigatePage', props.currentPage);
  } catch {
    useAlert(t('HELP_CENTER.REORDER_ARTICLE.API.ERROR_MESSAGE'));
  }
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

const updatePortalMeta = () => {
  const { portalSlug, locale } = route.params;
  return store.dispatch('portals/show', { portalSlug, locale });
};

const updateArticlesMeta = () => {
  const { portalSlug, locale } = route.params;
  return store.dispatch('articles/updateArticleMeta', {
    portalSlug,
    locale,
  });
};

const handleArticleAction = async (action, { status, id }) => {
  const { portalSlug } = route.params;
  try {
    if (action === 'delete') {
      await store.dispatch('articles/delete', {
        portalSlug,
        articleId: id,
      });
      useAlert(t('HELP_CENTER.DELETE_ARTICLE.API.SUCCESS_MESSAGE'));
    } else {
      await store.dispatch('articles/update', {
        portalSlug,
        articleId: id,
        status,
      });
      useAlert(getStatusMessage(status, true));

      if (status === ARTICLE_STATUS_TYPES.ARCHIVE) {
        useTrack(PORTALS_EVENTS.ARCHIVE_ARTICLE, { uiFrom: 'header' });
      } else if (status === ARTICLE_STATUS_TYPES.PUBLISH) {
        useTrack(PORTALS_EVENTS.PUBLISH_ARTICLE);
      }
    }
    await updateArticlesMeta();
    await updatePortalMeta();
  } catch (error) {
    const errorMessage =
      error?.message ||
      (action === 'delete'
        ? t('HELP_CENTER.DELETE_ARTICLE.API.ERROR_MESSAGE')
        : getStatusMessage(status, false));
    useAlert(errorMessage);
  }
};

const updateArticle = ({ action, value, id }) => {
  if (action === 'translate') {
    emit('translateArticle', id);
    return;
  }
  const status = action !== 'delete' ? getArticleStatus(value) : null;
  handleArticleAction(action, { status, id });
};
</script>

<template>
  <DraggableReorderList
    :items="articles"
    :disabled="!dragEnabled"
    :current-page="currentPage"
    :total-pages="totalPages"
    @reorder="onReorder"
    @navigate-page="page => emit('navigatePage', page)"
    @dragging="value => emit('dragging', value)"
  >
    <template #item="{ item }">
      <ArticleCard
        :id="item.id"
        :title="item.title"
        :status="item.status"
        :author="item.author"
        :category="getCategory(item.category.id)"
        :views="item.views || 0"
        :updated-at="item.updatedAt"
        :is-selected="selectedArticleIds.has(item.id)"
        selectable
        :show-selection-control="shouldShowSelectionControl(item.id)"
        @open-article="openArticle"
        @article-action="updateArticle"
        @toggle-select="emit('toggleSelect', $event)"
        @hover="isHovered => handleCardHover(isHovered, item.id)"
      />
    </template>
    <template #ghost="{ item }">
      <ArticleCard
        :id="item.id"
        :title="item.title"
        :status="item.status"
        :author="item.author"
        :category="getCategory(item.category.id)"
        :views="item.views || 0"
        :updated-at="item.updatedAt"
      />
    </template>
  </DraggableReorderList>
</template>
