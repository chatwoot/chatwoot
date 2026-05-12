<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  activeSourceFilter: { type: String, default: 'all' },
  activeStatusFilter: { type: String, default: null },
  activeSort: { type: String, default: 'recently_updated' },
  searchQuery: { type: String, default: '' },
});

const emit = defineEmits([
  'selectSource',
  'selectStatus',
  'selectSort',
  'search',
]);

const { t } = useI18n();

const openMenu = ref(null);

const MENU_CONFIG = [
  {
    key: 'source',
    activeKey: 'activeSourceFilter',
    dropdownClass: 'min-w-48',
    options: [
      { labelKey: 'SOURCE.ALL', value: 'all', icon: 'i-lucide-files' },
      { labelKey: 'SOURCE.WEB', value: 'web', icon: 'i-lucide-link' },
      { labelKey: 'SOURCE.PDF', value: 'pdf', icon: 'i-lucide-file-text' },
    ],
  },
  {
    key: 'status',
    activeKey: 'activeStatusFilter',
    dropdownClass: 'min-w-52',
    options: [
      { labelKey: 'STATUS.ANY', value: null, icon: 'i-lucide-circle-dashed' },
      {
        labelKey: 'STATUS.UPDATED',
        value: 'synced',
        icon: 'i-lucide-check-circle',
      },
      {
        labelKey: 'STATUS.NEEDS_UPDATE',
        value: 'stale',
        icon: 'i-lucide-clock',
      },
      {
        labelKey: 'STATUS.UPDATING',
        value: 'syncing',
        icon: 'i-lucide-refresh-cw',
      },
      {
        labelKey: 'STATUS.FAILED',
        value: 'failed',
        icon: 'i-lucide-circle-x',
      },
    ],
  },
  {
    key: 'sort',
    activeKey: 'activeSort',
    dropdownClass: 'min-w-56',
    options: [
      {
        labelKey: 'SORT.RECENTLY_UPDATED',
        value: 'recently_updated',
        icon: 'i-lucide-arrow-down-up',
      },
      {
        labelKey: 'SORT.RECENTLY_CREATED',
        value: 'recently_created',
        icon: 'i-lucide-clock',
      },
    ],
  },
];

const filterMenus = computed(() =>
  MENU_CONFIG.filter(
    menu => !(menu.key === 'status' && props.activeSourceFilter === 'pdf')
  ).map(menu => {
    const active = props[menu.activeKey];
    const items = menu.options.map(opt => ({
      label: t(`CAPTAIN.DOCUMENTS.FILTERS.${opt.labelKey}`),
      value: opt.value,
      icon: opt.icon,
      action: menu.key,
      isSelected: opt.value === active,
    }));
    return {
      ...menu,
      items,
      selected: items.find(item => item.isSelected) || items[0],
    };
  })
);

const closeMenu = () => {
  openMenu.value = null;
};

const toggleMenu = menu => {
  openMenu.value = openMenu.value === menu ? null : menu;
};

const handleMenuAction = ({ action, value }) => {
  closeMenu();
  if (action === 'source') emit('selectSource', value);
  else if (action === 'status') emit('selectStatus', value);
  else if (action === 'sort') emit('selectSort', value);
};
</script>

<template>
  <div
    v-on-clickaway="closeMenu"
    class="flex flex-col gap-3 w-full lg:flex-row lg:items-center lg:justify-between"
  >
    <div class="flex flex-wrap items-center gap-2">
      <div v-for="menu in filterMenus" :key="menu.key" class="relative">
        <Button
          :icon="menu.selected.icon"
          slate
          outline
          :class="{ 'bg-n-slate-9/10': openMenu === menu.key }"
          @click="toggleMenu(menu.key)"
        >
          <span class="min-w-0 truncate">{{ menu.selected.label }}</span>
          <Icon icon="i-lucide-chevron-down" class="shrink-0 size-4" />
        </Button>
        <DropdownMenu
          v-if="openMenu === menu.key"
          :menu-items="menu.items"
          :class="menu.dropdownClass"
          class="top-full mt-2 ltr:left-0 rtl:right-0"
          @action="handleMenuAction"
        />
      </div>
    </div>

    <Input
      :model-value="searchQuery"
      type="search"
      :placeholder="t('CAPTAIN.DOCUMENTS.FILTERS.SEARCH_PLACEHOLDER')"
      :custom-input-class="['ltr:!pl-9 rtl:!pr-9']"
      class="w-full lg:max-w-72"
      @input="emit('search', $event.target.value)"
    >
      <template #prefix>
        <Icon
          icon="i-lucide-search"
          class="absolute size-4 text-n-slate-11 top-1/2 -translate-y-1/2 ltr:left-3 rtl:right-3"
        />
      </template>
    </Input>
  </div>
</template>
