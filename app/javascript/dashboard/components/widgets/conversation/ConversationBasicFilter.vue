<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import wootConstants from 'dashboard/constants/globals';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

defineProps({
  isOnExpandedLayout: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits(['changeFilter']);

const store = useStore();
const { t } = useI18n();

const { updateUISettings } = useUISettings();

const chatStatusFilter = useMapGetter('getChatStatusFilter');
const chatSortFilter = useMapGetter('getChatSortFilter');

const [showActionsDropdown, toggleDropdown] = useToggle();
const [showSortMenu, toggleSortMenu] = useToggle();

const currentStatusFilter = computed(() => {
  return chatStatusFilter.value || wootConstants.STATUS_TYPE.OPEN;
});

const currentSortBy = computed(() => {
  return (
    chatSortFilter.value || wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC
  );
});

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

const chatSortGroups = computed(() => [
  {
    icon: 'i-lucide-activity',
    title: t('CHAT_LIST.SORT_ORDER_GROUPS.LAST_ACTIVITY'),
    options: [
      {
        label: t('CHAT_LIST.SORT_ORDER_ITEMS.last_activity_at_desc.SHORT'),
        value: 'last_activity_at_desc',
      },
      {
        label: t('CHAT_LIST.SORT_ORDER_ITEMS.last_activity_at_asc.SHORT'),
        value: 'last_activity_at_asc',
      },
    ],
  },
  {
    icon: 'i-lucide-calendar',
    title: t('CHAT_LIST.SORT_ORDER_GROUPS.CREATED_AT'),
    options: [
      {
        label: t('CHAT_LIST.SORT_ORDER_ITEMS.created_at_desc.SHORT'),
        value: 'created_at_desc',
      },
      {
        label: t('CHAT_LIST.SORT_ORDER_ITEMS.created_at_asc.SHORT'),
        value: 'created_at_asc',
      },
    ],
  },
  {
    icon: 'i-lucide-signal',
    title: t('CHAT_LIST.SORT_ORDER_GROUPS.PRIORITY'),
    options: [
      {
        label: t('CHAT_LIST.SORT_ORDER_ITEMS.priority_desc.SHORT'),
        value: 'priority_desc',
      },
      {
        label: t('CHAT_LIST.SORT_ORDER_ITEMS.priority_asc.SHORT'),
        value: 'priority_asc',
      },
      {
        label: t(
          'CHAT_LIST.SORT_ORDER_ITEMS.priority_desc_created_at_asc.SHORT'
        ),
        value: 'priority_desc_created_at_asc',
      },
    ],
  },
  {
    icon: 'i-lucide-clock',
    title: t('CHAT_LIST.SORT_ORDER_GROUPS.WAITING_SINCE'),
    options: [
      {
        label: t('CHAT_LIST.SORT_ORDER_ITEMS.waiting_since_asc.SHORT'),
        value: 'waiting_since_asc',
      },
      {
        label: t('CHAT_LIST.SORT_ORDER_ITEMS.waiting_since_desc.SHORT'),
        value: 'waiting_since_desc',
      },
    ],
  },
]);

const activeChatStatusLabel = computed(
  () =>
    chatStatusOptions.value.find(m => m.value === chatStatusFilter.value)
      ?.label || ''
);

const activeChatSortLabel = computed(() => {
  const allOptions = chatSortGroups.value.flatMap(group =>
    group.options.map(o => ({ ...o, groupTitle: group.title }))
  );
  const match = allOptions.find(o => o.value === chatSortFilter.value);
  return match ? `${match.groupTitle}: ${match.label}` : '';
});

const saveSelectedFilter = (type, value) => {
  updateUISettings({
    conversations_filter_by: {
      status: type === 'status' ? value : currentStatusFilter.value,
      order_by: type === 'sort' ? value : currentSortBy.value,
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

const handleSortSelect = value => {
  handleSortChange(value);
  toggleSortMenu(false);
};
</script>

<template>
  <div class="relative flex">
    <NextButton
      v-tooltip.right="$t('CHAT_LIST.SORT_TOOLTIP_LABEL')"
      icon="i-lucide-arrow-up-down"
      slate
      faded
      xs
      @click="
        toggleDropdown();
        toggleSortMenu(false);
      "
    />
    <div
      v-if="showActionsDropdown"
      v-on-click-outside="
        () => {
          toggleDropdown(false);
          toggleSortMenu(false);
        }
      "
      class="mt-1 bg-n-alpha-3 backdrop-blur-[100px] border border-n-weak w-72 rounded-xl p-4 absolute z-40 top-full"
      :class="{
        'ltr:left-0 rtl:right-0': !isOnExpandedLayout,
        'ltr:right-0 rtl:left-0': isOnExpandedLayout,
      }"
    >
      <div class="flex items-center justify-between last:mt-4 gap-2">
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
      <div class="flex items-center justify-between last:mt-4 gap-2">
        <span class="text-sm truncate text-n-slate-12">
          {{ $t('CHAT_LIST.CHAT_SORT.ORDER_BY') }}
        </span>
        <div
          v-on-click-outside="() => toggleSortMenu(false)"
          class="relative flex flex-col gap-1 w-fit"
        >
          <NextButton
            icon="i-lucide-chevron-down"
            size="sm"
            trailing-icon
            color="slate"
            variant="faded"
            class="!w-fit max-w-40"
            :class="{ 'dark:!bg-n-alpha-2 !bg-n-slate-9/20': showSortMenu }"
            :label="activeChatSortLabel"
            @click="toggleSortMenu()"
          />
          <div
            v-if="showSortMenu"
            class="absolute select-none w-56 flex flex-col bg-n-alpha-3 backdrop-blur-[100px] py-2 px-1 top-0 shadow-lg z-40 rounded-lg border border-n-weak dark:border-n-strong/50"
            :class="{
              'ltr:left-full rtl:right-full ltr:ml-1 rtl:mr-1':
                !isOnExpandedLayout,
              'ltr:right-full rtl:left-full ltr:mr-1 rtl:ml-1':
                isOnExpandedLayout,
            }"
          >
            <template
              v-for="(group, gIdx) in chatSortGroups"
              :key="group.title"
            >
              <div v-if="gIdx > 0" class="h-px bg-n-alpha-2 mx-1 my-1" />
              <div class="flex items-center gap-1.5 px-2 pt-1.5 pb-0.5">
                <span class="size-3 text-n-slate-10" :class="group.icon" />
                <span
                  class="text-[11px] font-medium text-n-slate-10 uppercase tracking-wide"
                >
                  {{ group.title }}
                </span>
              </div>
              <button
                v-for="option in group.options"
                :key="option.value"
                type="button"
                class="flex items-center gap-2 w-full px-2 py-1 rounded-lg text-sm text-n-slate-12 hover:bg-n-alpha-1 dark:hover:bg-n-alpha-2 transition-colors"
                :class="{
                  'bg-n-alpha-1 dark:bg-n-alpha-2':
                    option.value === chatSortFilter,
                }"
                @click="handleSortSelect(option.value)"
              >
                <span
                  class="size-3.5 flex-shrink-0"
                  :class="
                    option.value === chatSortFilter
                      ? 'i-lucide-check text-n-blue-11'
                      : ''
                  "
                />
                <span>{{ option.label }}</span>
              </button>
            </template>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
