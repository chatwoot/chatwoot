<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useNumberFormatter } from 'shared/composables/useNumberFormatter';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  currentPage: {
    type: Number,
    required: true,
  },
  totalItems: {
    type: Number,
    required: true,
  },
  itemsPerPage: {
    type: Number,
    default: 15,
  },
  currentPageInfo: {
    type: String,
    default: '',
  },
  showPageSizeSelector: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:currentPage', 'update:itemsPerPage']);

const PAGE_SIZE_OPTIONS = [15, 50, 100, 250, 500];

const { t } = useI18n();
const { formatCompactNumber, formatFullNumber } = useNumberFormatter();

const totalPages = computed(() =>
  Math.ceil(props.totalItems / props.itemsPerPage)
);
const startItem = computed(
  () => (props.currentPage - 1) * props.itemsPerPage + 1
);
const endItem = computed(() =>
  Math.min(startItem.value + props.itemsPerPage - 1, props.totalItems)
);
const isFirstPage = computed(() => props.currentPage === 1);
const isLastPage = computed(() => props.currentPage === totalPages.value);
const changePage = newPage => {
  if (newPage >= 1 && newPage <= totalPages.value) {
    emit('update:currentPage', newPage);
  }
};

const changePageSize = event => {
  const newSize = Number(event.target.value);
  if (PAGE_SIZE_OPTIONS.includes(newSize) && newSize !== props.itemsPerPage) {
    emit('update:itemsPerPage', newSize);
  }
};

const currentPageInformation = computed(() => {
  const translationKey = props.currentPageInfo || 'PAGINATION_FOOTER.SHOWING';
  return t(
    translationKey,
    {
      startItem: formatFullNumber(startItem.value),
      endItem: formatFullNumber(endItem.value),
      totalItems: formatCompactNumber(props.totalItems),
    },
    Number(props.totalItems)
  );
});

const pageInfo = computed(() => {
  return t(
    'PAGINATION_FOOTER.CURRENT_PAGE_INFO',
    {
      currentPage: '',
      totalPages: formatCompactNumber(totalPages.value),
    },
    Number(totalPages.value)
  );
});
</script>

<template>
  <div
    class="flex justify-between h-[3.375rem] w-full border-t border-n-weak mx-auto bg-n-surface-1 py-3 px-6 items-center before:absolute before:inset-x-0 before:-top-4 before:bg-gradient-to-t before:from-n-surface-1 before:from-0% before:to-transparent before:h-4 before:pointer-events-none"
  >
    <span class="min-w-0 text-body-main line-clamp-1 text-n-slate-11">
      {{ currentPageInformation }}
    </span>
    <div class="flex items-center gap-2">
      <template v-if="showPageSizeSelector">
        <div class="relative inline-flex items-center">
          <select
            :value="itemsPerPage"
            class="pl-3 pr-6 tabular-nums py-0.5 font-420 bg-n-input-background text-body-main text-n-slate-12 rounded-md border-0 appearance-none cursor-pointer focus:outline-none"
            @change="changePageSize"
          >
            <option v-for="size in PAGE_SIZE_OPTIONS" :key="size" :value="size">
              {{ size }}
            </option>
          </select>
          <span
            class="absolute right-2 top-1/2 -translate-y-1/2 pointer-events-none i-lucide-chevron-down size-3 text-n-slate-11"
          />
        </div>
        <span class="text-body-main text-n-slate-11">
          {{ t('PAGINATION_FOOTER.PAGE_SIZE_LABEL') }}
        </span>
        <div class="w-px h-4 bg-n-weak" />
      </template>
      <Button
        icon="i-lucide-chevrons-left"
        variant="ghost"
        size="sm"
        color="slate"
        class="!w-8 !h-6"
        :disabled="isFirstPage"
        @click="changePage(1)"
      />
      <Button
        icon="i-lucide-chevron-left"
        variant="ghost"
        color="slate"
        size="sm"
        class="!w-8 !h-6"
        :disabled="isFirstPage"
        @click="changePage(currentPage - 1)"
      />
      <div class="inline-flex items-center gap-2 text-sm">
        <span
          class="px-3 tabular-nums py-0.5 font-420 bg-n-input-background text-body-main text-n-slate-12 rounded-md"
        >
          {{ formatFullNumber(currentPage) }}
        </span>
        <span class="truncate text-body-main text-n-slate-11">
          {{ pageInfo }}
        </span>
      </div>
      <Button
        icon="i-lucide-chevron-right"
        variant="ghost"
        color="slate"
        size="sm"
        class="!w-8 !h-6"
        :disabled="isLastPage"
        @click="changePage(currentPage + 1)"
      />
      <Button
        icon="i-lucide-chevrons-right"
        variant="ghost"
        color="slate"
        size="sm"
        class="!w-8 !h-6"
        :disabled="isLastPage"
        @click="changePage(totalPages)"
      />
    </div>
  </div>
</template>
