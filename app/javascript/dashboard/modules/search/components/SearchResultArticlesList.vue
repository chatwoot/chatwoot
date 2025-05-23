<script setup>
import { useMapGetter } from 'dashboard/composables/store.js';

import SearchResultSection from './SearchResultSection.vue';
import SearchResultArticleItem from './SearchResultArticleItem.vue';

defineProps({
  articles: {
    type: Array,
    default: () => [],
  },
  query: {
    type: String,
    default: '',
  },
  isFetching: {
    type: Boolean,
    default: false,
  },
  showTitle: {
    type: Boolean,
    default: true,
  },
});

const accountId = useMapGetter('getCurrentAccountId');
</script>

<template>
  <SearchResultSection
    :title="$t('SEARCH.SECTION.ARTICLES')"
    :empty="!articles.length"
    :query="query"
    :show-title="showTitle"
    :is-fetching="isFetching"
  >
    <ul v-if="articles.length" class="space-y-1.5 list-none">
      <li v-for="article in articles" :key="article.id">
        <SearchResultArticleItem
          :id="article.id"
          :title="article.title"
          :description="article.description"
          :content="article.content"
          :portal-slug="article.portal_slug"
          :locale="article.locale"
          :account-id="accountId"
          :category="article.category_name"
          :status="article.status"
        />
      </li>
    </ul>
  </SearchResultSection>
</template>
