<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { FREQUENCY_OPTIONS } from 'dashboard/helper/recurrenceHelpers';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  modelValue: {
    type: Object,
    default: null,
  },
  scheduledDate: {
    type: Date,
    default: null,
  },
});

const emit = defineEmits(['update:modelValue', 'close']);

const { t } = useI18n();

const frequency = ref('weekly');
const interval = ref(1);
const weekDays = ref([]);
const monthlyType = ref('day_of_month');
const monthlyWeek = ref(1);
const monthlyWeekday = ref(0);
const endType = ref('never');
const endDate = ref('');
const endCount = ref(10);

const WEEKDAY_LABELS = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

const isWeekly = computed(() => frequency.value === 'weekly');
const isMonthly = computed(() => frequency.value === 'monthly');

const hasValidWeekDays = computed(
  () => !isWeekly.value || weekDays.value.length > 0
);

const hasValidEndDate = computed(
  () => endType.value !== 'on_date' || endDate.value
);

const hasValidEndCount = computed(
  () => endType.value !== 'after_count' || endCount.value >= 1
);

const hasValidInterval = computed(() => interval.value >= 1);

const isValid = computed(
  () =>
    hasValidInterval.value &&
    hasValidWeekDays.value &&
    hasValidEndDate.value &&
    hasValidEndCount.value
);

const toggleWeekDay = day => {
  const idx = weekDays.value.indexOf(day);
  if (idx === -1) {
    weekDays.value.push(day);
  } else if (weekDays.value.length > 1) {
    weekDays.value.splice(idx, 1);
  }
};

const resetToDefaults = () => {
  frequency.value = 'weekly';
  interval.value = 1;
  weekDays.value = props.scheduledDate ? [props.scheduledDate.getDay()] : [1];
  monthlyType.value = 'day_of_month';
  monthlyWeek.value = 1;
  monthlyWeekday.value = 0;
  endType.value = 'never';
  endDate.value = '';
  endCount.value = 10;
};

const initFromRule = rule => {
  if (!rule) {
    resetToDefaults();
    return;
  }
  frequency.value = rule.frequency || 'weekly';
  interval.value = rule.interval || 1;
  weekDays.value = rule.week_days ? [...rule.week_days] : [];
  monthlyType.value = rule.monthly_type || 'day_of_month';
  monthlyWeek.value = rule.monthly_week || 1;
  monthlyWeekday.value = rule.monthly_weekday || 0;
  endType.value = rule.end_type || 'never';
  endDate.value = rule.end_date || '';
  endCount.value = rule.end_count || 10;
};

const buildRule = () => {
  const rule = {
    frequency: frequency.value,
    interval: interval.value,
    end_type: endType.value,
  };

  if (isWeekly.value) {
    rule.week_days = [...weekDays.value].sort();
  }

  if (isMonthly.value) {
    rule.monthly_type = monthlyType.value;
    if (monthlyType.value === 'day_of_week') {
      rule.monthly_week = monthlyWeek.value;
      rule.monthly_weekday = monthlyWeekday.value;
    } else if (props.scheduledDate) {
      rule.month_day = props.scheduledDate.getDate();
    }
  }

  if (frequency.value === 'yearly' && props.scheduledDate) {
    rule.year_day = props.scheduledDate.getDate();
    rule.year_month = props.scheduledDate.getMonth() + 1;
  }

  if (endType.value === 'on_date') {
    rule.end_date = endDate.value;
  }

  if (endType.value === 'after_count') {
    rule.end_count = endCount.value;
  }

  return rule;
};

const onDone = () => {
  if (!isValid.value) return;
  emit('update:modelValue', buildRule());
  emit('close');
};

const onCancel = () => {
  emit('close');
};

watch(
  () => props.show,
  isVisible => {
    if (isVisible) {
      initFromRule(props.modelValue);
      if (!weekDays.value.length && props.scheduledDate) {
        weekDays.value = [props.scheduledDate.getDay()];
      }
    }
  }
);

watch(frequency, newFrequency => {
  if (newFrequency === 'weekly' && weekDays.value.length === 0) {
    weekDays.value = props.scheduledDate ? [props.scheduledDate.getDay()] : [1];
  }
});
</script>

