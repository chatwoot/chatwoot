<script setup>
import { ref, computed, toRef } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';

const props = defineProps({
  activeSort: {
    type: String,
    default: 'name',
  },
  activeOrdering: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:sort']);

const { t } = useI18n();

const isMenuOpen = ref(false);

const sortMenus = [
  {
    label: t('COMPANIES.SORT_BY.OPTIONS.NAME'),
    value: 'name',
  },
  {
    label: t('COMPANIES.SORT_BY.OPTIONS.DOMAIN'),
    value: 'domain',
  },
  {
    label: t('COMPANIES.SORT_BY.OPTIONS.CREATED_AT'),
    value: 'created_at',
  },
  {
    label: t('COMPANIES.SORT_BY.OPTIONS.CONTACTS_COUNT'),
    value: 'contacts_count',
  },
];

const orderingMenus = [
  {
    label: t('COMPANIES.ORDER.OPTIONS.ASCENDING'),
    value: '',
  },
  {
    label: t('COMPANIES.ORDER.OPTIONS.DESCENDING'),
    value: '-',
  },
];

// Converted the props to refs for better reactivity
const activeSort = toRef(props, 'activeSort');

const activeOrdering = toRef(props, 'activeOrdering');

const activeSortLabel = computed(() => {
  const selectedMenu = sortMenus.find(menu => menu.value === activeSort.value);
  return selectedMenu?.label || t('COMPANIES.SORT_BY.LABEL');
});

const activeOrderingLabel = computed(() => {
  const selectedMenu = orderingMenus.find(
    menu => menu.value === activeOrdering.value
  );
  return selectedMenu?.label || t('COMPANIES.ORDER.LABEL');
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
          {{ t('COMPANIES.SORT_BY.LABEL') }}
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
          {{ t('COMPANIES.ORDER.LABEL') }}
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
