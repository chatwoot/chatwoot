<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';
import PipelineBoardHeaderWrapper from './PipelineBoardHeaderWrapper.vue';
import PipelineBoard from 'dashboard/components/pipeline/PipelineBoard.vue';
import ContactCard from './ContactCard.vue';

const STORE_MODULE = 'contactPipeline';
const DEBOUNCE_DELAY = 300;

const store = useStore();
const router = useRouter();
const { t } = useI18n();

const searchQuery = ref('');
const appliedFilterPayload = ref(null);

const hasAppliedFilters = computed(() => !!appliedFilterPayload.value);

const fetchBoard = (params = {}) => {
  store.dispatch(`${STORE_MODULE}/fetchColumns`, params);
};

const onSearch = debounce(query => {
  searchQuery.value = query;
  appliedFilterPayload.value = null;
  fetchBoard({ q: query });
}, DEBOUNCE_DELAY);

const onApplyFilter = payload => {
  appliedFilterPayload.value = payload;
  searchQuery.value = '';
  fetchBoard(payload);
};

const onClearFilters = () => {
  appliedFilterPayload.value = null;
  fetchBoard();
};
</script>

<template>
  <div class="flex flex-col flex-1 h-full overflow-hidden bg-n-background">
    <PipelineBoardHeaderWrapper
      :search-value="searchQuery"
      :header-title="t('CONTACTS_LAYOUT.HEADER.TITLE')"
      :has-applied-filters="hasAppliedFilters"
      @search="onSearch"
      @toggle-view="router.push({ name: 'contacts_dashboard_index' })"
      @apply-filter="onApplyFilter"
      @clear-filters="onClearFilters"
    />
    <div class="flex-1 overflow-auto">
      <PipelineBoard :store-module="STORE_MODULE">
        <template #card="{ item }">
          <ContactCard :item="item" />
        </template>
      </PipelineBoard>
    </div>
  </div>
</template>
