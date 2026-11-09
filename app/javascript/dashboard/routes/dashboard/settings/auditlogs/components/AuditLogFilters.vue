<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { startOfDay, endOfDay } from 'date-fns';
import { vOnClickOutside } from '@vueuse/components';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import WootDatePicker from 'dashboard/components/ui/DatePicker/DatePicker.vue';
import { DATE_RANGE_TYPES } from 'dashboard/components/ui/DatePicker/helpers/DatePickerHelper';
import { EVENT_TYPE_GROUPS } from 'dashboard/helper/auditlogHelper';

const props = defineProps({
  type: {
    type: String,
    default: '',
  },
  range: {
    type: String,
    default: '',
  },
  since: {
    type: Number,
    default: null,
  },
  until: {
    type: Number,
    default: null,
  },
  sort: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update']);

const { t } = useI18n();

const toUnixTime = date => Math.floor(date.getTime() / 1000);
const toDate = seconds => new Date(seconds * 1000);
const isKnownRange = value => Object.values(DATE_RANGE_TYPES).includes(value);

const openFilterMenu = ref(null);
const showPicker = ref(false);

const pickerKey = ref(0);
const pickerDateRange = ref([]);
const pickerRangeType = ref(DATE_RANGE_TYPES.LAST_7_DAYS);

const hasDateFilter = computed(() => Boolean(props.since && props.until));
const isPickerVisible = computed(() => hasDateFilter.value || showPicker.value);

watch(
  () => [props.range, props.since, props.until],
  ([range, since, until]) => {
    if (!hasDateFilter.value) {
      showPicker.value = false;
      return;
    }
    pickerRangeType.value = isKnownRange(range)
      ? range
      : DATE_RANGE_TYPES.CUSTOM_RANGE;
    pickerDateRange.value = [toDate(since), toDate(until)];
  },
  { immediate: true }
);

const selectedEventType = computed(() =>
  EVENT_TYPE_GROUPS.flatMap(group => group.types).find(
    ({ value }) => value === props.type
  )
);

const eventTypeSections = computed(() => [
  {
    items: [
      {
        label: t('AUDIT_LOGS.FILTERS.ALL_EVENTS'),
        action: 'type',
        isSelected: !selectedEventType.value,
      },
    ],
  },
  ...EVENT_TYPE_GROUPS.map(group => ({
    title: t(`AUDIT_LOGS.FILTERS.EVENT_TYPE_GROUPS.${group.key}`),
    items: group.types.map(({ value, key }) => ({
      label: t(`AUDIT_LOGS.FILTERS.EVENT_TYPES.${key}`),
      value,
      action: 'type',
      isSelected: props.type === value,
    })),
  })),
]);

const sortSections = computed(() => [
  {
    items: [
      {
        label: t('AUDIT_LOGS.FILTERS.SORT.NEWEST'),
        action: 'sort',
        isSelected: props.sort !== 'asc',
      },
      {
        label: t('AUDIT_LOGS.FILTERS.SORT.OLDEST'),
        value: 'asc',
        action: 'sort',
        isSelected: props.sort === 'asc',
      },
    ],
  },
]);

const filterMenus = computed(() =>
  [
    {
      key: 'type',
      icon: 'i-lucide-list-filter',
      sections: eventTypeSections.value,
    },
    {
      key: 'sort',
      icon: 'i-lucide-arrow-down-up',
      sections: sortSections.value,
    },
  ].map(menu => ({
    ...menu,
    label: menu.sections
      .flatMap(section => section.items)
      .find(item => item.isSelected).label,
  }))
);

const resetPicker = () => {
  if (hasDateFilter.value) pickerKey.value += 1;
  else showPicker.value = false;
};

const closeMenus = () => {
  openFilterMenu.value = null;
};

const closeFilterMenu = () => {
  closeMenus();
  resetPicker();
};

const openDatePicker = () => {
  closeMenus();
  showPicker.value = true;
};

const toggleFilterMenu = key => {
  resetPicker();
  openFilterMenu.value = openFilterMenu.value === key ? null : key;
};

const applyDateRange = ([start, end, range]) => {
  emit('update', {
    range,
    since: toUnixTime(startOfDay(start)),
    until: toUnixTime(endOfDay(end)),
  });
};

const handleFilterAction = ({ action, value }) => {
  closeFilterMenu();
  emit('update', { [action]: value });
};
</script>

<template>
  <div
    v-on-click-outside="closeFilterMenu"
    class="flex flex-wrap sm:flex-nowrap items-center gap-2 sm:shrink-0"
  >
    <WootDatePicker
      v-if="isPickerVisible"
      :key="pickerKey"
      v-model:date-range="pickerDateRange"
      v-model:range-type="pickerRangeType"
      :has-applied-range="hasDateFilter"
      @click="closeMenus"
      @close="resetPicker"
      @date-range-changed="applyDateRange"
    />
    <Button
      v-else
      :label="$t('AUDIT_LOGS.FILTERS.DATE_RANGE')"
      icon="i-lucide-calendar-range"
      color="slate"
      size="sm"
      @click="openDatePicker"
    />
    <div v-for="menu in filterMenus" :key="menu.key" class="relative">
      <Button
        :icon="menu.icon"
        color="slate"
        size="sm"
        :class="{ 'bg-n-slate-9/10': openFilterMenu === menu.key }"
        @click="toggleFilterMenu(menu.key)"
      >
        <span class="min-w-0 truncate">{{ menu.label }}</span>
        <Icon icon="i-lucide-chevron-down" class="shrink-0 size-4" />
      </Button>
      <DropdownMenu
        v-if="openFilterMenu === menu.key"
        :menu-sections="menu.sections"
        class="mt-2 min-w-52 max-h-80 top-full start-0"
        @action="handleFilterAction"
      />
    </div>
  </div>
</template>
