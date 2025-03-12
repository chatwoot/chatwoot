<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';

defineProps({
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
  headerTitle: {
    type: String,
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },
  showPaginationFooter: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['click', 'close', 'update:currentPage']);

const handleButtonClick = () => {
  emit('click');
};

const handlePageChange = event => {
  emit('update:currentPage', event);
};
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-n-background">
    <header class="sticky top-0 z-10 px-6 xl:px-0">
      <div class="w-full max-w-[960px] mx-auto">
        <div
          class="flex items-start lg:items-center justify-between w-full py-6 lg:py-0 lg:h-20 gap-4 lg:gap-2 flex-col lg:flex-row"
        >
          <span class="text-xl font-medium text-n-slate-12">
            {{ headerTitle }}
            <slot name="headerTitle" />
          </span>
          <div
            v-on-clickaway="() => emit('close')"
            class="relative group/campaign-button"
          >
            <Button
              :label="buttonLabel"
              icon="i-lucide-plus"
              size="sm"
              class="group-hover/campaign-button:brightness-110"
              @click="handleButtonClick"
            />
            <slot name="action" />
          </div>
        </div>
      </div>
    </header>
    <main class="flex-1 px-6 overflow-y-auto xl:px-0">
      <div class="w-full max-w-[960px] mx-auto py-4">
        <slot name="default" />
      </div>
    </main>
    <footer v-if="showPaginationFooter" class="sticky bottom-0 z-10 px-4 pb-4">
      <PaginationFooter
        :current-page="currentPage"
        :total-items="totalCount"
        :items-per-page="itemsPerPage"
        @update:current-page="handlePageChange"
      />
    </footer>
  </section>
</template>
