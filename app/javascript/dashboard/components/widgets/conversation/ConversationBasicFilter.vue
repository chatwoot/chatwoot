<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useEmitter } from 'dashboard/composables/emitter';
import {
  CMD_SWITCH_SORT,
  CMD_SWITCH_STATUS,
} from 'dashboard/helper/commandbar/events';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import wootConstants from 'dashboard/constants/globals';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  isOnExpandedLayout: {
    type: Boolean,
    required: true,
  },
  // Inside a folder or an applied filter, status and group type are already decided by
  // the query itself, so offering them here would let the agent contradict the folder
  // they are standing in. Order is the one choice that stays theirs.
  showStatusFilter: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['changeFilter']);

const store = useStore();
const { t } = useI18n();

const { updateUISettings } = useUISettings();

const chatStatusFilter = useMapGetter('getChatStatusFilter');
const chatSortFilter = useMapGetter('getChatSortFilter');
const chatGroupTypeFilter = useMapGetter('getChatGroupTypeFilter');

const [showActionsDropdown, toggleDropdown] = useToggle();

// Wider, not narrower. Narrowing it for the single-row case was the wrong instinct: with
// only the sort row left, the label sits next to the longest value in the whole menu
// ("Atividade mais recente primeiro"), and at w-72 the label truncated to "Orden...".
const dropdownWidth = computed(() =>
  props.showStatusFilter ? 'w-72' : 'w-[22rem]'
);

const currentStatusFilter = computed(() => {
  return chatStatusFilter.value || wootConstants.STATUS_TYPE.OPEN;
});

const currentSortBy = computed(() => {
  return (
    chatSortFilter.value || wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC
  );
});

const currentGroupType = computed(() => chatGroupTypeFilter.value || '');

const chatStatusOptions = computed(() => [
  {
    label: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.open.TEXT'),
    value: 'open',
  },
  {
    label: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.resolved.TEXT'),
    value: 'resolved',
  },
  {
    label: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.pending.TEXT'),
    value: 'pending',
  },
  {
    label: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.snoozed.TEXT'),
    value: 'snoozed',
  },
  {
    label: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.all.TEXT'),
    value: 'all',
  },
]);

const chatSortOptions = computed(() => [
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.last_activity_at_asc.TEXT'),
    value: 'last_activity_at_asc',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.last_activity_at_desc.TEXT'),
    value: 'last_activity_at_desc',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.created_at_desc.TEXT'),
    value: 'created_at_desc',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.created_at_asc.TEXT'),
    value: 'created_at_asc',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.unread.TEXT'),
    value: 'unread',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.priority_desc.TEXT'),
    value: 'priority_desc',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.priority_asc.TEXT'),
    value: 'priority_asc',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.priority_desc_created_at_asc.TEXT'),
    value: 'priority_desc_created_at_asc',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.waiting_since_asc.TEXT'),
    value: 'waiting_since_asc',
  },
  {
    label: t('CHAT_LIST.SORT_ORDER_ITEMS.waiting_since_desc.TEXT'),
    value: 'waiting_since_desc',
  },
]);

const chatGroupTypeOptions = computed(() => [
  { label: t('GROUP.FILTER.ALL'), value: '' },
  { label: t('GROUP.FILTER.INDIVIDUAL'), value: 'individual' },
  { label: t('GROUP.FILTER.GROUP'), value: 'group' },
]);

const activeChatStatusLabel = computed(
  () =>
    chatStatusOptions.value.find(m => m.value === chatStatusFilter.value)
      ?.label || ''
);

const activeChatSortLabel = computed(
  () =>
    chatSortOptions.value.find(m => m.value === chatSortFilter.value)?.label ||
    ''
);

const activeGroupTypeLabel = computed(
  () =>
    chatGroupTypeOptions.value.find(m => m.value === chatGroupTypeFilter.value)
      ?.label || t('GROUP.FILTER.ALL')
);

const saveSelectedFilter = (type, value) => {
  updateUISettings({
    conversations_filter_by: {
      status: type === 'status' ? value : currentStatusFilter.value,
      order_by: type === 'sort' ? value : currentSortBy.value,
      group_type: type === 'group_type' ? value : currentGroupType.value,
    },
  });
};

const handleStatusChange = value => {
  emit('changeFilter', value, 'status');
  store.dispatch('setChatStatusFilter', value);
  saveSelectedFilter('status', value);
};

const handleSortChange = value => {
  emit('changeFilter', value, 'sort');
  store.dispatch('setChatSortFilter', value);
  saveSelectedFilter('sort', value);
};

const handleGroupTypeChange = value => {
  emit('changeFilter', value, 'group_type');
  store.dispatch('setChatGroupTypeFilter', value);
  saveSelectedFilter('group_type', value);
};
useEmitter(CMD_SWITCH_STATUS, handleStatusChange);
useEmitter(CMD_SWITCH_SORT, handleSortChange);
</script>

<template>
  <div class="relative flex">
    <NextButton
      v-tooltip.right="$t('CHAT_LIST.SORT_TOOLTIP_LABEL')"
      icon="i-lucide-arrow-up-down"
      slate
      faded
      xs
      @click="toggleDropdown()"
    />
    <div
      v-if="showActionsDropdown"
      v-on-click-outside="() => toggleDropdown()"
      class="mt-1 bg-n-alpha-3 backdrop-blur-[100px] border border-n-weak rounded-xl p-4 absolute z-40 top-full flex flex-col gap-4"
      :class="{
        [dropdownWidth]: true,
        'ltr:left-0 rtl:right-0': !isOnExpandedLayout,
        'ltr:right-0 rtl:left-0': isOnExpandedLayout,
      }"
    >
      <div
        v-if="showStatusFilter"
        class="flex items-center justify-between gap-2"
      >
        <span class="text-sm truncate text-n-slate-12">
          {{ $t('CHAT_LIST.CHAT_SORT.STATUS') }}
        </span>
        <SelectMenu
          :model-value="chatStatusFilter"
          :options="chatStatusOptions"
          :label="activeChatStatusLabel"
          :sub-menu-position="isOnExpandedLayout ? 'left' : 'right'"
          @update:model-value="handleStatusChange"
        />
      </div>
      <div class="flex items-center justify-between gap-2">
        <span
          class="text-sm truncate text-n-slate-12"
          :class="{ 'shrink-0': !showStatusFilter }"
        >
          {{ $t('CHAT_LIST.CHAT_SORT.ORDER_BY') }}
        </span>
        <SelectMenu
          :model-value="chatSortFilter"
          :options="chatSortOptions"
          :label="activeChatSortLabel"
          :sub-menu-position="isOnExpandedLayout ? 'left' : 'right'"
          @update:model-value="handleSortChange"
        />
      </div>
      <div
        v-if="showStatusFilter"
        class="flex items-center justify-between gap-2"
      >
        <span class="text-sm truncate text-n-slate-12">
          {{ $t('GROUP.FILTER.TYPE_LABEL') }}
        </span>
        <SelectMenu
          :model-value="chatGroupTypeFilter"
          :options="chatGroupTypeOptions"
          :label="activeGroupTypeLabel"
          :sub-menu-position="isOnExpandedLayout ? 'left' : 'right'"
          @update:model-value="handleGroupTypeChange"
        />
      </div>
    </div>
  </div>
</template>
