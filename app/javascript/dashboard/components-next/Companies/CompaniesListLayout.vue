<script setup>
import CompanyHeader from './CompaniesHeader/CompanyHeader.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';

defineProps({
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, default: '' },
  currentPage: { type: Number, default: 1 },
  totalItems: { type: Number, default: 100 },
  activeSort: { type: String, default: 'name' },
  activeOrdering: { type: String, default: '' },
  showPaginationFooter: { type: Boolean, default: true },
});

const emit = defineEmits(['update:currentPage', 'update:sort', 'search']);

const updateCurrentPage = page => {
  emit('update:currentPage', page);
};
</script>

<template>
  <section
    class="flex w-full h-full gap-4 overflow-hidden justify-evenly bg-n-surface-1"
  >
    <div class="flex flex-col w-full h-full transition-all duration-300">
      <CompanyHeader
        :search-value="searchValue"
        :header-title="headerTitle"
        :active-sort="activeSort"
        :active-ordering="activeOrdering"
        @search="emit('search', $event)"
        @update:sort="emit('update:sort', $event)"
      />
      <main class="flex-1 px-6 overflow-y-auto">
        <div class="w-full mx-auto max-w-5xl py-4">
          <slot name="default" />
        </div>
      </main>
      <footer v-if="showPaginationFooter" class="sticky bottom-0 z-0">
        <PaginationFooter
          current-page-info="COMPANIES_LAYOUT.PAGINATION_FOOTER.SHOWING"
          :current-page="currentPage"
          :total-items="totalItems"
          :items-per-page="25"
          class="max-w-[67rem]"
          @update:current-page="updateCurrentPage"
        />
      </footer>
    </div>
  </section>
</template>
