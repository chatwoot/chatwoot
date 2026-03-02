<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import InfluencerSearchResultCard from './InfluencerSearchResultCard.vue';
import InfluencerCreditsBadge from './InfluencerCreditsBadge.vue';

const emit = defineEmits(['select']);
const { t } = useI18n();
const store = useStore();

const searchResults = useMapGetter('influencerProfiles/getSearchResults');
const searchMeta = useMapGetter('influencerProfiles/getSearchMeta');
const uiFlags = useMapGetter('influencerProfiles/getUIFlags');

const hasResults = computed(() => searchResults.value.length > 0);
const hasSearched = computed(() => searchMeta.value.hasSearched);
const showPagination = computed(
  () => hasSearched.value && searchMeta.value.total > searchMeta.value.perPage
);
const searchingLabel = computed(() => `${t('INFLUENCER.SEARCH.SEARCHING')}...`);
const importedLabel = computed(() =>
  t('INFLUENCER.SEARCH.AUTO_SAVED', { count: searchMeta.value.imported })
);

async function handlePageChange(page) {
  try {
    await store.dispatch('influencerProfiles/search', { page });
  } catch (error) {
    const message =
      error?.response?.data?.error || t('INFLUENCER.SEARCH.API_ERROR');
    useAlert(message);
  }
}
</script>

<template>
  <div class="p-4">
    <div
      v-if="uiFlags.isSearching"
      class="py-8 text-center text-sm text-n-slate-11"
    >
      {{ searchingLabel }}
    </div>

    <div
      v-else-if="!hasSearched"
      class="py-8 text-center text-sm text-n-slate-11"
    >
      {{ t('INFLUENCER.SEARCH.NO_RESULTS') }}
    </div>

    <div v-else-if="!hasResults" class="py-8 text-center">
      <p class="text-sm font-medium text-n-slate-12">
        {{ t('INFLUENCER.SEARCH.EMPTY_RESULTS') }}
      </p>
      <p class="mt-1 text-xs text-n-slate-11">
        {{ t('INFLUENCER.SEARCH.EMPTY_RESULTS_HINT') }}
      </p>
    </div>

    <template v-else>
      <div
        class="mb-3 flex items-center justify-between text-xs text-n-slate-11"
      >
        <div class="flex items-center gap-2">
          <span>
            {{
              t('INFLUENCER.SEARCH.TOTAL_RESULTS', {
                total: searchMeta.total.toLocaleString(),
              })
            }}
          </span>
          <span v-if="searchMeta.imported" class="text-n-green-11">
            {{ importedLabel }}
          </span>
          <span v-if="searchMeta.cached">
            {{ t('INFLUENCER.SEARCH.CACHED_RESULTS') }}
          </span>
        </div>
        <InfluencerCreditsBadge />
      </div>

      <div class="grid grid-cols-1 gap-3 md:grid-cols-2 lg:grid-cols-3">
        <InfluencerSearchResultCard
          v-for="result in searchResults"
          :key="result.username"
          :result="result"
          @click="emit('select', result)"
        />
      </div>

      <footer v-if="showPagination" class="sticky bottom-0 z-0 mt-4">
        <PaginationFooter
          :current-page="searchMeta.currentPage"
          :total-items="searchMeta.total"
          :items-per-page="searchMeta.perPage"
          @update:current-page="handlePageChange"
        />
      </footer>
    </template>
  </div>
</template>
