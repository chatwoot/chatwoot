<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { debounce } from '@chatwoot/utils';

import CompaniesListLayout from 'dashboard/components-next/Companies/CompaniesListLayout.vue';
import CompaniesCard from 'dashboard/components-next/Companies/CompaniesCard/CompaniesCard.vue';

const DEBOUNCE_DELAY = 300;

const store = useStore();
const { t } = useI18n();

const searchQuery = ref('');
const currentPage = ref(1);
const activeSort = ref('name');
const activeOrdering = ref('');

const companies = useMapGetter('companies/getCompaniesList');
const meta = useMapGetter('companies/getMeta');
const uiFlags = useMapGetter('companies/getUIFlags');

const isFetchingList = computed(() => uiFlags.value.isFetching);

const buildSortParam = () => {
  return activeOrdering.value === '-'
    ? `-${activeSort.value}`
    : activeSort.value;
};

const fetchCompanies = async () => {
  const sortParam = buildSortParam();

  if (searchQuery.value) {
    await store.dispatch('companies/search', {
      search: searchQuery.value,
      page: currentPage.value,
      sort: sortParam,
    });
  } else {
    await store.dispatch('companies/get', {
      page: currentPage.value,
      sort: sortParam,
    });
  }
};

const onSearch = debounce(query => {
  searchQuery.value = query;
  currentPage.value = 1;
  fetchCompanies();
}, DEBOUNCE_DELAY);

const onPageChange = page => {
  currentPage.value = page;
  fetchCompanies();
};

const handleSort = ({ sort, order }) => {
  activeSort.value = sort;
  activeOrdering.value = order;
  currentPage.value = 1;
  fetchCompanies();
};

onMounted(() => {
  fetchCompanies();
});
</script>

<template>
  <CompaniesListLayout
    :search-value="searchQuery"
    :header-title="t('COMPANIES.HEADER')"
    :current-page="Number(meta.currentPage)"
    :total-items="Number(meta.count)"
    :active-sort="activeSort"
    :active-ordering="activeOrdering"
    :is-fetching-list="isFetchingList"
    @update:current-page="onPageChange"
    @update:sort="handleSort"
    @search="onSearch"
  >
    <div v-if="isFetchingList" class="flex items-center justify-center p-8">
      <span class="text-n-slate-11 text-base">{{
        t('COMPANIES.LOADING')
      }}</span>
    </div>
    <div
      v-else-if="companies.length === 0"
      class="flex items-center justify-center p-8"
    >
      <span class="text-n-slate-11 text-base">{{
        t('COMPANIES.EMPTY_STATE.TITLE')
      }}</span>
    </div>
    <div v-else class="flex flex-col gap-4 p-4">
      <CompaniesCard
        v-for="company in companies"
        :id="company.id"
        :key="company.id"
        :name="company.name"
        :domain="company.domain"
        :contacts-count="company.contactsCount || 0"
        :description="company.description"
        :avatar-url="company.avatarUrl"
        :updated-at="company.updatedAt"
      />
    </div>
  </CompaniesListLayout>
</template>
