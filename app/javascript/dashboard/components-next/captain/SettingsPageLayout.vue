<script setup>
import { useRouter } from 'vue-router';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';

defineProps({
  isFetching: {
    type: Boolean,
    default: false,
  },
  isEmpty: {
    type: Boolean,
    default: false,
  },
  currentPage: {
    type: Number,
    default: 1,
  },
  totalCount: {
    type: Number,
    default: 100,
  },
  itemsPerPage: {
    type: Number,
    default: 25,
  },
  showPaginationFooter: {
    type: Boolean,
    default: false,
  },
  breadcrumbItems: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['update:currentPage']);

const router = useRouter();

const handlePageChange = event => {
  emit('update:currentPage', event);
};

const handleBreadcrumbClick = item => {
  router.push({
    name: item.routeName,
  });
};
</script>

<template>
  <section
    class="px-6 flex flex-col w-full h-screen overflow-y-auto bg-n-background"
  >
    <div class="max-w-[60rem] mx-auto flex flex-col w-full h-full mb-4">
      <header class="mb-7 sticky top-0 bg-n-background pt-4 z-20">
        <Breadcrumb :items="breadcrumbItems" @click="handleBreadcrumbClick" />
      </header>
      <main class="flex gap-16 w-full flex-1 pb-16">
        <section
          v-if="$slots.body || $slots.emptyState || isFetching"
          class="flex flex-col w-full"
        >
          <div
            v-if="isFetching"
            class="flex items-center justify-center py-10 text-n-slate-11"
          >
            <Spinner />
          </div>
          <div v-else-if="isEmpty">
            <slot name="emptyState" />
          </div>
          <slot v-else name="body" />
        </section>
        <section v-if="$slots.controls" class="flex w-full">
          <slot name="controls" />
        </section>
      </main>
      <footer v-if="showPaginationFooter" class="sticky bottom-0 z-10 pb-4">
        <PaginationFooter
          :current-page="currentPage"
          :total-items="totalCount"
          :items-per-page="itemsPerPage"
          @update:current-page="handlePageChange"
        />
      </footer>
    </div>
  </section>
</template>
