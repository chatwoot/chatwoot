<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { debounce } from '@chatwoot/utils';

import CompaniesListLayout from 'dashboard/components-next/Companies/CompaniesListLayout.vue';
import CompaniesCard from 'dashboard/components-next/Companies/CompaniesCard/CompaniesCard.vue';

const DEBOUNCE_DELAY = 300;

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const searchQuery = computed(() => route.query?.search || '');
const searchValue = ref(searchQuery.value);
const pageNumber = computed(() => Number(route.query?.page) || 1);

const activeSort = computed(() => {
  const sortParam = route.query?.sort || 'name';
  return sortParam.startsWith('-') ? sortParam.slice(1) : sortParam;
});

const activeOrdering = computed(() => {
  const sortParam = route.query?.sort || 'name';
  return sortParam.startsWith('-') ? '-' : '';
});

const companies = useMapGetter('companies/getCompaniesList');
const meta = useMapGetter('companies/getMeta');
const uiFlags = useMapGetter('companies/getUIFlags');

const isFetchingList = computed(() => uiFlags.value.fetchingList);

const sortParam = computed(() => {
  return activeOrdering.value === '-'
    ? `-${activeSort.value}`
    : activeSort.value;
});

const updateURLParams = (page, search = '', sort = '') => {
  const query = {
    ...route.query,
    page: page.toString(),
  };

  if (search) {
    query.search = search;
  } else {
    delete query.search;
  }

  if (sort) {
    query.sort = sort;
  } else {
    delete query.sort;
  }

  router.replace({ query });
};

const fetchCompanies = async (page, search, sort) => {
  const currentPage = page ?? pageNumber.value;
  const currentSearch = search ?? searchQuery.value;
  const currentSort = sort ?? sortParam.value;

  // Only update URL if arguments were explicitly provided
  if (page !== undefined || search !== undefined || sort !== undefined) {
    updateURLParams(currentPage, currentSearch, currentSort);
  }

  if (currentSearch) {
    await store.dispatch('companies/search', {
      search: currentSearch,
      page: currentPage,
      sort: currentSort,
    });
  } else {
    await store.dispatch('companies/get', {
      page: currentPage,
      sort: currentSort,
    });
  }
};

const onSearch = debounce(query => {
  searchValue.value = query;
  fetchCompanies(1, query, sortParam.value);
}, DEBOUNCE_DELAY);

const onPageChange = page => {
  fetchCompanies(page, searchValue.value, sortParam.value);
};

const handleSort = ({ sort, order }) => {
  const newSortParam = order === '-' ? `-${sort}` : sort;
  fetchCompanies(1, searchValue.value, newSortParam);
};

onMounted(() => {
  searchValue.value = searchQuery.value;
  fetchCompanies();
});
</script>

<template>
  <CompaniesListLayout
    :search-value="searchValue"
    :header-title="t('COMPANIES.HEADER')"
    :current-page="pageNumber"
    :total-items="Number(meta.totalCount || 0)"
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
