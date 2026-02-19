<script setup>
import { ref, reactive, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import {
  TIME_COLUMNS,
  TIME_PERIODS,
  TIME_FORMATS,
} from '../helpers/DatePickerHelper';

const props = defineProps({
  minTime: { type: Date, default: null },
});

const model = defineModel({
  type: Object,
  default: () => ({ hour: 9, minute: 0, second: 0 }),
});

const { t } = useI18n();

const { HOUR, HOUR_12, MINUTE, SECOND, PERIOD } = TIME_COLUMNS;
const { AM, PM } = TIME_PERIODS;
const { H24, H12 } = TIME_FORMATS;

const ITEM_HEIGHT = 40;
const CENTER_ROW = 2;
const VISIBLE_ROWS = 5;
const SNAP_DELAY = 120;
const SEPARATOR = ':';

const is24HourFormat = ref(false);
const selectedTime = reactive({
  hour: model.value.hour,
  minute: model.value.minute,
  second: model.value.second ?? 0,
});
const activeIndex = reactive({});
const dragOffset = reactive({});
const interactionMode = reactive({});
const touchStartY = {};
const snapTimers = {};
const columnRefs = reactive({});
const focusedColumn = ref(null);

const period = computed(() => (selectedTime.hour >= 12 ? PM : AM));
const showPeriod = computed(() => !is24HourFormat.value);

const minBound = computed(() => {
  if (!props.minTime) return null;
  const d = props.minTime;
  return { h: d.getHours(), m: d.getMinutes(), s: d.getSeconds() };
});

const toTimeNumber = (h, m, s) => h * 3600 + m * 60 + s;

const convertTo12Hour = hour => {
  if (hour === 0) return 12;
  return hour > 12 ? hour - 12 : hour;
};

const convertTo24Hour = (hour12, timePeriod) => {
  if (timePeriod === AM) return hour12 === 12 ? 0 : hour12;
  return hour12 === 12 ? 12 : hour12 + 12;
};

const isItemDisabled = (key, val) => {
  const mb = minBound.value;
  if (!mb) return false;
  const minVal = toTimeNumber(mb.h, mb.m, mb.s);
  const { hour, minute } = selectedTime;
  if (key === HOUR) return toTimeNumber(val, 0, 0) < toTimeNumber(mb.h, 0, 0);
  if (key === MINUTE) return toTimeNumber(hour, val, 0) < minVal;
  if (key === SECOND) return toTimeNumber(hour, minute, val) < minVal;
  return false;
};

const formatLabel = value => String(value).padStart(2, '0');

const buildItems = (count, key) =>
  Array.from({ length: count }, (_, i) => ({
    value: i,
    label: formatLabel(i),
    disabled: isItemDisabled(key, i),
  }));

const buildHour12Items = () =>
  Array.from({ length: 12 }, (_, i) => {
    const display = i === 0 ? 12 : i;
    return {
      value: display,
      label: formatLabel(display),
      disabled: isItemDisabled(HOUR, convertTo24Hour(display, period.value)),
    };
  });

const periodItems = computed(() => [
  { value: AM, label: AM, disabled: minBound.value?.h >= 12 },
  { value: PM, label: PM, disabled: false },
]);

const columns = computed(() => [
  {
    key: is24HourFormat.value ? HOUR : HOUR_12,
    label: t('DATE_PICKER.HOUR'),
    items: is24HourFormat.value ? buildItems(24, HOUR) : buildHour12Items(),
  },
  {
    key: MINUTE,
    label: t('DATE_PICKER.MINUTE'),
    items: buildItems(60, MINUTE),
  },
  {
    key: SECOND,
    label: t('DATE_PICKER.SECOND'),
    items: buildItems(60, SECOND),
  },
  { key: PERIOD, label: '', items: periodItems.value },
]);

const findColumn = key => columns.value.find(c => c.key === key);

const findNearestEnabled = (items, index) => {
  for (let d = 0; d < items.length; d += 1) {
    if (index + d < items.length && !items[index + d].disabled)
      return index + d;
    if (index - d >= 0 && !items[index - d].disabled) return index - d;
  }
  return index;
};

const getActiveIndex = key => {
  if (key === HOUR) return selectedTime.hour;
  if (key === HOUR_12) {
    const h = convertTo12Hour(selectedTime.hour);
    return h === 12 ? 0 : h;
  }
  if (key === PERIOD) return period.value === AM ? 0 : 1;
  return selectedTime[key];
};

const getColumnTranslateY = key => {
  const idx = -(activeIndex[key] ?? 0) * ITEM_HEIGHT;
  return CENTER_ROW * ITEM_HEIGHT + idx + (dragOffset[key] ?? 0);
};

const getMaxDragOffset = key => {
  const column = findColumn(key);
  if (!column) return { maxDown: 0, maxUp: 0 };
  const currentIdx = activeIndex[key] ?? 0;
  const firstEnabled = column.items.findIndex(i => !i.disabled);
  const lastEnabled = column.items.findLastIndex(i => !i.disabled);
  if (firstEnabled === -1) return { maxDown: 0, maxUp: 0 };
  return {
    maxDown: (currentIdx - firstEnabled) * ITEM_HEIGHT,
    maxUp: (lastEnabled - currentIdx) * ITEM_HEIGHT,
  };
};

const clampDragOffset = (key, rawOffset) => {
  const { maxDown, maxUp } = getMaxDragOffset(key);
  return Math.max(-maxUp, Math.min(maxDown, rawOffset));
};

let lastEmittedSignature = '';
const emitTimeValue = () => {
  const sig = `${selectedTime.hour}:${selectedTime.minute}:${selectedTime.second}`;
  if (sig === lastEmittedSignature) return;
  lastEmittedSignature = sig;
  model.value = { ...selectedTime };
};

const applySelection = (key, item) => {
  if (key === HOUR_12) {
    selectedTime.hour = convertTo24Hour(item.value, period.value);
  } else if (key === PERIOD) {
    selectedTime.hour = convertTo24Hour(
      convertTo12Hour(selectedTime.hour),
      item.value
    );
  } else {
    selectedTime[key] = item.value;
  }
  emitTimeValue();
};

const selectIndex = (key, targetIndex) => {
  const column = findColumn(key);
  if (!column) return;
  const clamped = Math.max(0, Math.min(targetIndex, column.items.length - 1));
  const resolved = column.items[clamped]?.disabled
    ? findNearestEnabled(column.items, clamped)
    : clamped;
  activeIndex[key] = resolved;
  const item = column.items[resolved];
  if (item) applySelection(key, item);
};

const selectByValue = (key, value) => {
  const column = findColumn(key);
  if (!column) return;
  const idx = column.items.findIndex(i => i.value === value && !i.disabled);
  if (idx !== -1) selectIndex(key, idx);
};

const snapToNearest = key => {
  const offset = dragOffset[key] ?? 0;
  const steps = Math.round(-offset / ITEM_HEIGHT);
  dragOffset[key] = 0;
  interactionMode[key] = null;
  if (steps !== 0) selectIndex(key, (activeIndex[key] ?? 0) + steps);
};

const isItemSelected = (key, val) => {
  if (key === HOUR_12) return convertTo12Hour(selectedTime.hour) === val;
  if (key === PERIOD) return period.value === val;
  return selectedTime[key] === val;
};

const isColumnHidden = key => key === PERIOD && !showPeriod.value;

const onWheelScroll = (key, event) => {
  event.preventDefault();
  interactionMode[key] = 'wheel';
  dragOffset[key] = clampDragOffset(key, (dragOffset[key] ?? 0) - event.deltaY);
  clearTimeout(snapTimers[key]);
  snapTimers[key] = setTimeout(() => snapToNearest(key), SNAP_DELAY);
};

const onTouchStart = (key, event) => {
  interactionMode[key] = 'touch';
  touchStartY[key] = event.touches[0].clientY;
  dragOffset[key] = 0;
};

const onTouchMove = (key, event) => {
  event.preventDefault();
  dragOffset[key] = clampDragOffset(
    key,
    event.touches[0].clientY - touchStartY[key]
  );
};

const onTouchEnd = key => snapToNearest(key);

const visibleColumnKeys = computed(() =>
  columns.value.filter(col => !isColumnHidden(col.key)).map(col => col.key)
);

const onKeyDown = (key, event) => {
  const { key: pressed, shiftKey } = event;
  if (pressed === 'ArrowUp' || pressed === 'ArrowDown') {
    event.preventDefault();
    selectIndex(
      key,
      (activeIndex[key] ?? 0) + (pressed === 'ArrowDown' ? 1 : -1)
    );
    return;
  }
  if (pressed === 'Tab') {
    const keys = visibleColumnKeys.value;
    const next = keys.indexOf(key) + (shiftKey ? -1 : 1);
    if (next >= 0 && next < keys.length) {
      event.preventDefault();
      columnRefs[keys[next]]?.focus();
    }
  }
};

const syncAllColumns = () => {
  columns.value.forEach(col => {
    activeIndex[col.key] = getActiveIndex(col.key);
  });
};

const formatTabs = [
  { label: t('DATE_PICKER.FORMAT_24H'), value: H24 },
  { label: t('DATE_PICKER.FORMAT_12H'), value: H12 },
];
const activeFormatTab = computed(() => (is24HourFormat.value ? 0 : 1));

const onFormatChange = tab => {
  is24HourFormat.value = tab.value === H24;
  syncAllColumns();
};

watch(model, v => {
  selectedTime.hour = v.hour;
  selectedTime.minute = v.minute;
  selectedTime.second = v.second ?? 0;
  syncAllColumns();
});

onMounted(syncAllColumns);
</script>

<template>
  <div class="relative flex flex-col items-center py-2 w-full">
    <div class="mb-4">
      <TabBar
        :tabs="formatTabs"
        :initial-active-tab="activeFormatTab"
        @tab-changed="onFormatChange"
      />
    </div>
    <div class="flex items-center z-[1] mb-1">
      <template v-for="(col, colIdx) in columns" :key="`label-${col.key}`">
        <span
          class="text-center text-xs font-medium text-n-slate-11 transition-all duration-300 ease-in-out overflow-hidden"
          :class="
            isColumnHidden(col.key) ? 'w-0 opacity-0' : 'w-14 opacity-100'
          "
        >
          {{ col.label }}
        </span>
        <span
          v-if="colIdx < columns.length - 1"
          class="text-lg font-520 text-transparent transition-all duration-300 ease-in-out overflow-hidden"
          :class="
            isColumnHidden(columns[colIdx + 1]?.key)
              ? 'w-0 opacity-0'
              : 'opacity-100'
          "
        >
          {{ SEPARATOR }}
        </span>
      </template>
    </div>
    <div class="relative w-full">
      <div
        class="absolute inset-x-6 h-10 rounded-2xl bg-n-solid-active outline outline-1 -outline-offset-1 outline-n-weak pointer-events-none shadow-inner"
        :style="{ top: `${CENTER_ROW * ITEM_HEIGHT}px` }"
      />
      <div class="flex items-center justify-center z-[1] relative">
        <template v-for="(col, colIdx) in columns" :key="col.key">
          <div
            :ref="
              el => {
                if (el) columnRefs[col.key] = el;
              }
            "
            :tabindex="isColumnHidden(col.key) ? -1 : 0"
            class="time-wheel relative overflow-hidden transition-all duration-300 ease-in-out outline-none"
            :class="
              isColumnHidden(col.key) ? 'w-0 opacity-0' : 'w-14 opacity-100'
            "
            :style="{ height: `${VISIBLE_ROWS * ITEM_HEIGHT}px` }"
            @wheel.prevent="onWheelScroll(col.key, $event)"
            @touchstart="onTouchStart(col.key, $event)"
            @touchmove.prevent="onTouchMove(col.key, $event)"
            @touchend="onTouchEnd(col.key)"
            @keydown="onKeyDown(col.key, $event)"
            @focus="focusedColumn = col.key"
            @blur="focusedColumn = null"
          >
            <div
              class="flex flex-col items-center"
              :class="{
                'transition-transform duration-200 ease-out':
                  !interactionMode[col.key],
                'transition-transform duration-100 ease-out':
                  interactionMode[col.key] === 'wheel',
              }"
              :style="{
                transform: `translateY(${getColumnTranslateY(col.key)}px)`,
              }"
            >
              <button
                v-for="item in col.items"
                :key="item.value"
                :disabled="item.disabled"
                tabindex="-1"
                class="flex items-center justify-center w-14 shrink-0 text-base font-semibold transition-colors outline-none"
                :style="{ height: `${ITEM_HEIGHT}px` }"
                :class="[
                  isItemSelected(col.key, item.value)
                    ? 'text-n-slate-12'
                    : 'text-n-slate-9',
                  item.disabled
                    ? 'opacity-20 cursor-not-allowed'
                    : 'cursor-pointer',
                  isItemSelected(col.key, item.value) &&
                  focusedColumn === col.key
                    ? 'outline outline-1 outline-n-brand -outline-offset-4 rounded-xl'
                    : '',
                ]"
                @click="selectByValue(col.key, item.value)"
              >
                {{ item.label }}
              </button>
            </div>
          </div>
          <span
            v-if="colIdx < columns.length - 1 && col.key !== SECOND"
            class="text-lg font-520 text-n-slate-11"
          >
            {{ SEPARATOR }}
          </span>
        </template>
      </div>
    </div>
  </div>
</template>

<style scoped>
.time-wheel {
  mask-image: linear-gradient(
    to bottom,
    transparent 0%,
    rgba(0, 0, 0, 0.3) 15%,
    rgba(0, 0, 0, 0.7) 30%,
    black 40%,
    black 60%,
    rgba(0, 0, 0, 0.7) 70%,
    rgba(0, 0, 0, 0.3) 85%,
    transparent 100%
  );
  -webkit-mask-image: linear-gradient(
    to bottom,
    transparent 0%,
    rgba(0, 0, 0, 0.3) 15%,
    rgba(0, 0, 0, 0.7) 30%,
    black 40%,
    black 60%,
    rgba(0, 0, 0, 0.7) 70%,
    rgba(0, 0, 0, 0.3) 85%,
    transparent 100%
  );
}
</style>
