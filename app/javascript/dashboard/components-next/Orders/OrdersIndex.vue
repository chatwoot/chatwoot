<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';

import OrdersListLayout from 'dashboard/components-next/Orders/OrdersListLayout.vue';
import OrdersTable from 'dashboard/components-next/Orders/OrdersTable.vue';
import TableFooter from 'dashboard/components/widgets/TableFooter.vue';
import Spinner from 'shared/components/Spinner.vue';

const DEBOUNCE_DELAY = 300;

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const route = useRoute();

const orders = useMapGetter('orders/getOrders');
const uiFlags = useMapGetter('orders/getUIFlags');
const meta = useMapGetter('orders/getMeta');

const isLoading = computed(() => uiFlags.value.fetchingList);
const noRecordsFound = computed(() => orders.value.length === 0);

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

const fetchOrders = async (page = 1, sort = '', order = '') => {
  await store.dispatch('orders/fetch', { page, sort, order });
  updatePageParam(page, '', sort, order);
};

const searchOrders = debounce(
  async (value, page = 1, sort = '', order = '') => {
    if (!value) {
      searchValue.value = '';
      updatePageParam(page, '', sort, order);
      await fetchOrders(page, sort, order);
      return;
    }

    searchValue.value = value;

    updatePageParam(page, value, sort, order);
    await store.dispatch('orders/search', {
      page,
      search: encodeURIComponent(value),
      sort,
      order,
    });
  },
  DEBOUNCE_DELAY
);

const fetchOrdersBasedOnContext = async page => {
  const sort = activeSort.value;
  const order = activeOrdering.value;

  updatePageParam(page, searchValue.value, sort, order);
  if (isLoading.value) return;

  if (searchQuery.value) {
    await searchOrders(searchQuery.value, page, sort, order);
    return;
  }

  searchValue.value = '';
  await fetchOrders(page, sort, order);
};

const onPageChange = page => {
  fetchOrdersBasedOnContext(page);
};

const onSearch = value => {
  searchOrders(value, 1, activeSort.value, activeOrdering.value);
};

const onSortUpdate = ({ sort, order }) => {
  activeSort.value = sort;
  activeOrdering.value = order;
  fetchOrdersBasedOnContext(1);
};

watch(searchQuery, value => {
  if (isLoading.value) return;
  searchValue.value = value || '';
  if (value === undefined) {
    fetchOrders(1, activeSort.value, activeOrdering.value);
  }
});

onMounted(async () => {
  if (searchQuery.value) {
    await searchOrders(
      searchQuery.value,
      currentPage.value,
      activeSort.value,
      activeOrdering.value
    );
    return;
  }
  await fetchOrders(currentPage.value, activeSort.value, activeOrdering.value);
});
</script>

<template>
  <OrdersListLayout
    :search-value="searchValue"
    :header-title="t('ORDERS_LIST.HEADER')"
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
          {{ t('ORDERS_LIST.EMPTY_STATE') }}
        </span>
      </div>

      <!-- Table -->
      <OrdersTable
        v-else
        :orders="orders"
        :no-records-found="noRecordsFound"
        :search-value="searchValue"
      />

      <!-- Pagination -->
      <TableFooter
        v-if="orders.length > 0"
        :current-page="meta.currentPage"
        :page-size="meta.perPage"
        :total-count="meta.totalEntries"
        @page-change="onPageChange"
      />
    </div>
  </OrdersListLayout>
</template>
