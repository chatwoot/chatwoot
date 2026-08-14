<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDebounceFn } from '@vueuse/core';
import { subDays, startOfDay, endOfDay } from 'date-fns';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import WootDatePicker from 'dashboard/components/ui/DatePicker/DatePicker.vue';
import { DATE_RANGE_TYPES } from 'dashboard/components/ui/DatePicker/helpers/DatePickerHelper';

const props = defineProps({
  // route-level filters: { q, type, since, until, sort }
  filters: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['update']);

const { t } = useI18n();

const EVENT_TYPE_GROUPS = [
  { key: 'ACCESS', types: [{ value: 'User', key: 'SIGN_IN_OUT' }] },
  {
    key: 'AGENTS_TEAMS',
    types: [
      { value: 'AccountUser', key: 'AGENTS' },
      { value: 'Team', key: 'TEAMS' },
      { value: 'TeamMember', key: 'TEAM_MEMBERS' },
      { value: 'InboxMember', key: 'INBOX_MEMBERS' },
    ],
  },
  {
    key: 'CONFIGURATION',
    types: [
      { value: 'Account', key: 'ACCOUNT' },
      { value: 'Inbox', key: 'INBOXES' },
      { value: 'Webhook', key: 'WEBHOOKS' },
      { value: 'AutomationRule', key: 'AUTOMATION_RULES' },
      { value: 'Macro', key: 'MACROS' },
    ],
  },
];

const showEventMenu = ref(false);

const eventMenuSections = computed(() => [
  {
    items: [
      {
        label: t('AUDIT_LOGS.FILTERS.EVENT_TYPE.ALL'),
        value: '',
        isSelected: !props.filters.type,
      },
    ],
  },
  ...EVENT_TYPE_GROUPS.map(group => ({
    title: t(`AUDIT_LOGS.FILTERS.EVENT_TYPE.GROUPS.${group.key}`),
    items: group.types.map(type => ({
      label: t(`AUDIT_LOGS.FILTERS.EVENT_TYPE.OPTIONS.${type.key}`),
      value: type.value,
      isSelected: props.filters.type === type.value,
    })),
  })),
]);

const activeEventTypeLabel = computed(() => {
  const match = EVENT_TYPE_GROUPS.flatMap(group => group.types).find(
    type => type.value === props.filters.type
  );
  return match
    ? t(`AUDIT_LOGS.FILTERS.EVENT_TYPE.OPTIONS.${match.key}`)
    : t('AUDIT_LOGS.FILTERS.EVENT_TYPE.LABEL');
});

const onEventTypeAction = ({ value }) => {
  showEventMenu.value = false;
  emit('update', { type: value || undefined });
};

const searchText = ref(props.filters.q || '');

watch(
  () => props.filters.q,
  value => {
    searchText.value = value || '';
  }
);

const AUTO_SEARCH_MIN_CHARS = 3;
const AUTO_SEARCH_DELAY = 800;

const submitSearch = () => {
  emit('update', { q: searchText.value || undefined });
};

const autoSearch = useDebounceFn(() => {
  if (searchText.value === (props.filters.q || '')) return;
  if (searchText.value.length < AUTO_SEARCH_MIN_CHARS) return;
  submitSearch();
}, AUTO_SEARCH_DELAY);

const onSearchInput = value => {
  searchText.value = value;
  // Emptying the field clears the filter without waiting for the debounce
  if (value === '' && props.filters.q) {
    emit('update', { q: undefined });
    return;
  }
  autoSearch();
};

const showSortMenu = ref(false);

const activeSort = computed(() =>
  props.filters.sort === 'asc' ? 'asc' : 'desc'
);

const sortMenuItems = computed(() => [
  {
    label: t('AUDIT_LOGS.FILTERS.SORT.NEWEST'),
    value: 'desc',
    isSelected: activeSort.value === 'desc',
  },
  {
    label: t('AUDIT_LOGS.FILTERS.SORT.OLDEST'),
    value: 'asc',
    isSelected: activeSort.value === 'asc',
  },
]);

const activeSortLabel = computed(
  () => sortMenuItems.value.find(item => item.isSelected).label
);

const onSortAction = ({ value }) => {
  showSortMenu.value = false;
  emit('update', { sort: value === 'desc' ? undefined : value });
};

const toEpoch = date => Math.floor(date.getTime() / 1000);
const toDate = seconds => (seconds ? new Date(seconds * 1000) : undefined);

const hasDateFilter = computed(() =>
  Boolean(props.filters.since || props.filters.until)
);

// Shows the picker before any range is applied; the filter only kicks in
// once the user picks a preset or hits apply.
const showPicker = ref(false);

const pickerDateRange = ref([]);
// Custom range until proven otherwise; a URL-restored window has no preset
const pickerRangeType = ref(DATE_RANGE_TYPES.CUSTOM_RANGE);

watch(
  () => [props.filters.since, props.filters.until],
  ([since, until]) => {
    if (since || until) {
      pickerDateRange.value = [
        toDate(since) || startOfDay(subDays(new Date(), 6)),
        toDate(until) || endOfDay(new Date()),
      ];
    } else {
      showPicker.value = false;
      pickerDateRange.value = [];
      pickerRangeType.value = DATE_RANGE_TYPES.LAST_7_DAYS;
    }
  },
  { immediate: true }
);

const onPickerClickaway = () => {
  if (!hasDateFilter.value) showPicker.value = false;
};

const clearDateFilter = () => {
  emit('update', { since: undefined, until: undefined });
};

const onDateRangeChanged = ([startDate, endDate, rangeType]) => {
  if (rangeType) pickerRangeType.value = rangeType;
  emit('update', { since: toEpoch(startDate), until: toEpoch(endDate) });
};
</script>

<template>
  <div class="flex flex-wrap items-center gap-2 mb-4">
    <Input
      :model-value="searchText"
      type="search"
      :placeholder="$t('AUDIT_LOGS.FILTERS.SEARCH_PLACEHOLDER')"
      :custom-input-class="[
        'h-8 ltr:!pl-8 !py-1 rtl:!pr-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1',
      ]"
      class="w-full sm:w-auto sm:flex-1 sm:min-w-56 sm:max-w-72"
      @update:model-value="onSearchInput"
      @enter="submitSearch"
    >
      <template #prefix>
        <Icon
          icon="i-lucide-search"
          class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2 rtl:right-2"
        />
      </template>
    </Input>
    <div class="relative">
      <Button
        icon="i-lucide-list-filter"
        slate
        faded
        sm
        justify="start"
        class="w-48"
        @click="showEventMenu = !showEventMenu"
      >
        <span class="min-w-0 truncate">{{ activeEventTypeLabel }}</span>
        <Icon
          icon="i-lucide-chevron-down"
          class="flex-shrink-0 size-3.5 ltr:ml-auto rtl:mr-auto"
        />
      </Button>
      <DropdownMenu
        v-if="showEventMenu"
        v-on-clickaway="() => (showEventMenu = false)"
        :menu-sections="eventMenuSections"
        class="top-full mt-1 ltr:left-0 rtl:right-0 max-h-80"
        @action="onEventTypeAction"
      />
    </div>
    <div class="relative">
      <Button
        icon="i-lucide-arrow-down-up"
        slate
        faded
        sm
        justify="start"
        @click="showSortMenu = !showSortMenu"
      >
        <span class="min-w-0 truncate">{{ activeSortLabel }}</span>
        <Icon icon="i-lucide-chevron-down" class="flex-shrink-0 size-3.5" />
      </Button>
      <DropdownMenu
        v-if="showSortMenu"
        v-on-clickaway="() => (showSortMenu = false)"
        :menu-items="sortMenuItems"
        class="top-full mt-1 ltr:left-0 rtl:right-0"
        @action="onSortAction"
      />
    </div>
    <div
      v-if="hasDateFilter || showPicker"
      v-on-clickaway="onPickerClickaway"
      class="flex items-center gap-2"
    >
      <WootDatePicker
        v-model:date-range="pickerDateRange"
        v-model:range-type="pickerRangeType"
        :default-open="!hasDateFilter"
        @date-range-changed="onDateRangeChanged"
      />
      <Button
        v-if="hasDateFilter"
        v-tooltip.top="$t('AUDIT_LOGS.FILTERS.CLEAR_DATE_RANGE')"
        icon="i-lucide-x"
        slate
        ghost
        sm
        @click="clearDateFilter"
      />
    </div>
    <Button
      v-else
      :label="$t('AUDIT_LOGS.FILTERS.DATE_RANGE')"
      icon="i-lucide-calendar-range"
      slate
      faded
      sm
      @click="showPicker = true"
    />
  </div>
</template>
