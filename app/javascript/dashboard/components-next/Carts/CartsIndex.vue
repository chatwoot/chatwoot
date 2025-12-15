<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';

import CartsListLayout from 'dashboard/components-next/Carts/CartsListLayout.vue';
import CartsTable from 'dashboard/components-next/Carts/CartsTable.vue';
import TableFooter from 'dashboard/components/widgets/TableFooter.vue';
import Spinner from 'shared/components/Spinner.vue';

const DEBOUNCE_DELAY = 300;

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const route = useRoute();

const carts = useMapGetter('carts/getCarts');
const uiFlags = useMapGetter('carts/getUIFlags');
const meta = useMapGetter('carts/getMeta');

const isLoading = computed(() => uiFlags.value.fetchingList);
const noRecordsFound = computed(() => carts.value.length === 0);

const currentPage = computed(() => Number(route.query.page) || 1);
const searchQuery = computed(() => route.query?.search);
const searchValue = ref(searchQuery.value || '');

const activeSort = ref(route.query?.sort || 'created_at');
const activeOrdering = ref(route.query?.order || '-');

const updatePageParam = (page, search = '', sort = '', order = '') => {
  const query = {
    ...route.query,
    page: page.toString(),
    ...(search ? { search } : {}),
    ...(sort ? { sort } : {}),
    ...(order ? { order } : {}),
  };

  if (!search) {
    delete query.search;
  }
  if (!sort) {
    delete query.sort;
  }
  if (!order) {
    delete query.order;
  }

  router.replace({ query });
};

const fetchCarts = async (page = 1, sort = '', order = '') => {
  await store.dispatch('carts/fetch', { page, sort, order });
  updatePageParam(page, '', sort, order);
};

const searchCarts = debounce(async (value, page = 1, sort = '', order = '') => {
  if (!value) {
    searchValue.value = '';
    updatePageParam(page, '', sort, order);
    await fetchCarts(page, sort, order);
    return;
  }

  searchValue.value = value;

  updatePageParam(page, value, sort, order);
  await store.dispatch('carts/search', {
    page,
    search: encodeURIComponent(value),
    sort,
    order,
  });
}, DEBOUNCE_DELAY);

const fetchCartsBasedOnContext = async page => {
  const sort = activeSort.value;
  const order = activeOrdering.value;

  updatePageParam(page, searchValue.value, sort, order);
  if (isLoading.value) return;

  if (searchQuery.value) {
    await searchCarts(searchQuery.value, page, sort, order);
    return;
  }

  searchValue.value = '';
  await fetchCarts(page, sort, order);
};

const onPageChange = page => {
  fetchCartsBasedOnContext(page);
};

const onSearch = value => {
  searchCarts(value, 1, activeSort.value, activeOrdering.value);
};

const onSortUpdate = ({ sort, order }) => {
  activeSort.value = sort;
  activeOrdering.value = order;
  fetchCartsBasedOnContext(1);
};

watch(searchQuery, value => {
  if (isLoading.value) return;
  searchValue.value = value || '';
  if (value === undefined) {
    fetchCarts(1, activeSort.value, activeOrdering.value);
  }
});

onMounted(async () => {
  if (searchQuery.value) {
    await searchCarts(
      searchQuery.value,
      currentPage.value,
      activeSort.value,
      activeOrdering.value
    );
    return;
  }
  await fetchCarts(currentPage.value, activeSort.value, activeOrdering.value);
});
</script>

<template>
  <CartsListLayout
    :search-value="searchValue"
    :header-title="t('CARTS_LIST.HEADER')"
    :show-pagination-footer="false"
    :current-page="meta.currentPage"
    :total-items="meta.totalEntries"
    :items-per-page="meta.perPage"
    :active-sort="activeSort"
    :active-ordering="activeOrdering"
    @update:current-page="onPageChange"
    @update:sort="onSortUpdate"
    @search="onSearch"
  >
    <div class="flex flex-col gap-4 px-6 pb-6">
      <!-- Loading State -->
      <div v-if="isLoading" class="flex justify-center py-10">
        <Spinner size="large" />
      </div>

      <!-- Empty State (no results at all) -->
      <div
        v-else-if="noRecordsFound && !searchValue && !isLoading"
        class="flex flex-col items-center justify-center py-20"
      >
        <span class="text-lg text-n-slate-11">
          {{ t('CARTS_LIST.EMPTY_STATE') }}
        </span>
      </div>

      <!-- Table -->
      <CartsTable
        v-else
        :carts="carts"
        :no-records-found="noRecordsFound"
        :search-value="searchValue"
      />

      <!-- Pagination -->
      <TableFooter
        v-if="carts.length > 0"
        :current-page="meta.currentPage"
        :page-size="meta.perPage"
        :total-count="meta.totalEntries"
        @page-change="onPageChange"
      />
    </div>
  </CartsListLayout>
</template>