<template>
  <woot-modal :show="show" size="small" @close="onCancel">
    <div class="flex w-full flex-col gap-5 px-6 py-6">
      <h3 class="text-lg font-semibold text-n-slate-12">
        {{ t('SCHEDULED_MESSAGES.RECURRENCE.CUSTOM_MODAL.TITLE') }}
      </h3>

      <!-- Frequency -->
      <div class="flex items-center gap-3">
        <span class="text-sm text-n-slate-12 whitespace-nowrap">
          {{ t('SCHEDULED_MESSAGES.RECURRENCE.CUSTOM_MODAL.REPEAT_EVERY') }}
        </span>
        <input
          v-model.number="interval"
          type="number"
          min="1"
          class="w-16 rounded-lg border border-n-weak px-2 py-1.5 text-sm text-n-slate-12"
        />
        <select
          v-model="frequency"
          class="rounded-lg border border-n-weak px-2 py-1.5 text-sm text-n-slate-12"
        >
          <option v-for="freq in FREQUENCY_OPTIONS" :key="freq" :value="freq">
            {{
              t(
                `SCHEDULED_MESSAGES.RECURRENCE.CUSTOM_MODAL.FREQ_${freq.toUpperCase()}`
              )
            }}
          </option>
        </select>
      </div>

      <!-- Week Days (weekly only) -->
      <div v-if="isWeekly" class="flex flex-col gap-2">
        <span class="text-sm text-n-slate-12">
          {{ t('SCHEDULED_MESSAGES.RECURRENCE.CUSTOM_MODAL.REPEAT_ON') }}
        </span>
        <div class="flex gap-1">
          <button
            v-for="(label, index) in WEEKDAY_LABELS"
            :key="index"
            class="flex h-8 w-8 items-center justify-center rounded-full text-xs font-medium transition-colors"
            :class="
              weekDays.includes(index)
                ? 'bg-n-blue-9 text-white'
                : 'bg-n-alpha-1 text-n-slate-11 hover:bg-n-alpha-2'
            "
            @click="toggleWeekDay(index)"
          >
            {{ t(`SCHEDULED_MESSAGES.RECURRENCE.WEEKDAYS_SHORT.${label}`) }}
          </button>
        </div>
      </div>

      <!-- Monthly Type (monthly only) -->
      <div v-if="isMonthly" class="flex flex-col gap-2">
        <label class="flex items-center gap-2 text-sm text-n-slate-12">
          <input
            v-model="monthlyType"
            type="radio"
            value="day_of_month"
            class="accent-n-blue-9"
          />
          {{ t('SCHEDULED_MESSAGES.RECURRENCE.CUSTOM_MODAL.MONTHLY_ON_DAY') }}
        </label>
        <label class="flex items-center gap-2 text-sm text-n-slate-12">
          <input
            v-model="monthlyType"
            type="radio"
            value="day_of_week"
            class="accent-n-blue-9"
          />
          {{
            t('SCHEDULED_MESSAGES.RECURRENCE.CUSTOM_MODAL.MONTHLY_ON_WEEKDAY')
          }}
        </label>
      </div>

      <!-- End Condition -->
      <div class="flex flex-col gap-2">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('SCHEDULED_MESSAGES.RECURRENCE.CUSTOM_MODAL.ENDS') }}
        </span>
        <label class="flex items-center gap-2 text-sm text-n-slate-12">
          <input
            v-model="endType"
            type="radio"
            value="never"
            class="accent-n-blue-9"
          />
          {{ t('SCHEDULED_MESSAGES.RECURRENCE.CUSTOM_MODAL.ENDS_NEVER') }}
        </label>
        <label class="flex items-center gap-2 text-sm text-n-slate-12">
          <input
            v-model="endType"
            type="radio"
            value="on_date"
            class="accent-n-blue-9"
          />
          {{ t('SCHEDULED_MESSAGES.RECURRENCE.CUSTOM_MODAL.ENDS_ON_DATE') }}
          <input
            v-if="endType === 'on_date'"
            v-model="endDate"
            type="date"
            class="ml-2 rounded-lg border border-n-weak px-2 py-1 text-sm"
          />
        </label>
        <label class="flex items-center gap-2 text-sm text-n-slate-12">
          <input
            v-model="endType"
            type="radio"
            value="after_count"
            class="accent-n-blue-9"
          />
          {{ t('SCHEDULED_MESSAGES.RECURRENCE.CUSTOM_MODAL.ENDS_AFTER') }}
          <input
            v-if="endType === 'after_count'"
            v-model.number="endCount"
            type="number"
            min="1"
            class="ml-2 w-16 rounded-lg border border-n-weak px-2 py-1 text-sm"
          />
          <span
            v-if="endType === 'after_count'"
            class="text-sm text-n-slate-11"
          >
            {{
              t('SCHEDULED_MESSAGES.RECURRENCE.CUSTOM_MODAL.ENDS_OCCURRENCES')
            }}
          </span>
        </label>
      </div>

      <!-- Actions -->
      <div class="flex items-center justify-end gap-3 pt-2">
        <NextButton
          ghost
          slate
          :label="t('SCHEDULED_MESSAGES.RECURRENCE.CUSTOM_MODAL.CANCEL')"
          @click="onCancel"
        />
        <NextButton
          solid
          blue
          :label="t('SCHEDULED_MESSAGES.RECURRENCE.CUSTOM_MODAL.DONE')"
          :disabled="!isValid"
          @click="onDone"
        />
      </div>
    </div>
  </woot-modal>
</template>
