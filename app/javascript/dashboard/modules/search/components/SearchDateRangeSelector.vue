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

const customFrom = ref('');
const customTo = ref('');
const rangeType = ref(DATE_RANGE_TYPES.BETWEEN);

// Calculate min date (90 days ago) for date inputs
const minDate = computed(() => format(subDays(new Date(), 90), 'yyyy-MM-dd'));
const maxDate = computed(() => format(new Date(), 'yyyy-MM-dd'));

// Check if both custom date inputs have values
const hasCustomDates = computed(() => customFrom.value && customTo.value);

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
    label: t('SEARCH.DATE_RANGE.LAST_60_DAYS'),
    value: DATE_RANGE_TYPES.LAST_60_DAYS,
    days: 60,
  },
  {
    label: t('SEARCH.DATE_RANGE.LAST_90_DAYS'),
    value: DATE_RANGE_TYPES.LAST_90_DAYS,
    days: 90,
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

  // Only BETWEEN mode - require both dates
  if (customFromDate && customToDate) {
    applySelection({
      type: DATE_RANGE_TYPES.BETWEEN,
      from: getUnixTime(customFromDate),
      to: getUnixTime(customToDate),
    });
    toggleDropdown(false);
  }
};

const clearCustomRange = () => {
  customFrom.value = '';
  customTo.value = '';
};

const formatDate = timestamp => format(fromUnixTime(timestamp), 'MMM d, yyyy'); // (e.g., "Jan 15, 2024")

const selectedLabel = computed(() => {
  const prefix = t('SEARCH.DATE_RANGE.TIME_RANGE');
  if (!selectedValue.value) return prefix;

  // Check if it's a preset
  const preset = PRESET_RANGES.value.find(p => p.value === selectedValue.value);
  if (preset) return `${prefix}: ${preset.label}`;

  // Custom range - only BETWEEN mode with both dates
  const { from, to } = modelValue.value;
  if (from && to) return `${prefix}: ${formatDate(from)} - ${formatDate(to)}`;

  return `${prefix}: ${t('SEARCH.DATE_RANGE.CUSTOM_RANGE')}`;
});

const CUSTOM_RANGE_TYPES = [DATE_RANGE_TYPES.BETWEEN, DATE_RANGE_TYPES.CUSTOM];

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
    class="relative flex items-center group min-w-0 max-w-full"
  >
    <Button
      sm
      slate
      :variant="showDropdown ? 'faded' : 'solid'"
      :label="selectedLabel"
      class="group-hover:bg-n-alpha-2 max-w-full"
      trailing-icon
      icon="i-lucide-chevron-down"
      @click="onToggleDropdown()"
    />
    <DropdownMenu
      v-if="showDropdown"
      :menu-items="menuItems"
      class="mt-1 ltr:left-0 rtl:right-0 top-full w-64"
      @action="handlePresetAction"
    >
      <template #footer>
        <div class="h-px bg-n-strong" />
        <div class="flex flex-col gap-2">
          <div class="flex items-center justify-between gap-2 px-1 h-9">
            <span class="text-sm text-n-slate-11">
              {{ t('SEARCH.DATE_RANGE.CUSTOM_RANGE') }}
            </span>
            <span class="text-sm text-n-slate-12">
              {{ t('SEARCH.DATE_RANGE.CREATED_BETWEEN') }}
            </span>
          </div>

          <input
            v-model="customFrom"
            type="date"
            :min="minDate"
            :max="customTo || maxDate"
            class="!w-full !mb-0 !rounded-lg !bg-n-alpha-black2 !outline-n-strong -outline-offset-1 !px-3 !py-2 !text-sm text-n-slate-12 !h-8"
          />

          <div class="flex items-center gap-3 h-5 px-1">
            <div class="flex-1 h-px bg-n-weak" />
            <span class="text-sm text-n-slate-11">
              {{ t('SEARCH.DATE_RANGE.AND') }}
            </span>
            <div class="flex-1 h-px bg-n-weak" />
          </div>

          <input
            v-model="customTo"
            type="date"
            :min="customFrom || minDate"
            :max="maxDate"
            class="!w-full !mb-0 !rounded-lg !bg-n-alpha-black2 !outline-n-strong -outline-offset-1 !px-3 !py-2 !text-sm text-n-slate-12 !h-8"
          />

          <div class="flex items-center gap-2 mt-2">
            <Button
              sm
              slate
              faded
              :label="t('SEARCH.DATE_RANGE.CLEAR_FILTER')"
              :disabled="!hasCustomDates"
              class="flex-1 justify-center"
              @click="clearCustomRange"
            />
            <Button
              sm
              solid
              color="blue"
              :label="t('SEARCH.DATE_RANGE.APPLY')"
              :disabled="!hasCustomDates"
              class="flex-1 justify-center"
              @click="applyCustomRange"
            />
          </div>
        </div>
      </template>
    </DropdownMenu>
  </div>
</template>
