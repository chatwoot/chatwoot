<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';

import ContactListHeaderWrapper from 'dashboard/components-next/Contacts/ContactsHeader/ContactListHeaderWrapper.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';

defineProps({
  searchValue: {
    type: String,
    default: '',
  },
  headerTitle: {
    type: String,
    default: '',
  },
  showPaginationFooter: {
    type: Boolean,
    default: true,
  },
  currentPage: {
    type: Number,
    default: 1,
  },
  totalItems: {
    type: Number,
    default: 100,
  },
  itemsPerPage: {
    type: Number,
    default: 15,
  },
  activeSort: {
    type: String,
    default: '',
  },
  activeOrdering: {
    type: String,
    default: '',
  },
  activeSegment: {
    type: Object,
    default: null,
  },
  segmentsId: {
    type: [String, Number],
    default: 0,
  },
  hasAppliedFilters: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'update:currentPage',
  'update:sort',
  'search',
  'applyFilter',
  'clearFilters',
]);

const route = useRoute();

const isNotSegmentView = computed(() => {
  return route.name !== 'contacts_dashboard_segments_index';
});

const updateCurrentPage = page => {
  emit('update:currentPage', page);
};
</script>

<template>
  <section
    class="flex w-full h-full gap-4 overflow-hidden justify-evenly bg-n-background"
  >
    <div class="flex flex-col w-full h-full transition-all duration-300">
      <ContactListHeaderWrapper
        :show-search="isNotSegmentView"
        :search-value="searchValue"
        :active-sort="activeSort"
        :active-ordering="activeOrdering"
        :header-title="headerTitle"
        :active-segment="activeSegment"
        :segments-id="segmentsId"
        :has-applied-filters="hasAppliedFilters"
        @update:sort="emit('update:sort', $event)"
        @search="emit('search', $event)"
        @apply-filter="emit('applyFilter', $event)"
        @clear-filters="emit('clearFilters')"
      />
      <main class="flex-1 px-6 overflow-y-auto xl:px-px">
        <div class="w-full mx-auto max-w-[960px]">
          <slot name="default" />
        </div>
      </main>
      <footer
        v-if="showPaginationFooter"
        class="sticky bottom-0 z-10 px-4 pb-4"
      >
        <PaginationFooter
          current-page-info="CONTACTS_LAYOUT.PAGINATION_FOOTER.SHOWING"
          :current-page="currentPage"
          :total-items="totalItems"
          :items-per-page="itemsPerPage"
          @update:current-page="updateCurrentPage"
        />
      </footer>
    </div>
  </section>
</template>
