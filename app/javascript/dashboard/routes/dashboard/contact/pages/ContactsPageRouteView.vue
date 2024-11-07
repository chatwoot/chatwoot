<script setup>
import { onMounted, computed, ref, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { debounce } from '@chatwoot/utils';
import { useUISettings } from 'dashboard/composables/useUISettings';

import ContactsLayout from 'dashboard/components-next/Contacts/ContactsLayout.vue';
import ContactsList from 'dashboard/components-next/Contacts/Pages/ContactsList.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const DEFAULT_SORT_FIELD = 'last_activity_at';
const DEBOUNCE_DELAY = 300;

const store = useStore();
const { updateUISettings, uiSettings } = useUISettings();

const contacts = useMapGetter('contacts/getContactsList');
const uiFlags = useMapGetter('contacts/getUIFlags');
const meta = useMapGetter('contacts/getMeta');

const searchValue = ref('');

const parseSortSettings = (sortString = '') => {
  const hasDescending = sortString.startsWith('-');
  const sortField = hasDescending ? sortString.slice(1) : sortString;
  return {
    sort: sortField || DEFAULT_SORT_FIELD,
    order: hasDescending ? '-' : '',
  };
};

const { contacts_sort_by: contactSortBy = '' } = uiSettings.value ?? {};
const { sort: initialSort, order: initialOrder } =
  parseSortSettings(contactSortBy);

const activeSort = ref(initialSort);
const activeOrdering = ref(initialOrder);

const isFetchingList = computed(() => uiFlags.value.isFetching);

const currentPage = computed(() => Number(meta.value?.currentPage));
const totalItems = computed(() => meta.value?.count);

const buildSortAttr = (order, sort) => `${order}${sort}`;

const fetchContacts = page => {
  const sortAttr = buildSortAttr(activeOrdering.value, activeSort.value);
  store.dispatch('contacts/get', {
    page,
    sortAttr,
  });
};

const debouncedSearch = debounce(
  value => {
    searchValue.value = value;
    const sortAttr = buildSortAttr(activeOrdering.value, activeSort.value);
    if (!value) {
      fetchContacts(1);
    } else {
      store.dispatch('contacts/search', {
        search: encodeURIComponent(value),
        page: 1,
        sortAttr,
      });
    }
  },
  DEBOUNCE_DELAY,
  false
);

const searchContacts = value => {
  debouncedSearch(value);
};

const handleSort = async ({ sort, order }) => {
  activeSort.value = sort;
  activeOrdering.value = order;

  const sortString = buildSortAttr(order, sort);
  await updateUISettings({
    contacts_sort_by: sortString,
  });

  await fetchContacts(1);
};

watch(
  () => uiSettings.value?.contacts_sort_by,
  newSortBy => {
    if (newSortBy) {
      const { sort, order } = parseSortSettings(newSortBy);
      activeSort.value = sort;
      activeOrdering.value = order;
    }
  },
  { immediate: true }
);

onMounted(async () => {
  await fetchContacts(1);
});

const updateCurrentPage = page => fetchContacts(page);
</script>

<template>
  <div
    class="flex flex-col justify-between flex-1 h-full m-0 overflow-auto bg-n-background"
  >
    <ContactsLayout
      :header-title="$t('CONTACTS_LAYOUT.HEADER.TITLE')"
      :button-label="$t('CONTACTS_LAYOUT.HEADER.MESSAGE_BUTTON')"
      :current-page="currentPage"
      :total-items="totalItems"
      :show-pagination-footer="!isFetchingList && searchValue === ''"
      :active-sort="activeSort"
      :active-ordering="activeOrdering"
      @update:current-page="updateCurrentPage"
      @search="searchContacts"
      @sort="handleSort"
    >
      <div
        v-if="isFetchingList"
        class="flex items-center justify-center py-10 text-n-slate-11"
      >
        <Spinner />
      </div>
      <ContactsList v-else :contacts="contacts" />
    </ContactsLayout>
  </div>
</template>
