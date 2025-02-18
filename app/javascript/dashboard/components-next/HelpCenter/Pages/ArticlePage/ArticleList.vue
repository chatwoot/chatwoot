<script setup>
import { ref, computed, watch } from 'vue';
import Draggable from 'vuedraggable';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert, useTrack } from 'dashboard/composables';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { getArticleStatus } from 'dashboard/helper/portalHelper.js';
import wootConstants from 'dashboard/constants/globals';

import ArticleCard from 'dashboard/components-next/HelpCenter/ArticleCard/ArticleCard.vue';

const props = defineProps({
  articles: {
    type: Array,
    required: true,
  },
  isCategoryArticles: {
    type: Boolean,
    default: false,
  },
});

const { ARTICLE_STATUS_TYPES } = wootConstants;

const router = useRouter();
const route = useRoute();
const store = useStore();
const { t } = useI18n();

const localArticles = ref(props.articles);

const dragEnabled = computed(() => {
  // Enable dragging only for category articles and when there's more than one article
  return props.isCategoryArticles && localArticles.value?.length > 1;
});

const getCategoryById = useMapGetter('categories/categoryById');

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

const onReorder = reorderedGroup => {
  store.dispatch('articles/reorder', {
    reorderedGroup,
    portalSlug: route.params.portalSlug,
  });
};

const onDragEnd = () => {
  // Reuse existing positions to maintain order within the current group
  const sortedArticlePositions = localArticles.value
    .map(article => article.position)
    .sort((a, b) => a - b); // Use custom sort to handle numeric values correctly

  const orderedArticles = localArticles.value.map(article => article.id);

  // Create a map of article IDs to their new positions
  const reorderedGroup = orderedArticles.reduce((obj, key, index) => {
    obj[key] = sortedArticlePositions[index];
    return obj;
  }, {});

  onReorder(reorderedGroup);
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
    await updateMeta();
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
  const status = action !== 'delete' ? getArticleStatus(value) : null;
  handleArticleAction(action, { status, id });
};

// Watch for changes in the articles prop and update the localArticles ref
watch(
  () => props.articles,
  newArticles => {
    localArticles.value = newArticles;
  },
  { deep: true }
);
</script>

<template>
  <Draggable
    v-model="localArticles"
    :disabled="!dragEnabled"
    item-key="id"
    tag="ul"
    ghost-class="article-ghost-class"
    class="w-full h-full space-y-4"
    @end="onDragEnd"
  >
    <template #item="{ element }">
      <li class="list-none rounded-2xl">
        <ArticleCard
          :id="element.id"
          :key="element.id"
          :title="element.title"
          :status="element.status"
          :author="element.author"
          :category="getCategory(element.category.id)"
          :views="element.views || 0"
          :updated-at="element.updatedAt"
          :class="{ 'cursor-grab': dragEnabled }"
          @open-article="openArticle"
          @article-action="updateArticle"
        />
      </li>
    </template>
  </Draggable>
</template>

<style lang="scss" scoped>
.article-ghost-class {
  @apply opacity-50 bg-n-solid-1;
}
</style>
