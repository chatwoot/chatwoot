<script setup>
// import { computed } from 'vue';

import LibraryHeader from './LibraryHeader.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';

// const props = defineProps({
//   searchValue: { type: String, default: '' },
//   headerTitle: { type: String, default: '' },
//   showPaginationFooter: { type: Boolean, default: true },
//   currentPage: { type: Number, default: 1 },
//   totalItems: { type: Number, default: 0 },
//   itemsPerPage: { type: Number, default: 10 },
//   isLoading: { type: Boolean, default: false },
// });

const emit = defineEmits(['update:currentPage', 'search']);

const updateCurrentPage = page => {
  emit('update:currentPage', page);
};
</script>

<template>
  <section
    class="flex w-full h-full gap-4 overflow-hidden justify-evenly bg-n-background"
  >
    <div class="flex flex-col w-full h-full transition-all duration-300">
      <LibraryHeader
        :search-value="searchValue"
        :header-title="headerTitle"
        @search="emit('search', $event)"
      />

      <main class="flex-1 overflow-y-auto">
        <div class="w-full mx-auto max-w-[60rem]">
          <slot name="default" />
        </div>
      </main>

      <footer
        v-if="showPaginationFooter"
        class="sticky bottom-0 z-10 px-4 pb-4"
      >
        <PaginationFooter
          current-page-info="LIBRARY.PAGINATION_FOOTER.SHOWING"
          :current-page="currentPage"
          :total-items="totalItems"
          :items-per-page="itemsPerPage"
          @update:current-page="updateCurrentPage"
        />
      </footer>
    </div>
  </section>
</template>
