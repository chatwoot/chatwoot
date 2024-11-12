<script setup>
import { onMounted, computed, ref, reactive, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { debounce } from '@chatwoot/utils';
import { useUISettings } from 'dashboard/composables/useUISettings';

import ContactsLayout from 'dashboard/components-next/Contacts/ContactsLayout.vue';
import ContactsList from 'dashboard/components-next/Contacts/Pages/ContactsList.vue';
import ContactEmptyState from 'dashboard/components-next/Contacts/EmptyState/ContactEmptyState.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const DEFAULT_SORT_FIELD = 'last_activity_at';
const DEBOUNCE_DELAY = 300;

const store = useStore();
const route = useRoute();
const { t } = useI18n();

const { updateUISettings, uiSettings } = useUISettings();

const contacts = useMapGetter('contacts/getContactsList');
const uiFlags = useMapGetter('contacts/getUIFlags');
const segments = useMapGetter('customViews/getContactCustomViews');
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

const sortState = reactive({
  activeSort: initialSort,
  activeOrdering: initialOrder,
});

const activeLabel = computed(() => route.params.label);
const activeSegmentId = computed(() => route.params.segmentId);
const isFetchingList = computed(() => uiFlags.value.isFetching);
const currentPage = computed(() => Number(meta.value?.currentPage));
const totalItems = computed(() => meta.value?.count);
const activeSegment = computed(() =>
  activeSegmentId.value
    ? segments.value.find(view => view.id === Number(activeSegmentId.value))
    : undefined
);

const hasContacts = computed(() => contacts.value.length > 0);
const isContactIndexView = computed(
  () => route.name === 'contacts_dashboard_index'
);

const headerTitle = computed(() => {
  if (activeSegmentId.value) {
    return activeSegment.value.name;
  }
  if (activeLabel.value) {
    return `#${activeLabel.value}`;
  }
  return t('CONTACTS_LAYOUT.HEADER.TITLE');
});

const buildSortAttr = () =>
  `${sortState.activeOrdering}${sortState.activeSort}`;

const fetchContacts = async (page = 1) => {
  await store.dispatch('contacts/get', {
    page,
    sortAttr: buildSortAttr(),
    label: activeLabel.value,
  });
};

const fetchSavedFilteredContact = async (payload, page = 1) => {
  if (activeSegmentId.value) {
    await store.dispatch('contacts/filter', {
      queryPayload: payload,
      page,
      sortAttr: buildSortAttr(),
    });
  }
};

const searchContacts = debounce(async (value, page = 1) => {
  searchValue.value = value;
  if (!value) {
    if (activeSegmentId.value) {
      await fetchSavedFilteredContact(activeSegment.value.query);
    } else {
      await fetchContacts();
    }
    return;
  }

  await store.dispatch('contacts/search', {
    search: encodeURIComponent(value),
    page,
    sortAttr: buildSortAttr(),
    label: activeLabel.value,
  });
}, DEBOUNCE_DELAY);

const handleSort = async ({ sort, order }) => {
  sortState.activeSort = sort;
  sortState.activeOrdering = order;

  await updateUISettings({
    contacts_sort_by: buildSortAttr(),
  });
  if (activeSegmentId.value) {
    await fetchSavedFilteredContact(activeSegment.value.query);
  } else {
    await fetchContacts();
  }
};

watch(
  () => uiSettings.value?.contacts_sort_by,
  newSortBy => {
    if (newSortBy) {
      const { sort, order } = parseSortSettings(newSortBy);
      sortState.activeSort = sort;
      sortState.activeOrdering = order;
    }
  },
  { immediate: true }
);

const handlePageChange = async page => {
  if (searchValue.value) {
    await searchContacts(searchValue.value, page);
    return;
  }
  if (activeSegmentId.value) {
    await fetchSavedFilteredContact(activeSegment.value.query, page);
  } else {
    await fetchContacts(page);
  }
};

watch(activeLabel, () => {
  if (!activeSegmentId.value) {
    fetchContacts();
  }
});

watch(activeSegment, () => {
  if (activeSegment.value && activeSegmentId.value) {
    fetchSavedFilteredContact(activeSegment.value.query);
  } else if (!activeLabel.value) {
    fetchContacts();
  }
});

onMounted(async () => {
  if (!activeSegmentId.value) {
    await fetchContacts();
  } else if (activeSegment.value && activeSegmentId.value) {
    fetchSavedFilteredContact(activeSegment.value.query);
  }
});
</script>

<template>
  <div
    class="flex flex-col justify-between flex-1 h-full m-0 overflow-auto bg-n-background"
  >
    <ContactsLayout
      :search-value="searchValue"
      :header-title="headerTitle"
      :button-label="$t('CONTACTS_LAYOUT.HEADER.MESSAGE_BUTTON')"
      :current-page="currentPage"
      :total-items="totalItems"
      :show-pagination-footer="!isFetchingList && hasContacts"
      :active-sort="sortState.activeSort"
      :active-ordering="sortState.activeOrdering"
      :is-empty-state="!searchValue && !hasContacts && isContactIndexView"
      @update:current-page="handlePageChange"
      @search="searchContacts"
      @sort="handleSort"
    >
      <div
        v-if="isFetchingList"
        class="flex items-center justify-center py-10 text-n-slate-11"
      >
        <Spinner />
      </div>

      <template v-else>
        <ContactEmptyState
          v-if="!searchValue && !hasContacts && isContactIndexView"
          class="pt-14"
          :title="t('CONTACTS_LAYOUT.EMPTY_STATE.TITLE')"
          :subtitle="t('CONTACTS_LAYOUT.EMPTY_STATE.SUBTITLE')"
          :button-label="t('CONTACTS_LAYOUT.EMPTY_STATE.BUTTON_LABEL')"
        />

        <div
          v-else-if="(searchValue || !isContactIndexView) && !hasContacts"
          class="flex items-center justify-center py-10"
        >
          <span class="text-base text-n-slate-11">
            {{
              searchValue
                ? t('CONTACTS_LAYOUT.EMPTY_STATE.SEARCH_EMPTY_STATE_TITLE')
                : t('CONTACTS_LAYOUT.EMPTY_STATE.LIST_EMPTY_STATE_TITLE')
            }}
          </span>
        </div>

        <ContactsList v-else :contacts="contacts" />
      </template>
    </ContactsLayout>
  </div>
</template>
