<script setup>
import { computed, nextTick, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { differenceInCalendarDays, parseISO } from 'date-fns';
import { formatInTimeZone } from 'date-fns-tz';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';
import {
  CUSTOM_RANGE,
  INTERVALS,
  MAX_RANGE_DAYS,
  MIN_RANGE_DAYS,
  shiftDate,
} from './monitorFilters';

const props = defineProps({
  timezone: { type: String, required: true },
  pausedAt: { type: Number, default: null },
  isLoading: { type: Boolean, default: false },
});
const filters = defineModel({ type: Object, required: true });

const { t } = useI18n();
const popover = ref(null);
const trigger = ref(null);
const form = ref(null);
const rangeSelect = ref(null);
const draft = ref({});
const error = ref('');
const now = ref(Date.now());

const lastDate = computed(() =>
  formatInTimeZone(
    props.pausedAt ? props.pausedAt * 1000 : now.value,
    props.timezone,
    'yyyy-MM-dd'
  )
);
const earliest = (...dates) => dates.filter(Boolean).sort()[0];
const rangeLabel = days =>
  t(props.pausedAt ? 'MONITORS.LAST_DAYS_BEFORE_PAUSE' : 'MONITORS.LAST_DAYS', {
    count: days,
  });

const resetDraft = () => {
  draft.value = {
    from: shiftDate(lastDate.value, 1 - MIN_RANGE_DAYS),
    to: lastDate.value,
    ...filters.value,
  };
};
watch(filters, resetDraft);

const onShow = async () => {
  now.value = Date.now();
  if (!draft.value.range) resetDraft();
  await nextTick();
  rangeSelect.value?.focus();
};

const onHide = () => {
  if (form.value?.contains(document.activeElement)) trigger.value?.$el.focus();
};

const apply = () => {
  now.value = Date.now();
  error.value = '';
  const { range, from, to, interval } = draft.value;
  if (range === CUSTOM_RANGE) {
    const days = differenceInCalendarDays(parseISO(to), parseISO(from)) + 1;
    if (Number.isNaN(days) || days < MIN_RANGE_DAYS || days > MAX_RANGE_DAYS) {
      error.value = t('MONITORS.CUSTOM_RANGE_HELP', {
        min: MIN_RANGE_DAYS,
        max: MAX_RANGE_DAYS,
      });
      return;
    }
    if (to > lastDate.value) {
      error.value = t('MONITORS.CUSTOM_RANGE_BOUNDARY_ERROR', {
        date: lastDate.value,
      });
      return;
    }
  }
  filters.value = { range, from, to, interval };
  popover.value.hide();
};
</script>

<template>
  <Popover ref="popover" @show="onShow" @hide="onHide">
    <template #default="{ isOpen }">
      <Button
        ref="trigger"
        v-tooltip.bottom="t('MONITORS.FILTERS')"
        slate
        ghost
        size="sm"
        icon="i-lucide-list-filter"
        class="shrink-0"
        :aria-label="t('MONITORS.FILTERS')"
        :aria-expanded="isOpen"
        aria-haspopup="dialog"
        aria-controls="monitor-chart-filters"
      />
    </template>
    <template #content>
      <form
        id="monitor-chart-filters"
        ref="form"
        role="dialog"
        :aria-label="t('MONITORS.FILTERS')"
        class="flex w-full flex-col gap-4 p-4 md:w-72"
        @submit.prevent="apply"
      >
        <p class="m-0 text-sm font-medium text-n-slate-12">
          {{ t('MONITORS.FILTERS') }}
        </p>
        <label class="flex flex-col gap-2 text-sm text-n-slate-12">
          {{ t('MONITORS.DATE_RANGE') }}
          <select
            ref="rangeSelect"
            v-model="draft.range"
            class="m-0 w-full rounded-lg border border-n-weak bg-n-solid-1 text-sm text-n-slate-12"
          >
            <option
              v-for="days in [MIN_RANGE_DAYS, MAX_RANGE_DAYS]"
              :key="days"
              :value="days"
            >
              {{ rangeLabel(days) }}
            </option>
            <option :value="CUSTOM_RANGE">
              {{ t('MONITORS.CUSTOM_RANGE') }}
            </option>
          </select>
        </label>
        <template v-if="draft.range === CUSTOM_RANGE">
          <Input
            v-model="draft.from"
            type="date"
            :label="t('MONITORS.FROM')"
            :min="shiftDate(draft.to, 1 - MAX_RANGE_DAYS)"
            :max="shiftDate(earliest(draft.to, lastDate), 1 - MIN_RANGE_DAYS)"
          />
          <Input
            v-model="draft.to"
            type="date"
            :label="t('MONITORS.TO')"
            :min="shiftDate(draft.from, MIN_RANGE_DAYS - 1)"
            :max="earliest(shiftDate(draft.from, MAX_RANGE_DAYS - 1), lastDate)"
          />
          <p v-if="!error" class="m-0 text-xs text-n-slate-11">
            {{
              t('MONITORS.CUSTOM_RANGE_HELP', {
                min: MIN_RANGE_DAYS,
                max: MAX_RANGE_DAYS,
              })
            }}
          </p>
        </template>
        <label class="flex flex-col gap-2 text-sm text-n-slate-12">
          {{ t('MONITORS.INTERVAL') }}
          <select
            v-model="draft.interval"
            class="m-0 w-full rounded-lg border border-n-weak bg-n-solid-1 text-sm text-n-slate-12"
          >
            <option v-for="value in INTERVALS" :key="value" :value="value">
              {{ t(`MONITORS.INTERVALS.${value.toUpperCase()}`) }}
            </option>
          </select>
        </label>
        <p v-if="error" role="alert" class="m-0 text-xs text-n-ruby-11">
          {{ error }}
        </p>
        <Button
          type="submit"
          size="sm"
          :label="t('MONITORS.APPLY')"
          :is-loading="isLoading"
        />
      </form>
    </template>
  </Popover>
</template>
