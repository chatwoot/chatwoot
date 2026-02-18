<script setup>
import { computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';

const props = defineProps({
  headerTitle: { type: String, default: '' },
  headerDescription: { type: String, default: '' },
  showPaginationFooter: { type: Boolean, default: true },
  currentPage: { type: Number, default: 1 },
  totalItems: { type: Number, default: 0 },
  itemsPerPage: { type: Number, default: 15 },
  isFetchingList: { type: Boolean, default: false },
});

const emit = defineEmits(['update:currentPage', 'create']);

const updateCurrentPage = page => {
  emit('update:currentPage', page);
};

const showPagination = computed(() => {
  return props.showPaginationFooter && props.totalItems > 0;
});
</script>

<template>
  <section
    class="flex w-full h-full gap-4 overflow-hidden justify-evenly bg-n-background"
  >
    <div class="flex flex-col w-full h-full transition-all duration-300">
      <!-- Header -->
      <header
        class="sticky top-0 z-10 flex flex-col bg-n-background border-b border-n-weak"
      >
        <div class="w-full mx-auto max-w-[90rem] px-4 py-4">
          <div class="flex items-start justify-between gap-4">
            <div class="flex-1">
              <h1 class="text-2xl font-semibold text-n-slate-12">
                {{ headerTitle }}
              </h1>
              <p
                v-if="headerDescription"
                class="mt-1 text-sm text-n-slate-11"
              >
                {{ headerDescription }}
              </p>
            </div>
            <div class="flex items-center gap-2">
              <slot name="header-actions" />
            </div>
          </div>
        </div>
      </header>

      <!-- Main content -->
      <main class="flex-1 overflow-y-auto">
        <div class="w-full mx-auto max-w-[90rem] px-4 py-4">
          <slot name="default" />
        </div>
      </main>

      <!-- Footer with pagination -->
      <footer v-if="showPagination" class="sticky bottom-0 z-0 px-4 pb-4">
        <PaginationFooter
          current-page-info="APPOINTMENTS.PAGINATION_FOOTER.SHOWING"
          :current-page="currentPage"
          :total-items="totalItems"
          :items-per-page="itemsPerPage"
          @update:current-page="updateCurrentPage"
        />
      </footer>
    </div>
  </section>
</template>
