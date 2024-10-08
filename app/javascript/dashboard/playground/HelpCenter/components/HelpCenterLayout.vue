<script setup>
import PaginationFooter from 'dashboard/playground/components/PaginationFooter.vue';
import ButtonV4 from 'dashboard/playground/components/Button.vue';

defineProps({
  header: {
    type: String,
    default: 'Chatwoot Help Center',
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
    default: 10,
  },
  showPaginationFooter: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['update:currentPage']);

const updateCurrentPage = page => {
  emit('update:currentPage', page);
};
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <section
    class="flex flex-col w-full h-full overflow-hidden bg-white dark:bg-slate-900"
  >
    <header class="sticky top-0 z-10 h-20 p-4 bg-white dark:bg-slate-900">
      <div class="w-full max-w-[900px] flex items-center gap-2 mx-auto py-4">
        <span class="text-xl font-medium text-slate-900 dark:text-white">
          {{ header }}
        </span>
        <ButtonV4 icon="more-vertical" variant="ghost" size="sm" />
      </div>
    </header>
    <main class="flex-1 overflow-y-auto">
      <div class="w-full max-w-[900px] mx-auto py-4">
        <slot name="content" />
      </div>
    </main>
    <footer
      v-if="showPaginationFooter"
      class="sticky bottom-0 z-10 p-4 bg-white dark:bg-slate-900"
    >
      <PaginationFooter
        :current-page="currentPage"
        :total-items="totalItems"
        :items-per-page="itemsPerPage"
        @update:current-page="updateCurrentPage"
      />
    </footer>
  </section>
</template>
