<script setup>
import { ref, computed, toRef } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';

const props = defineProps({
  activeSort: { type: String, default: 'created_at' },
  activeOrdering: { type: String, default: '-' },
});

const emit = defineEmits(['update:sort']);

const { t } = useI18n();

const isMenuOpen = ref(false);

const sortMenus = [
  { label: t('TASKS.HEADER.ACTIONS.SORT_BY.OPTIONS.TITLE'), value: 'title' },
  { label: t('TASKS.HEADER.ACTIONS.SORT_BY.OPTIONS.STATUS'), value: 'status' },
  {
    label: t('TASKS.HEADER.ACTIONS.SORT_BY.OPTIONS.CREATED_AT'),
    value: 'created_at',
  },
];

const orderingMenus = [
  { label: t('TASKS.HEADER.ACTIONS.ORDER.OPTIONS.ASCENDING'), value: '' },
  { label: t('TASKS.HEADER.ACTIONS.ORDER.OPTIONS.DESCENDING'), value: '-' },
];

const activeSort = toRef(props, 'activeSort');
const activeOrdering = toRef(props, 'activeOrdering');

const activeSortLabel = computed(() => {
  const selected = sortMenus.find(m => m.value === activeSort.value);
  return selected?.label || t('TASKS.HEADER.ACTIONS.SORT_BY.LABEL');
});

const activeOrderingLabel = computed(() => {
  const selected = orderingMenus.find(m => m.value === activeOrdering.value);
  return selected?.label || t('TASKS.HEADER.ACTIONS.ORDER.LABEL');
});

const handleSortChange = value => {
  emit('update:sort', { sort: value, order: props.activeOrdering });
};

const handleOrderChange = value => {
  emit('update:sort', { sort: props.activeSort, order: value });
};
</script>

<template>
  <div class="relative">
    <Button
      icon="i-lucide-arrow-down-up"
      color="slate"
      size="sm"
      variant="ghost"
      :class="isMenuOpen ? 'bg-n-alpha-2' : ''"
      @click="isMenuOpen = !isMenuOpen"
    />
    <div
      v-if="isMenuOpen"
      v-on-clickaway="() => (isMenuOpen = false)"
      class="absolute top-full mt-1 ltr:-right-32 rtl:-left-32 sm:ltr:right-0 sm:rtl:left-0 flex flex-col gap-4 bg-n-alpha-3 backdrop-blur-[100px] border border-n-weak w-72 rounded-xl p-4"
    >
      <div class="flex items-center justify-between gap-2">
        <span class="text-sm text-n-slate-12">
          {{ t('TASKS.HEADER.ACTIONS.SORT_BY.LABEL') }}
        </span>
        <SelectMenu
          :model-value="activeSort"
          :options="sortMenus"
          :label="activeSortLabel"
          @update:model-value="handleSortChange"
        />
      </div>
      <div class="flex items-center justify-between gap-2">
        <span class="text-sm text-n-slate-12">
          {{ t('TASKS.HEADER.ACTIONS.ORDER.LABEL') }}
        </span>
        <SelectMenu
          :model-value="activeOrdering"
          :options="orderingMenus"
          :label="activeOrderingLabel"
          @update:model-value="handleOrderChange"
        />
      </div>
    </div>
  </div>
</template>
