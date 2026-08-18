<script setup>
import { computed, ref } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import { TICKET_STATUS_CATEGORIES, TICKET_TYPES } from './constants';

const statusCategory = defineModel('statusCategory', {
  type: String,
  default: null,
});
const ticketType = defineModel('ticketType', { type: String, default: null });
const overdue = defineModel('overdue', { type: Boolean, default: false });

const { t } = useI18n();

const isTypeMenuOpen = ref(false);

const tabs = computed(() => [
  { label: t('TICKETS.FILTERS.ALL'), value: null },
  ...TICKET_STATUS_CATEGORIES.map(value => ({
    label: t(`TICKETS.STATUS_CATEGORY.${value.toUpperCase()}`),
    value,
  })),
]);

const activeTabIndex = computed(() =>
  Math.max(
    tabs.value.findIndex(tab => tab.value === statusCategory.value),
    0
  )
);

const typeItems = computed(() => [
  {
    label: t('TICKETS.FILTERS.ALL_TYPES'),
    value: null,
    action: 'type',
    isSelected: !ticketType.value,
  },
  ...TICKET_TYPES.map(value => ({
    label: t(`TICKETS.TYPE.${value.toUpperCase()}`),
    value,
    action: 'type',
    isSelected: ticketType.value === value,
  })),
]);

const typeLabel = computed(() =>
  ticketType.value
    ? t(`TICKETS.TYPE.${ticketType.value.toUpperCase()}`)
    : t('TICKETS.FILTERS.TYPE')
);

const onTabChanged = tab => {
  statusCategory.value = tab.value;
};

const onTypeSelected = ({ value }) => {
  isTypeMenuOpen.value = false;
  ticketType.value = value;
};
</script>

<template>
  <div class="flex flex-wrap items-center justify-between gap-3">
    <TabBar
      :tabs="tabs"
      :initial-active-tab="activeTabIndex"
      @tab-changed="onTabChanged"
    />
    <div class="flex items-center gap-3 shrink-0">
      <OnClickOutside
        class="relative"
        @trigger="isTypeMenuOpen = false"
      >
        <Button
          variant="outline"
          size="sm"
          icon="i-lucide-tag"
          class="!h-7 !px-2"
          :color="ticketType ? 'blue' : 'slate'"
          :class="ticketType ? '' : 'text-n-slate-11'"
          @click="isTypeMenuOpen = !isTypeMenuOpen"
        >
          {{ typeLabel }}
          <Icon icon="i-lucide-chevron-down" />
        </Button>
        <DropdownMenu
          v-if="isTypeMenuOpen"
          :menu-items="typeItems"
          class="mt-1 end-0 top-full w-44"
          @action="onTypeSelected"
        />
      </OnClickOutside>
      <div class="flex items-center gap-2 text-sm text-n-slate-11">
        <span>{{ t('TICKETS.FILTERS.OVERDUE') }}</span>
        <Switch v-model="overdue" />
      </div>
    </div>
  </div>
</template>
