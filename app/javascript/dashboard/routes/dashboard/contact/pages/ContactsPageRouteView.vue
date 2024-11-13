<script setup>
import { onMounted, computed, ref, reactive, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
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
const router = useRouter();
const { t } = useI18n();

const { updateUISettings, uiSettings } = useUISettings();

const contacts = useMapGetter('contacts/getContactsList');
const uiFlags = useMapGetter('contacts/getUIFlags');
const customViewsUiFlags = useMapGetter('customViews/getUIFlags');
const segments = useMapGetter('customViews/getContactCustomViews');
const meta = useMapGetter('contacts/getMeta');

const searchQuery = computed(() => route.query?.search);
const searchValue = ref(searchQuery.value || '');
const pageNumber = computed(() => Number(route.query?.page) || 1);

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
const isFetchingList = computed(
  () => uiFlags.value.isFetching || customViewsUiFlags.value.isFetching
);
const currentPage = computed(() => Number(meta.value?.currentPage));
const totalItems = computed(() => meta.value?.count);
const activeSegment = computed(() =>
  activeSegmentId.value
    ? segments.value.find(view => view.id === Number(activeSegmentId.value))
    : undefined
);

const hasContacts = computed(() => contacts.value.length > 0);
const isContactIndexView = computed(
  () => route.name === 'contacts_dashboard_index' && pageNumber.value === 1
);

const headerTitle = computed(() => {
  if (searchQuery.value) {
    return t('CONTACTS_LAYOUT.HEADER.SEARCH_TITLE');
  }
  if (activeSegmentId.value) {
    return activeSegment.value?.name;
  }
  if (activeLabel.value) {
    return `#${activeLabel.value}`;
  }
  return t('CONTACTS_LAYOUT.HEADER.TITLE');
});

const updatePageParam = (page, search = searchValue.value) => {
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

const buildSortAttr = () =>
  `${sortState.activeOrdering}${sortState.activeSort}`;

const getCommonFetchParams = (page = 1) => ({
  page,
  sortAttr: buildSortAttr(),
  label: activeLabel.value,
});

const fetchContacts = async (page = 1) => {
  await store.dispatch('contacts/get', getCommonFetchParams(page));
  updatePageParam(page);
};

const fetchSavedFilteredContact = async (payload, page = 1) => {
  if (!activeSegmentId.value) return;

  await store.dispatch('contacts/filter', {
    ...getCommonFetchParams(page),
    queryPayload: payload,
  });
  updatePageParam(page);
};

const searchContacts = debounce(async (value, page = 1) => {
  searchValue.value = value;

  if (!value) {
    updatePageParam(page);
    await fetchContacts(page);
    return;
  }

  updatePageParam(page, value);
  await store.dispatch('contacts/search', {
    ...getCommonFetchParams(page),
    search: encodeURIComponent(value),
  });
}, DEBOUNCE_DELAY);

const handleSort = async ({ sort, order }) => {
  Object.assign(sortState, { activeSort: sort, activeOrdering: order });

  await updateUISettings({
    contacts_sort_by: buildSortAttr(),
  });

  if (searchQuery.value) {
    await searchContacts(searchValue.value, pageNumber.value);
    return;
  }

  await (activeSegmentId.value
    ? fetchSavedFilteredContact(activeSegment.value?.query, pageNumber.value)
    : fetchContacts(pageNumber.value));
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

watch(activeLabel, () => {
  if (searchQuery.value) return;

  searchValue.value = '';
  if (!activeSegmentId.value) {
    fetchContacts();
  }
});

watch(activeSegment, () => {
  if (searchQuery.value) return;

  searchValue.value = '';
  if (activeSegment.value && activeSegmentId.value) {
    fetchSavedFilteredContact(activeSegment.value.query, pageNumber.value);
  } else if (!activeLabel.value) {
    fetchContacts(pageNumber.value);
  }
});

watch(pageNumber, async page => {
  if (isFetchingList.value) return;

  if (searchQuery.value) {
    await searchContacts(searchQuery.value, page);
    return;
  }
  if (activeSegmentId.value) {
    await fetchSavedFilteredContact(activeSegment.value.query, page);
  } else {
    await fetchContacts(page);
  }
});

watch(searchQuery, value => {
  if (isFetchingList.value) return;
  searchValue.value = value || '';
  // Reset the view if there is search query when we click on the sidebar group
  if (value === undefined) {
    fetchContacts();
  }
});

onMounted(async () => {
  if (!activeSegmentId.value) {
    if (searchQuery.value) {
      await searchContacts(searchQuery.value, pageNumber.value);
      return;
    }
    await fetchContacts(pageNumber.value);
  } else if (activeSegment.value && activeSegmentId.value) {
    await fetchSavedFilteredContact(
      activeSegment.value.query,
      pageNumber.value
    );
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
      :is-empty-state="!searchQuery && !hasContacts && isContactIndexView"
      @update:current-page="page => updatePageParam(page, searchValue)"
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
          v-if="!searchQuery && !hasContacts && isContactIndexView"
          class="pt-14"
          :title="t('CONTACTS_LAYOUT.EMPTY_STATE.TITLE')"
          :subtitle="t('CONTACTS_LAYOUT.EMPTY_STATE.SUBTITLE')"
          :button-label="t('CONTACTS_LAYOUT.EMPTY_STATE.BUTTON_LABEL')"
        />

        <div
          v-else-if="(searchQuery || !isContactIndexView) && !hasContacts"
          class="flex items-center justify-center py-10"
        >
          <span class="text-base text-n-slate-11">
            {{
              searchQuery
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
