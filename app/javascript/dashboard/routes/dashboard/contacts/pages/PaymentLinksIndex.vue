<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';

import PaymentLinksListLayout from 'dashboard/components-next/PaymentLinks/PaymentLinksListLayout.vue';
import PaymentLinksTable from 'dashboard/components-next/PaymentLinks/PaymentLinksTable.vue';
import TableFooter from 'dashboard/components/widgets/TableFooter.vue';
import Spinner from 'shared/components/Spinner.vue';

const DEBOUNCE_DELAY = 300;

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const route = useRoute();

const paymentLinks = useMapGetter('paymentLinks/getPaymentLinks');
const uiFlags = useMapGetter('paymentLinks/getUIFlags');
const meta = useMapGetter('paymentLinks/getMeta');
const appliedFilters = useMapGetter(
  'paymentLinks/getAppliedPaymentLinkFiltersV4'
);

const isLoading = computed(() => uiFlags.value.fetchingList);
const noRecordsFound = computed(() => paymentLinks.value.length === 0);

const currentPage = computed(() => Number(route.query.page) || 1);
const searchQuery = computed(() => route.query?.search);
const searchValue = ref(searchQuery.value || '');

const activeSort = ref(route.query?.sort || 'created_at');
const activeOrdering = ref(route.query?.order || '-');

const hasAppliedFilters = computed(() => {
  return appliedFilters.value && appliedFilters.value.length > 0;
});

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

const fetchPaymentLinks = async (page = 1, sort = '', order = '') => {
  await store.dispatch('paymentLinks/clearPaymentLinkFilters');
  await store.dispatch('paymentLinks/fetch', { page, sort, order });
  updatePageParam(page, '', sort, order);
};

const fetchFilteredPaymentLinks = async (
  payload,
  page = 1,
  sort = '',
  order = ''
) => {
  if (!hasAppliedFilters.value) return;
  await store.dispatch('paymentLinks/filter', {
    page,
    queryPayload: payload,
    sort,
    order,
  });
  updatePageParam(page, '', sort, order);
};

const searchPaymentLinks = debounce(
  async (value, page = 1, sort = '', order = '') => {
    await store.dispatch('paymentLinks/clearPaymentLinkFilters');

    if (!value) {
      searchValue.value = '';
      updatePageParam(page, '', sort, order);
      await fetchPaymentLinks(page, sort, order);
      return;
    }

    searchValue.value = value;

    updatePageParam(page, value, sort, order);
    await store.dispatch('paymentLinks/search', {
      page,
      search: encodeURIComponent(value),
      sort,
      order,
    });
  },
  DEBOUNCE_DELAY
);

const fetchPaymentLinksBasedOnContext = async page => {
  const sort = activeSort.value;
  const order = activeOrdering.value;

  updatePageParam(page, searchValue.value, sort, order);
  if (isLoading.value) return;

  if (searchQuery.value) {
    await searchPaymentLinks(searchQuery.value, page, sort, order);
    return;
  }

  searchValue.value = '';

  if (hasAppliedFilters.value) {
    const queryPayload = filterQueryGenerator(appliedFilters.value);
    await fetchFilteredPaymentLinks(queryPayload, page, sort, order);
    return;
  }

  await fetchPaymentLinks(page, sort, order);
};

const onPageChange = page => {
  fetchPaymentLinksBasedOnContext(page);
};

const onSearch = value => {
  searchPaymentLinks(value, 1, activeSort.value, activeOrdering.value);
};

const onSortUpdate = ({ sort, order }) => {
  activeSort.value = sort;
  activeOrdering.value = order;
  fetchPaymentLinksBasedOnContext(1);
};

const onApplyFilter = async queryPayload => {
  // queryPayload is already processed by filterQueryGenerator in HeaderWrapper
  await fetchFilteredPaymentLinks(
    queryPayload,
    1,
    activeSort.value,
    activeOrdering.value
  );
};

const clearFilters = async () => {
  await fetchPaymentLinks(1, activeSort.value, activeOrdering.value);
};

watch(searchQuery, value => {
  if (isLoading.value) return;
  searchValue.value = value || '';
  if (value === undefined && !hasAppliedFilters.value) {
    fetchPaymentLinks(1, activeSort.value, activeOrdering.value);
  }
});

onMounted(async () => {
  if (searchQuery.value) {
    await searchPaymentLinks(
      searchQuery.value,
      currentPage.value,
      activeSort.value,
      activeOrdering.value
    );
    return;
  }
  if (hasAppliedFilters.value) {
    await fetchFilteredPaymentLinks(
      filterQueryGenerator(appliedFilters.value),
      currentPage.value,
      activeSort.value,
      activeOrdering.value
    );
    return;
  }
  await fetchPaymentLinks(
    currentPage.value,
    activeSort.value,
    activeOrdering.value
  );
});
</script>

<template>
  <PaymentLinksListLayout
    :search-value="searchValue"
    :header-title="t('PAYMENT_LINKS.HEADER')"
    :show-pagination-footer="false"
    :current-page="meta.currentPage"
    :total-items="meta.totalEntries"
    :items-per-page="meta.perPage"
    :active-sort="activeSort"
    :active-ordering="activeOrdering"
    :has-applied-filters="hasAppliedFilters"
    :is-fetching-list="isLoading"
    @update:current-page="onPageChange"
    @update:sort="onSortUpdate"
    @search="onSearch"
    @apply-filter="onApplyFilter"
    @clear-filters="clearFilters"
  >
    <div class="flex flex-col gap-4 px-6 pb-6">
      <!-- Loading State -->
      <div v-if="isLoading" class="flex justify-center py-10">
        <Spinner size="large" />
      </div>

      <!-- Empty State (no results at all) -->
      <div
        v-else-if="
          noRecordsFound && !searchValue && !hasAppliedFilters && !isLoading
        "
        class="flex flex-col items-center justify-center py-20"
      >
        <span class="text-lg text-n-slate-11">
          {{ t('PAYMENT_LINKS.EMPTY_STATE') }}
        </span>
      </div>

      <!-- Table -->
      <PaymentLinksTable
        v-else
        :payment-links="paymentLinks"
        :no-records-found="noRecordsFound"
        :search-value="searchValue"
        :has-applied-filters="hasAppliedFilters"
      />

      <!-- Pagination -->
      <TableFooter
        v-if="paymentLinks.length > 0"
        :current-page="meta.currentPage"
        :page-size="meta.perPage"
        :total-count="meta.totalEntries"
        @page-change="onPageChange"
      />
    </div>
  </PaymentLinksListLayout>
</template>
