<script setup>
import { computed } from 'vue';
import { dateRanges } from '../helpers/DatePickerHelper';
import { format, isSameYear, isValid } from 'date-fns';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  selectedStartDate: Date,
  selectedEndDate: Date,
  selectedRange: {
    type: String,
    default: '',
  },
  showMonthNavigation: {
    type: Boolean,
    default: false,
  },
  canNavigateNext: {
    type: Boolean,
    default: false,
  },
  navigationLabel: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(['open', 'navigateMonth']);

const formatDateRange = computed(() => {
  const startDate = props.selectedStartDate;
  const endDate = props.selectedEndDate;

  if (!isValid(startDate) || !isValid(endDate)) {
    return 'Select a date range';
  }

  const crossesYears = !isSameYear(startDate, endDate);

  // Always show years when crossing year boundaries
  if (crossesYears) {
    return `${format(startDate, 'MMM d, yyyy')} - ${format(endDate, 'MMM d, yyyy')}`;
  }

  // For same year, always show the year for clarity
  return `${format(startDate, 'MMM d')} - ${format(endDate, 'MMM d, yyyy')}`;
});

const activeDateRange = computed(
  () => dateRanges.find(range => range.value === props.selectedRange).label
);

const openDatePicker = () => {
  emit('open');
};
</script>

<template>
  <div class="inline-flex items-center gap-1">
    <button
      class="inline-flex relative items-center rounded-lg gap-2 py-1.5 px-3 h-8 bg-n-alpha-2 hover:bg-n-alpha-1 active:bg-n-alpha-1 flex-shrink-0"
      @click="openDatePicker"
    >
      <Icon
        icon="i-lucide-calendar-range"
        class="text-n-slate-11 size-3.5 flex-shrink-0"
      />
      <span class="text-sm font-medium text-n-slate-12 truncate">
        {{ navigationLabel || $t(activeDateRange) }}
      </span>
      <span class="text-sm font-medium text-n-slate-11 truncate">
        {{ formatDateRange }}
      </span>
      <Icon
        icon="i-lucide-chevron-down"
        class="text-n-slate-12 size-4 flex-shrink-0"
      />
    </button>
    <NextButton
      v-if="showMonthNavigation"
      v-tooltip.top="$t('DATE_PICKER.PREVIOUS_PERIOD')"
      slate
      faded
      sm
      icon="i-lucide-chevron-left"
      class="rtl:rotate-180"
      @click="emit('navigateMonth', 'prev')"
    />
    <NextButton
      v-if="showMonthNavigation"
      v-tooltip.top="$t('DATE_PICKER.NEXT_PERIOD')"
      slate
      faded
      sm
      icon="i-lucide-chevron-right"
      class="rtl:rotate-180"
      :disabled="!canNavigateNext"
      @click="emit('navigateMonth', 'next')"
    />
  </div>
</template>
