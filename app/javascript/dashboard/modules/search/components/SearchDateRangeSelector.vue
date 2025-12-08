<script setup>
import { computed, ref, defineModel } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import {
  subDays,
  subMonths,
  subYears,
  startOfDay,
  endOfDay,
  format,
  getUnixTime,
  fromUnixTime,
} from 'date-fns';
import { DATE_RANGE_TYPES } from '../helpers/searchHelper';

import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const emit = defineEmits(['change']);
const modelValue = defineModel({
  type: Object,
  default: () => ({ type: null, from: null, to: null }),
});

const { t } = useI18n();
const [showDropdown, toggleDropdown] = useToggle();
const [showRangeTypeDropdown, toggleRangeTypeDropdown] = useToggle();

const customFrom = ref('');
const customTo = ref('');
const rangeType = ref(DATE_RANGE_TYPES.BETWEEN);

// Calculate min date (90 days ago) for date inputs
const minDate = computed(() => format(subDays(new Date(), 90), 'yyyy-MM-dd'));
const maxDate = computed(() => format(new Date(), 'yyyy-MM-dd'));

const DATE_FILTER_ACTIONS = {
  PRESET: 'preset',
  SELECT: 'select',
};

const PRESET_RANGES = computed(() => [
  {
    label: t('SEARCH.DATE_RANGE.LAST_7_DAYS'),
    value: DATE_RANGE_TYPES.LAST_7_DAYS,
    days: 7,
  },
  {
    label: t('SEARCH.DATE_RANGE.LAST_30_DAYS'),
    value: DATE_RANGE_TYPES.LAST_30_DAYS,
    days: 30,
  },
  {
    label: t('SEARCH.DATE_RANGE.LAST_90_DAYS'),
    value: DATE_RANGE_TYPES.LAST_90_DAYS,
    days: 90,
  },
]);

const RANGE_TYPES = computed(() => [
  {
    label: t('SEARCH.DATE_RANGE.BETWEEN'),
    value: DATE_RANGE_TYPES.BETWEEN,
    action: DATE_FILTER_ACTIONS.SELECT,

    isSelected: rangeType.value === DATE_RANGE_TYPES.BETWEEN,
  },
  {
    label: t('SEARCH.DATE_RANGE.BEFORE'),
    value: DATE_RANGE_TYPES.BEFORE,
    action: DATE_FILTER_ACTIONS.SELECT,

    isSelected: rangeType.value === DATE_RANGE_TYPES.BEFORE,
  },
  {
    label: t('SEARCH.DATE_RANGE.AFTER'),
    value: DATE_RANGE_TYPES.AFTER,
    action: DATE_FILTER_ACTIONS.SELECT,

    isSelected: rangeType.value === DATE_RANGE_TYPES.AFTER,
  },
]);

const computeDateRange = config => {
  const end = endOfDay(new Date());
  let start;

  if (config.days) {
    start = startOfDay(subDays(end, config.days));
  } else if (config.months) {
    start = startOfDay(subMonths(end, config.months));
  } else {
    start = startOfDay(subYears(end, config.years));
  }

  return { type: config.value, from: getUnixTime(start), to: getUnixTime(end) };
};

const selectedValue = computed(() => {
  const { from, to, type } = modelValue.value || {};
  if (!from && !to && !type) return '';
  return type || DATE_RANGE_TYPES.CUSTOM;
});

const menuItems = computed(() =>
  PRESET_RANGES.value.map(item => ({
    ...item,
    action: DATE_FILTER_ACTIONS.PRESET,
    isSelected: selectedValue.value === item.value,
  }))
);

const applySelection = ({ type, from, to }) => {
  const newValue = { type, from, to };
  modelValue.value = newValue;
  emit('change', newValue);
};

const clearFilter = () => {
  applySelection({ type: null, from: null, to: null });
  customFrom.value = '';
  customTo.value = '';
  toggleDropdown(false);
};

const handlePresetAction = item => {
  if (selectedValue.value === item.value) {
    clearFilter();
    return;
  }
  customFrom.value = '';
  customTo.value = '';
  applySelection(computeDateRange(item));
  toggleDropdown(false);
};

const applyCustomRange = () => {
  const customFromDate = customFrom.value
    ? startOfDay(new Date(customFrom.value))
    : null;
  const customToDate = customTo.value
    ? endOfDay(new Date(customTo.value))
    : null;

  let start = null;
  let end = null;

  if (
    rangeType.value === DATE_RANGE_TYPES.BETWEEN &&
    customFromDate &&
    customToDate
  ) {
    start = customFromDate;
    end = customToDate;
  } else if (rangeType.value === DATE_RANGE_TYPES.BEFORE && customToDate) {
    end = customToDate;
  } else if (rangeType.value === DATE_RANGE_TYPES.AFTER && customFromDate) {
    start = customFromDate;
  }

  if (start || end) {
    applySelection({
      type: rangeType.value,
      from: start ? getUnixTime(start) : null,
      to: end ? getUnixTime(end) : null,
    });
    toggleDropdown(false);
  }
};

const formatDate = timestamp => format(fromUnixTime(timestamp), 'MMM d, yyyy'); // (e.g., "Jan 15, 2024")

