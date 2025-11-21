<script setup>
import PaymentLinksHeaderWrapper from 'dashboard/components-next/PaymentLinks/PaymentLinksHeader/PaymentLinksHeaderWrapper.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';

defineProps({
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, default: '' },
  showPaginationFooter: { type: Boolean, default: true },
  currentPage: { type: Number, default: 1 },
  totalItems: { type: Number, default: 100 },
  itemsPerPage: { type: Number, default: 15 },
  activeSort: { type: String, default: '' },
  activeOrdering: { type: String, default: '' },
  hasAppliedFilters: { type: Boolean, default: false },
});

const emit = defineEmits([
  'update:currentPage',
  'update:sort',
  'search',
  'applyFilter',
  'clearFilters',
]);

const updateCurrentPage = page => {
  emit('update:currentPage', page);
};
</script>

<template>
  <section
    class="flex w-full h-full gap-4 overflow-hidden justify-evenly bg-n-background"
  >
    <div class="flex flex-col w-full h-full transition-all duration-300">
      <PaymentLinksHeaderWrapper
        :search-value="searchValue"
        :active-sort="activeSort"
        :active-ordering="activeOrdering"
        :header-title="headerTitle"
        :has-applied-filters="hasAppliedFilters"
        @update:sort="emit('update:sort', $event)"
        @search="emit('search', $event)"
        @apply-filter="emit('applyFilter', $event)"
        @clear-filters="emit('clearFilters')"
      />
      <main class="flex-1 overflow-y-auto">
        <div class="w-full mx-auto max-w-[60rem]">
          <slot name="default" />
        </div>
      </main>
      <footer v-if="showPaginationFooter" class="sticky bottom-0 z-0 px-4 pb-4">
        <PaginationFooter
          current-page-info="PAYMENT_LINKS_LAYOUT.PAGINATION_FOOTER.SHOWING"
          :current-page="currentPage"
          :total-items="totalItems"
          :items-per-page="itemsPerPage"
          @update:current-page="updateCurrentPage"
        />
      </footer>
    </div>
  </section>
</template>
