<script setup>
import { computed, ref, watch, defineModel } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import addMonths from 'date-fns/addMonths';
import differenceInCalendarDays from 'date-fns/differenceInCalendarDays';
import endOfDay from 'date-fns/endOfDay';
import endOfMonth from 'date-fns/endOfMonth';
import startOfDay from 'date-fns/startOfDay';
import startOfMonth from 'date-fns/startOfMonth';
import subDays from 'date-fns/subDays';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const emit = defineEmits(['rangeTypeChange', 'monthOffsetChange']);

const fromModel = defineModel('from', { type: Date, default: null });
const toModel = defineModel('to', { type: Date, default: null });
const daysNumModel = defineModel('daysNum', { type: Number, default: null });

const { t } = useI18n();

const DATE_FILTER_TYPES = {
  DAY: 'day',
  MONTH: 'month',
};

const DATE_FILTER_ACTION = 'select_date_range';

const dayMenuItemConfigs = [
  {
    labelKey: 'LAST_7_DAYS',
    value: 'last_7_days',
    action: DATE_FILTER_ACTION,
    type: DATE_FILTER_TYPES.DAY,
    daysBefore: 6,
  },
  {
    labelKey: 'LAST_14_DAYS',
    value: 'last_14_days',
    action: DATE_FILTER_ACTION,
    type: DATE_FILTER_TYPES.DAY,
    daysBefore: 13,
  },
  {
    labelKey: 'LAST_30_DAYS',
    value: 'last_30_days',
    action: DATE_FILTER_ACTION,
    type: DATE_FILTER_TYPES.DAY,
    daysBefore: 29,
  },
];

const monthMenuItemConfigs = [
  {
    labelKey: 'THIS_MONTH',
    value: 'this_month',
    action: DATE_FILTER_ACTION,
    type: DATE_FILTER_TYPES.MONTH,
    monthOffset: 0,
  },
  {
    labelKey: 'LAST_MONTH',
    value: 'last_month',
    action: DATE_FILTER_ACTION,
    type: DATE_FILTER_TYPES.MONTH,
    monthOffset: -1,
  },
];

const menuItemConfigs = [...dayMenuItemConfigs, ...monthMenuItemConfigs];

const labelResolvers = {
  LAST_7_DAYS: () => t('REPORT.DATE_RANGE_OPTIONS.LAST_7_DAYS'),
  LAST_14_DAYS: () => t('REPORT.DATE_RANGE_OPTIONS.LAST_14_DAYS'),
  LAST_30_DAYS: () => t('REPORT.DATE_RANGE_OPTIONS.LAST_30_DAYS'),
  THIS_MONTH: () => t('REPORT.DATE_RANGE_OPTIONS.THIS_MONTH'),
  LAST_MONTH: () => t('REPORT.DATE_RANGE_OPTIONS.LAST_MONTH'),
};

const [showDropdown, toggleDropdown] = useToggle();
const selectedDateRangeValue = ref(menuItemConfigs[0]?.value || '');
const monthOffset = ref(
  menuItemConfigs.find(item => item.value === selectedDateRangeValue.value)
    ?.monthOffset || 0
);

const menuItems = computed(() =>
  menuItemConfigs.map(config => ({
    ...config,
    label: labelResolvers[config.labelKey]
      ? labelResolvers[config.labelKey]()
      : config.labelKey,
    isSelected: selectedDateRangeValue.value === config.value,
  }))
);

const menuSections = computed(() => {
  const dayItems = menuItems.value.filter(
    item => item.type === DATE_FILTER_TYPES.DAY
  );
  const monthItems = menuItems.value.filter(
    item => item.type === DATE_FILTER_TYPES.MONTH
  );

  return [{ items: dayItems }, { items: monthItems }].filter(
    section => section.items.length > 0
  );
});

const selectedConfig = computed(
  () =>
    menuItemConfigs.find(
      menuItem => menuItem.value === selectedDateRangeValue.value
    ) || menuItemConfigs[0]
);

const selectedLabel = computed(() => {
  const selectedItem = menuItems.value.find(
    item => item.value === selectedDateRangeValue.value
  );
  return selectedItem?.label || '';
});

const computeRange = config => {
  if (!config) {
    return null;
  }

  if (config.type === DATE_FILTER_TYPES.MONTH) {
    const now = new Date();
    const baseMonthStart = startOfMonth(addMonths(now, monthOffset.value));
    const from = startOfDay(baseMonthStart);
    const isCurrentMonth =
      config.value === 'this_month' && monthOffset.value === 0;
    const to = isCurrentMonth
      ? endOfDay(now)
      : endOfDay(endOfMonth(baseMonthStart));
    const daysBefore = differenceInCalendarDays(to, from);
    return { from, to, daysBefore };
  }

  const to = endOfDay(new Date());
  const from = startOfDay(subDays(to, Number(config.daysBefore)));
  return { from, to, daysBefore: Number(config.daysBefore) };
};

const applySelection = config => {
  if (!config) return;

  if (config.type === DATE_FILTER_TYPES.MONTH) {
    monthOffset.value = config.monthOffset || 0;
  } else {
    monthOffset.value = 0;
  }

  const range = computeRange(config);
  if (!range) return;

  const { from, to, daysBefore } = range;
  fromModel.value = from;
  toModel.value = to;
  daysNumModel.value = daysBefore;

  emit('rangeTypeChange', config.type);
  emit('monthOffsetChange', monthOffset.value);
};

const handleAction = ({ action, value }) => {
  toggleDropdown(false);
  if (action !== DATE_FILTER_ACTION) {
    return;
  }
  selectedDateRangeValue.value = value;
};

watch(
  () => selectedConfig.value,
  config => {
    applySelection(config);
  },
  { immediate: true }
);
</script>

<template>
  <div
    v-on-clickaway="() => toggleDropdown(false)"
    class="relative flex items-center group"
  >
    <Button
      sm
      slate
      faded
      :label="selectedLabel"
      class="rounded-md group-hover:bg-n-alpha-2"
      @click="toggleDropdown()"
    />
    <DropdownMenu
      v-if="showDropdown"
      :menu-items="menuItems"
      :menu-sections="menuSections"
      class="mt-1 ltr:right-0 rtl:left-0 xl:ltr:right-0 xl:rtl:left-0 top-full"
      @action="handleAction($event)"
    />
  </div>
</template>