const selectedLabel = computed(() => {
  const prefix = t('SEARCH.DATE_RANGE.TIME_RANGE');
  if (!selectedValue.value) return prefix;

  // Check if it's a preset
  const preset = PRESET_RANGES.value.find(p => p.value === selectedValue.value);
  if (preset) return `${prefix}: ${preset.label}`;

  // Custom ranges
  const { from, to } = modelValue.value;
  if (from && to) return `${prefix}: ${formatDate(from)} - ${formatDate(to)}`;
  if (to)
    return `${prefix}: ${t('SEARCH.DATE_RANGE.BEFORE_DATE', { date: formatDate(to) })}`;
  if (from)
    return `${prefix}: ${t('SEARCH.DATE_RANGE.AFTER_DATE', { date: formatDate(from) })}`;

  return `${prefix}: ${t('SEARCH.DATE_RANGE.CUSTOM_RANGE')}`;
});

const selectedRangeTypeLabel = computed(
  () => RANGE_TYPES.value.find(type => type.value === rangeType.value)?.label
);

const handleRangeTypeAction = item => {
  customFrom.value = '';
  customTo.value = '';
  rangeType.value = item.value;
  toggleRangeTypeDropdown(false);
};

const CUSTOM_RANGE_TYPES = [
  DATE_RANGE_TYPES.BETWEEN,
  DATE_RANGE_TYPES.BEFORE,
  DATE_RANGE_TYPES.AFTER,
  DATE_RANGE_TYPES.CUSTOM,
];

const onToggleDropdown = () => {
  if (!showDropdown.value) {
    const { type, from, to } = modelValue.value || {};

    rangeType.value = CUSTOM_RANGE_TYPES.includes(type)
      ? type
      : DATE_RANGE_TYPES.BETWEEN;

    if (CUSTOM_RANGE_TYPES.includes(type)) {
      try {
        customFrom.value = from ? format(fromUnixTime(from), 'yyyy-MM-dd') : '';
        customTo.value = to ? format(fromUnixTime(to), 'yyyy-MM-dd') : '';
      } catch {
        customFrom.value = '';
        customTo.value = '';
      }
    } else {
      customFrom.value = '';
      customTo.value = '';
    }
  }
  toggleDropdown();
};
</script>

<template>
  <div
    v-on-click-outside="() => toggleDropdown(false)"
    class="relative flex items-center group"
  >
    <Button
      sm
      slate
      :label="selectedLabel"
      class="group-hover:bg-n-alpha-2"
      trailing-icon
      icon="i-lucide-chevron-down"
      @click="onToggleDropdown()"
    />
    <DropdownMenu
      v-if="showDropdown"
      :menu-items="menuItems"
      class="mt-1 ltr:left-0 rtl:right-0 top-full w-[20.5rem]"
      @action="handlePresetAction"
    >
      <template #footer>
        <div class="h-px bg-n-strong" />
        <div class="px-2 flex flex-col gap-1 items-start mb-2">
          <p class="text-sm font-medium text-n-slate-11 pt-2 pb-3 mb-0">
            {{ t('SEARCH.DATE_RANGE.CUSTOM_RANGE') }}
          </p>

          <div class="flex items-center flex-wrap gap-2">
            <span class="text-sm text-n-slate-12">
              {{ t('SEARCH.DATE_RANGE.CREATED') }}
            </span>
            <div
              v-on-click-outside="() => toggleRangeTypeDropdown(false)"
              class="relative"
            >
              <Button
                sm
                slate
                :label="selectedRangeTypeLabel"
                trailing-icon
                icon="i-lucide-chevron-down"
                @click="toggleRangeTypeDropdown()"
              />
              <DropdownMenu
                v-if="showRangeTypeDropdown"
                :menu-items="RANGE_TYPES"
                class="top-full mt-1 left-0 w-32"
                @action="handleRangeTypeAction"
              />
            </div>
            <input
              v-if="rangeType !== 'before'"
              v-model="customFrom"
              type="date"
              :min="minDate"
              :max="customTo || maxDate"
              class="!w-[7.75rem] !mb-0 !rounded-md !bg-transparent !outline-n-strong -outline-offset-1 !px-2 !py-1 !text-sm text-n-slate-12 !h-8"
            />
            <span
              v-if="rangeType === 'between'"
              class="text-sm text-n-slate-12"
            >
              {{ t('SEARCH.DATE_RANGE.AND') }}
            </span>
            <input
              v-if="rangeType !== 'after'"
              v-model="customTo"
              type="date"
              :min="customFrom || minDate"
              :max="maxDate"
              class="!w-[7.75rem] !mb-0 !rounded-md !bg-transparent !outline-n-strong -outline-offset-1 !px-2 !py-1 !text-sm text-n-slate-12 !h-8"
            />
          </div>
        </div>
        <div class="flex items-center gap-2 px-2 pb-2">
          <Button
            v-if="selectedValue"
            sm
            faded
            slate
            :label="t('SEARCH.DATE_RANGE.CLEAR_FILTER')"
            class="flex-1 justify-center"
            @click="clearFilter"
          />
          <Button
            sm
            solid
            color="blue"
            :label="t('SEARCH.DATE_RANGE.APPLY')"
            class="flex-1 justify-center"
            @click="applyCustomRange"
          />
        </div>
      </template>
    </DropdownMenu>
  </div>
</template>
