<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import TaskSortMenu from './TaskSortMenu.vue';

const props = defineProps({
  headerTitle: { type: String, default: '' },
  searchValue: { type: String, default: '' },
  showPaginationFooter: { type: Boolean, default: true },
  currentPage: { type: Number, default: 1 },
  totalItems: { type: Number, default: 0 },
  itemsPerPage: { type: Number, default: 15 },
  activeSort: { type: String, default: 'created_at' },
  activeOrdering: { type: String, default: '-' },
  isFetchingList: { type: Boolean, default: false },
});

const emit = defineEmits(['update:currentPage', 'search', 'update:sort', 'create']);

const { t } = useI18n();

const showPagination = computed(
  () => props.showPaginationFooter && props.totalItems > 0
);
</script>

<template>
  <section
    class="flex w-full h-full gap-4 overflow-hidden justify-evenly bg-n-background"
  >
    <div class="flex flex-col w-full h-full transition-all duration-300">
      <!-- Header -->
      <header class="sticky top-0 z-10">
        <div
          class="flex items-start sm:items-center justify-between w-full py-6 px-6 gap-2 mx-auto max-w-[60rem]"
        >
          <span class="text-xl font-medium truncate text-n-slate-12">
            {{ headerTitle }}
          </span>
          <div
            class="flex items-center flex-col sm:flex-row flex-shrink-0 gap-4"
          >
            <div class="flex items-center gap-2 w-full">
              <Input
                :model-value="searchValue"
                type="search"
                :placeholder="t('TASKS.HEADER.SEARCH_PLACEHOLDER')"
                :custom-input-class="[
                  'h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8',
                ]"
                class="w-full"
                @input="emit('search', $event.target.value)"
              >
                <template #prefix>
                  <Icon
                    icon="i-lucide-search"
                    class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2 rtl:right-2"
                  />
                </template>
              </Input>
            </div>
            <div class="flex items-center flex-shrink-0 gap-4">
              <TaskSortMenu
                :active-sort="activeSort"
                :active-ordering="activeOrdering"
                @update:sort="emit('update:sort', $event)"
              />
              <div class="w-px h-4 bg-n-strong" />
              <Button size="sm" icon="i-lucide-plus" @click="emit('create')">
                {{ t('TASKS.HEADER.NEW_TASK') }}
              </Button>
            </div>
          </div>
        </div>
      </header>

      <!-- Main content -->
      <main class="flex-1 px-6 overflow-y-auto lg:px-0">
        <div class="w-full mx-auto max-w-[60rem] py-4">
          <slot name="default" />
        </div>
      </main>

      <!-- Pagination footer -->
      <footer v-if="showPagination" class="sticky bottom-0 z-0 px-4 pb-4">
        <PaginationFooter
          current-page-info="TASKS.PAGINATION_FOOTER.SHOWING"
          :current-page="currentPage"
          :total-items="totalItems"
          :items-per-page="itemsPerPage"
          @update:current-page="page => emit('update:currentPage', page)"
        />
      </footer>
    </div>
  </section>
</template>
