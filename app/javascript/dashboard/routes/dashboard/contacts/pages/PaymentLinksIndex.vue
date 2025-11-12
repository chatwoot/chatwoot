<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter, useRoute } from 'vue-router';
import { debounce } from '@chatwoot/utils';
import { format } from 'date-fns';
import { usePaymentLinkStatus } from 'dashboard/composables/usePaymentLinkStatus';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';

import TableFooter from 'dashboard/components/widgets/TableFooter.vue';
import SettingsLayout from '../../settings/SettingsLayout.vue';
import BaseSettingsHeader from '../../settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import PaymentLinksFilter from 'dashboard/components-next/filter/PaymentLinksFilter.vue';

const DEBOUNCE_DELAY = 300;

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

const hasAppliedFilters = computed(() => {
  return appliedFilters.value && appliedFilters.value.length > 0;
});

const showFiltersModal = ref(false);
const appliedFilter = ref([]);

const updatePageParam = (page, search = '') => {
  const query = {
    ...route.query,
    page: page.toString(),
    ...(search ? { search } : {}),
  };

  if (!search) {
    delete query.search;
  }

  router.replace({ query });
};

const fetchPaymentLinks = async (page = 1) => {
  await store.dispatch('paymentLinks/clearPaymentLinkFilters');
  await store.dispatch('paymentLinks/fetch', { page });
  updatePageParam(page);
};

const fetchFilteredPaymentLinks = async (payload, page = 1) => {
  if (!hasAppliedFilters.value) return;
  await store.dispatch('paymentLinks/filter', {
    page,
    queryPayload: payload,
  });
  updatePageParam(page);
};

const searchPaymentLinks = debounce(async (value, page = 1) => {
  await store.dispatch('paymentLinks/clearPaymentLinkFilters');
  searchValue.value = value;

  if (!value) {
    updatePageParam(page);
    await fetchPaymentLinks(page);
    return;
  }

  updatePageParam(page, value);
  await store.dispatch('paymentLinks/search', {
    page,
    search: encodeURIComponent(value),
  });
}, DEBOUNCE_DELAY);

const fetchPaymentLinksBasedOnContext = async page => {
  updatePageParam(page, searchValue.value);
  if (isLoading.value) return;

  if (searchQuery.value) {
    await searchPaymentLinks(searchQuery.value, page);
    return;
  }

  searchValue.value = '';

  if (hasAppliedFilters.value) {
    const queryPayload = filterQueryGenerator(appliedFilters.value);
    await fetchFilteredPaymentLinks(queryPayload, page);
    return;
  }

  await fetchPaymentLinks(page);
};

const onPageChange = page => {
  fetchPaymentLinksBasedOnContext(page);
};

const formatDate = dateString => {
  if (!dateString) return '-';
  return format(new Date(dateString), 'MMM d, yyyy h:mm a');
};

const copyToClipboard = async url => {
  try {
    await navigator.clipboard.writeText(url);
  } catch (err) {
    // Failed to copy
  }
};

const navigateToConversation = (accountId, conversationId) => {
  router.push({
    name: 'inbox_conversation',
    params: { accountId, conversation_id: conversationId },
  });
};

const navigateToContact = (accountId, contactId) => {
  router.push({
    name: 'contact_profile',
    params: { accountId, id: contactId },
  });
};

const getStatusBadgeClasses = status => {
  const { statusBadgeBg, statusBadgeText, iconName } =
    usePaymentLinkStatus(status);
  return {
    bg: statusBadgeBg.value,
    text: statusBadgeText.value,
    icon: iconName.value,
  };
};

const onToggleFilters = () => {
  appliedFilter.value = hasAppliedFilters.value
    ? [...appliedFilters.value]
    : [
        {
          attributeKey: 'status',
          filterOperator: 'equal_to',
          values: [],
          queryOperator: 'and',
          attributeModel: 'standard',
        },
      ];
  showFiltersModal.value = true;
};

const closeFiltersModal = () => {
  showFiltersModal.value = false;
  appliedFilter.value = [];
};

const onApplyFilter = async payload => {
  store.dispatch('paymentLinks/setPaymentLinkFilters', payload);
  const queryPayload = filterQueryGenerator(payload);
  await fetchFilteredPaymentLinks(queryPayload, 1);
  showFiltersModal.value = false;
};

