<script setup>
import { onMounted, computed, ref, reactive, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { debounce } from '@chatwoot/utils';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import AppointmentsList from 'dashboard/components-next/Contacts/Pages/AppointmentsList.vue';
import AppointmentsHeader from 'dashboard/components-next/Contacts/ContactsHeader/AppointmentsHeader.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';

const DEFAULT_SORT_FIELD = 'start_time';
const DEBOUNCE_DELAY = 300;

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const appointments = useMapGetter('appointments/getAppointments');
const uiFlags = useMapGetter('appointments/getUIFlags');
const meta = useMapGetter('appointments/getMeta');
const appliedFilters = useMapGetter('appointments/getAppliedFilters');

const searchQuery = computed(() => route.query?.search);
const searchValue = ref(searchQuery.value || '');
const pageNumber = computed(() => Number(route.query?.page) || 1);

const sortState = reactive({
  activeSort: DEFAULT_SORT_FIELD,
  activeOrdering: '-',
});

const isFetching = computed(() => uiFlags.value.isFetching);
const hasAppointments = computed(
  () => appointments.value && appointments.value.length > 0
);
const currentPage = computed(() => Number(meta.value?.currentPage));
const totalItems = computed(() => meta.value?.count);
const hasAppliedFilters = computed(() => appliedFilters.value.length > 0);

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

const buildSortAttr = () =>
  `${sortState.activeOrdering}${sortState.activeSort}`;

const fetchAppointments = async (page = 1) => {
  await store.dispatch('appointments/get', {
    page,
    sortAttr: buildSortAttr(),
  });
  updatePageParam(page);
};

const searchAppointments = debounce(async (value, page = 1) => {
  searchValue.value = value;

  if (!value) {
    updatePageParam(page);
    await fetchAppointments(page);
    return;
  }

  updatePageParam(page, value);
  await store.dispatch('appointments/search', {
    search: value,
    page,
    sortAttr: buildSortAttr(),
  });
}, DEBOUNCE_DELAY);

const fetchFilteredAppointments = async ({ payload }, page = 1) => {
  if (!hasAppliedFilters.value) return;
  await store.dispatch('appointments/filter', {
    queryPayload: payload,
    page,
    sortAttr: buildSortAttr(),
  });
  updatePageParam(page);
};

const fetchAppointmentsBasedOnContext = async page => {
  updatePageParam(page, searchValue.value);
  if (isFetching.value) return;

  if (hasAppliedFilters.value) {
    await fetchFilteredAppointments(appliedFilters.value, page);
    return;
  }

  if (searchQuery.value) {
    await searchAppointments(searchQuery.value, page);
    return;
  }

  searchValue.value = '';
  await fetchAppointments(page);
};

const handleSort = async ({ sort, order }) => {
  Object.assign(sortState, { activeSort: sort, activeOrdering: order });

  if (hasAppliedFilters.value) {
    await fetchFilteredAppointments(appliedFilters.value);
    return;
  }

  if (searchQuery.value) {
    await searchAppointments(searchValue.value);
    return;
  }

  await fetchAppointments();
};

const applyFilter = async payload => {
  const queryPayload = filterQueryGenerator(payload);
  await fetchFilteredAppointments(queryPayload);
};

const clearFilters = async () => {
  await store.dispatch('appointments/clearAppointmentFilters');
  await fetchAppointments();
};

watch(searchQuery, value => {
  if (isFetching.value) return;
  searchValue.value = value || '';
  if (value === undefined) {
    fetchAppointments();
  }
});

onMounted(async () => {
  if (searchQuery.value) {
    await searchAppointments(searchQuery.value, pageNumber.value);
    return;
  }
  await fetchAppointments(pageNumber.value);
});
</script>

<template>
  <div
    class="flex flex-col justify-between flex-1 h-full m-0 overflow-auto bg-n-background"
  >
    <section
      class="flex w-full h-full gap-4 overflow-hidden justify-evenly bg-n-background"
    >
      <div class="flex flex-col w-full h-full transition-all duration-300">
        <AppointmentsHeader
          :search-value="searchValue"
          :active-sort="sortState.activeSort"
          :active-ordering="sortState.activeOrdering"
          :header-title="t('APPOINTMENTS.HEADER.TITLE')"
          :show-search
          :has-active-filters="hasAppliedFilters"
          @update:sort="handleSort"
          @search="searchAppointments"
          @apply-filter="applyFilter"
          @clear-filters="clearFilters"
        />

        <main class="flex-1 overflow-y-auto">
          <div class="w-full mx-auto max-w-[60rem]">
            <div
              v-if="isFetching"
              class="flex items-center justify-center py-10 text-n-slate-11"
            >
              <Spinner />
            </div>

            <div
              v-else-if="!hasAppointments"
              class="flex items-center justify-center py-10"
            >
              <span class="text-base text-n-slate-11">
                {{ t('APPOINTMENTS.EMPTY_STATE') }}
              </span>
            </div>

            <AppointmentsList v-else :appointments="appointments" />
          </div>
        </main>

        <footer
          v-if="!isFetching && hasAppointments"
          class="sticky bottom-0 z-0 px-4 pb-4"
        >
          <PaginationFooter
            :current-page="currentPage"
            :total-items="totalItems"
            @update:current-page="fetchAppointmentsBasedOnContext"
          />
        </footer>
      </div>
    </section>
  </div>
</template>
