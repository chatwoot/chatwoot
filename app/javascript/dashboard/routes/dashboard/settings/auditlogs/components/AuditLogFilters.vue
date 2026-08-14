<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDebounceFn } from '@vueuse/core';
import { subDays, startOfDay, endOfDay } from 'date-fns';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';
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
  {
    key: 'CONVERSATIONS',
    types: [
      { value: 'Conversation', key: 'CONVERSATION_DELETIONS' },
      { value: 'Message', key: 'MESSAGE_DELETIONS' },
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

const onSearchInput = useDebounceFn(event => {
  emit('update', { q: event.target.value });
}, 300);

const sortOptions = computed(() => [
  { label: t('AUDIT_LOGS.FILTERS.SORT.NEWEST'), value: 'desc' },
  { label: t('AUDIT_LOGS.FILTERS.SORT.OLDEST'), value: 'asc' },
]);

const activeSort = computed(() =>
  props.filters.sort === 'asc' ? 'asc' : 'desc'
);

const activeSortLabel = computed(
  () =>
    sortOptions.value.find(option => option.value === activeSort.value).label
);

const onSortChange = value => {
  emit('update', { sort: value === 'desc' ? undefined : value });
};

const toEpoch = date => Math.floor(date.getTime() / 1000);
const toDate = seconds => (seconds ? new Date(seconds * 1000) : undefined);

const hasDateFilter = computed(() =>
  Boolean(props.filters.since || props.filters.until)
);

const pickerDateRange = ref([]);
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
      pickerDateRange.value = [];
      pickerRangeType.value = DATE_RANGE_TYPES.CUSTOM_RANGE;
    }
  },
  { immediate: true }
);

const enableDateFilter = () => {
  pickerRangeType.value = DATE_RANGE_TYPES.LAST_7_DAYS;
  emit('update', {
    since: toEpoch(startOfDay(subDays(new Date(), 6))),
    until: toEpoch(endOfDay(new Date())),
  });
};

const clearDateFilter = () => {
  emit('update', { since: undefined, until: undefined });
};

const onDateRangeChanged = ([startDate, endDate]) => {
  emit('update', { since: toEpoch(startDate), until: toEpoch(endDate) });
};
</script>

<template>
  <div class="flex flex-col lg:flex-row lg:items-center gap-2 mb-4">
    <Input
      :model-value="filters.q || ''"
      type="search"
      :placeholder="$t('AUDIT_LOGS.FILTERS.SEARCH_PLACEHOLDER')"
      :custom-input-class="['h-8 ltr:!pl-8 !py-1 rtl:!pr-8']"
      class="lg:max-w-72 w-full"
      @input="onSearchInput"
    >
      <template #prefix>
        <Icon
          icon="i-lucide-search"
          class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2 rtl:right-2"
        />
      </template>
    </Input>
    <div class="flex items-center gap-2 flex-wrap">
      <div class="relative">
        <Button
          :label="activeEventTypeLabel"
          icon="i-lucide-chevron-down"
          trailing-icon
          slate
          faded
          sm
          @click="showEventMenu = !showEventMenu"
        />
        <DropdownMenu
          v-if="showEventMenu"
          v-on-clickaway="() => (showEventMenu = false)"
          :menu-sections="eventMenuSections"
          class="top-full mt-1 ltr:left-0 rtl:right-0 max-h-80"
          @action="onEventTypeAction"
        />
      </div>
      <template v-if="hasDateFilter">
        <WootDatePicker
          v-model:date-range="pickerDateRange"
          v-model:range-type="pickerRangeType"
          @date-range-changed="onDateRangeChanged"
        />
        <Button
          v-tooltip.top="$t('AUDIT_LOGS.FILTERS.CLEAR_DATE_RANGE')"
          icon="i-lucide-x"
          slate
          ghost
          sm
          @click="clearDateFilter"
        />
      </template>
      <Button
        v-else
        :label="$t('AUDIT_LOGS.FILTERS.DATE_RANGE')"
        icon="i-lucide-calendar-range"
        slate
        faded
        sm
        @click="enableDateFilter"
      />
      <SelectMenu
        :model-value="activeSort"
        :options="sortOptions"
        :label="activeSortLabel"
        @update:model-value="onSortChange"
      />
    </div>
  </div>
</template>