const clearFilters = async () => {
  await fetchPaymentLinks(1);
};

watch(searchQuery, value => {
  if (isLoading.value) return;
  searchValue.value = value || '';
  if (value === undefined && !hasAppliedFilters.value) {
    fetchPaymentLinks();
  }
});

onMounted(async () => {
  if (searchQuery.value) {
    await searchPaymentLinks(searchQuery.value, currentPage.value);
    return;
  }
  if (hasAppliedFilters.value) {
    await fetchFilteredPaymentLinks(
      filterQueryGenerator(appliedFilters.value),
      currentPage.value
    );
    return;
  }
  await fetchPaymentLinks(currentPage.value);
});
</script>

<template>
  <div
    class="flex flex-col w-full h-full m-0 p-6 sm:py-8 lg:px-16 overflow-auto bg-n-background font-inter"
  >
    <div class="flex items-start w-full max-w-6xl mx-auto">
      <SettingsLayout
        :is-loading="isLoading"
        :loading-message="$t('PAYMENT_LINKS.LOADING')"
        :no-records-found="noRecordsFound && !searchValue && !hasAppliedFilters"
        :no-records-message="$t('PAYMENT_LINKS.EMPTY_STATE')"
      >
        <template #header>
          <BaseSettingsHeader
            :title="$t('PAYMENT_LINKS.HEADER')"
            :description="$t('PAYMENT_LINKS.DESCRIPTION')"
          />
        </template>

        <template #body>
          <div class="flex flex-col gap-4">
            <!-- Search and Filter Header -->
            <div class="flex items-center justify-between gap-3">
              <!-- Search Input -->
              <div class="relative flex-1 max-w-md">
                <Input
                  v-model="searchValue"
                  type="search"
                  :placeholder="$t('PAYMENT_LINKS.FILTERS.SEARCH_PLACEHOLDER')"
                  :custom-input-class="[
                    'h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8',
                  ]"
                  @update:model-value="searchPaymentLinks"
                >
                  <template #prefix>
                    <Icon
                      icon="i-lucide-search"
                      class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2 rtl:right-2"
                    />
                  </template>
                </Input>
              </div>

              <!-- Filter Button -->
              <div class="relative">
                <Button
                  id="togglePaymentLinksFilterButton"
                  icon="i-lucide-filter"
                  slate
                  faded
                  sm
                  @click="onToggleFilters"
                >
                  {{ $t('PAYMENT_LINKS.FILTER.TITLE') }}
                  <span
                    v-if="hasAppliedFilters"
                    class="absolute top-0 right-0 w-2 h-2 rounded-full bg-n-iris-9"
                  />
                </Button>

                <!-- Filter Modal -->
                <div
                  v-if="showFiltersModal"
                  class="absolute mt-1 ltr:right-0 rtl:left-0 top-full"
                >
                  <PaymentLinksFilter
                    v-model="appliedFilter"
                    @apply-filter="onApplyFilter"
                    @close="closeFiltersModal"
                    @clear-filters="clearFilters"
                  />
                </div>
              </div>
            </div>

            <!-- Empty State for Search/Filters -->
            <div
              v-if="noRecordsFound && (searchValue || hasAppliedFilters)"
              class="flex items-center justify-center py-10"
            >
              <span class="text-base text-n-slate-11">
                {{
                  searchValue
                    ? 'No payment links found matching your search'
                    : 'No payment links found matching your filters'
                }}
              </span>
            </div>

            <!-- Payment Links Table -->
            <table
              v-if="!noRecordsFound || searchValue || hasAppliedFilters"
              class="min-w-full divide-y divide-n-weak"
            >
              <thead>
                <tr>
                  <th
                    class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
                  >
                    {{ $t('PAYMENT_LINKS.TABLE.PAYMENT_ID') }}
                  </th>
                  <th
                    class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
                  >
                    {{ $t('PAYMENT_LINKS.TABLE.CONTACT') }}
                  </th>
                  <th
                    class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
                  >
                    {{ $t('PAYMENT_LINKS.TABLE.AMOUNT') }}
                  </th>
                  <th
                    class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
                  >
                    {{ $t('PAYMENT_LINKS.TABLE.STATUS') }}
                  </th>
                  <th
                    class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
                  >
                    {{ $t('PAYMENT_LINKS.TABLE.CREATED_BY') }}
                  </th>
                  <th
                    class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
                  >
                    {{ $t('PAYMENT_LINKS.TABLE.CONVERSATION') }}
                  </th>
                  <th
                    class="py-4 ltr:pr-4 rtl:pl-4 text-left font-semibold text-n-slate-11"
                  >
                    {{ $t('PAYMENT_LINKS.TABLE.ACTIONS') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-n-weak text-n-slate-12">
                <tr v-for="paymentLink in paymentLinks" :key="paymentLink.id">
                  <td class="py-4 ltr:pr-4 rtl:pl-4">
                    <div class="flex flex-col gap-0.5">
                      <span class="font-medium">{{
                        paymentLink.payment_id
                      }}</span>
                      <span class="text-xs text-n-slate-11">{{
                        formatDate(paymentLink.created_at)
                      }}</span>
                    </div>
                  </td>
                  <td class="py-4 ltr:pr-4 rtl:pl-4">
                    <button
                      v-if="paymentLink.contact"
                      class="text-n-iris-9 hover:text-n-iris-10 hover:underline"
                      @click="
                        navigateToContact(
                          $store.state.auth.currentAccountId,
                          paymentLink.contact.id
                        )
                      "
                    >
                      {{
                        paymentLink.contact.name ||
                        paymentLink.contact.email ||
                        paymentLink.contact.phone_number
                      }}
                    </button>
                    <span v-else class="text-n-slate-11">-</span>
                  </td>
                  <td class="py-4 ltr:pr-4 rtl:pl-4 font-medium">
                    {{ paymentLink.amount }} {{ paymentLink.currency }}
                  </td>
                  <td class="py-4 ltr:pr-4 rtl:pl-4">
                    <span
                      class="inline-flex items-center gap-1.5 px-2 py-1 rounded-full text-xs font-medium"
                      :class="[
                        getStatusBadgeClasses(paymentLink.status).bg,
                        getStatusBadgeClasses(paymentLink.status).text,
                      ]"
                    >
                      <span
                        :class="getStatusBadgeClasses(paymentLink.status).icon"
                        class="text-sm"
                      />
                      <span>{{
                        $t(
                          `PAYMENT_LINKS.STATUS.${paymentLink.status.toUpperCase()}`
                        )
                      }}</span>
                    </span>
                  </td>
                  <td class="py-4 ltr:pr-4 rtl:pl-4 text-n-slate-11">
                    {{ paymentLink.created_by?.name || '-' }}
                  </td>
                  <td class="py-4 ltr:pr-4 rtl:pl-4">
                    <button
                      v-if="paymentLink.conversation"
                      class="text-n-iris-9 hover:text-n-iris-10 hover:underline"
                      @click="
                        navigateToConversation(
                          $store.state.auth.currentAccountId,
                          paymentLink.conversation.id
                        )
                      "
                    >
                      #{{ paymentLink.conversation.display_id }}
                    </button>
                    <span v-else class="text-n-slate-11">-</span>
                  </td>
                  <td class="py-4 ltr:pr-4 rtl:pl-4">
                    <div class="flex items-center gap-2">
                      <Button
                        v-tooltip.top="$t('PAYMENT_LINKS.TABLE.COPY_URL')"
                        icon="i-lucide-copy"
                        slate
                        xs
                        faded
                        @click="copyToClipboard(paymentLink.payment_url)"
                      />
                      <Button
                        v-tooltip.top="$t('PAYMENT_LINKS.TABLE.VIEW_PAYMENT')"
                        icon="i-lucide-external-link"
                        slate
                        xs
                        faded
                        tag="a"
                        :href="paymentLink.payment_url"
                        target="_blank"
                        rel="noopener noreferrer"
                      />
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>

            <TableFooter
              v-if="paymentLinks.length > 0"
              :current-page="meta.currentPage"
              :page-size="meta.perPage"
              :total-count="meta.totalEntries"
              @page-change="onPageChange"
            />
          </div>
        </template>
      </SettingsLayout>
    </div>
  </div>
</template>
