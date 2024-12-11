<script setup>
import { ref, computed, toRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';

import Button from 'dashboard/components-next/button/Button.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';

const props = defineProps({
  activeStatus: {
    type: String,
    default: 'open',
  },
  activeOrdering: {
    type: String,
    default: 'last_activity_at_desc',
  },
});

const emit = defineEmits(['update:activeStatus', 'update:activeOrdering']);

const { t } = useI18n();

const CHAT_STATUS_FILTER_ITEMS = Object.freeze([
  'open',
  'resolved',
  'pending',
  'snoozed',
  'all',
]);

const SORT_ORDER_ITEMS = Object.freeze([
  'last_activity_at_asc',
  'last_activity_at_desc',
  'created_at_desc',
  'created_at_asc',
  'priority_desc',
  'priority_asc',
  'waiting_since_asc',
  'waiting_since_desc',
]);

// Converted to ref to avoid reactivity issues
const activeStatus = toRef(props, 'activeStatus');
const activeOrdering = toRef(props, 'activeOrdering');

const statusMenus = computed(() => {
  return CHAT_STATUS_FILTER_ITEMS.map(item => ({
    label: t(`CONVERSATION_LIST.CHAT_STATUS.OPTIONS.${item.toUpperCase()}`),
    value: item,
  }));
});

const orderingMenus = computed(() => {
  return SORT_ORDER_ITEMS.map(item => ({
    label: t(`CONVERSATION_LIST.CHAT_SORT_ORDER.OPTIONS.${item.toUpperCase()}`),
    value: item,
  }));
});

const activeStatusLabel = computed(() => {
  return t(
    `CONVERSATION_LIST.CHAT_STATUS.OPTIONS.${activeStatus.value.toUpperCase()}`
  );
});

const activeOrderingLabel = computed(() => {
  return t(
    `CONVERSATION_LIST.CHAT_SORT_ORDER.OPTIONS.${activeOrdering.value.toUpperCase()}`
  );
});

const isMenuOpen = ref(false);

const handleStatusChange = value => {
  emit('update:activeStatus', value);
};

const handleOrderChange = value => {
  emit('update:activeOrdering', value);
};
</script>

<template>
  <div class="relative">
    <Button
      icon="i-lucide-arrow-down-up"
      color="slate"
      size="sm"
      variant="ghost"
      :class="isMenuOpen ? 'bg-n-alpha-2' : ''"
      @click="isMenuOpen = !isMenuOpen"
    />
    <div
      v-if="isMenuOpen"
      v-on-click-outside="() => (isMenuOpen = false)"
      class="absolute top-full mt-1 ltr:right-0 rtl:left-0 flex flex-col gap-4 bg-n-alpha-3 backdrop-blur-[100px] border border-n-weak w-72 rounded-xl p-4"
    >
      <div class="flex items-center justify-between gap-2">
        <span class="text-sm text-n-slate-12">
          {{ t('CONVERSATION_LIST.CHAT_STATUS.LABEL') }}
        </span>
        <SelectMenu
          :model-value="activeStatus"
          :options="statusMenus"
          :label="activeStatusLabel"
          @update:model-value="handleStatusChange"
        />
      </div>
      <div class="flex items-center justify-between gap-2">
        <span class="text-sm text-n-slate-12">
          {{ t('CONVERSATION_LIST.CHAT_SORT_ORDER.LABEL') }}
        </span>
        <SelectMenu
          :model-value="activeOrdering"
          :options="orderingMenus"
          :label="activeOrderingLabel"
          @update:model-value="handleOrderChange"
        />
      </div>
    </div>
  </div>
</template>
