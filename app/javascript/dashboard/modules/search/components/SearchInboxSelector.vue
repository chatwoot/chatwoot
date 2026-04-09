<script setup>
import { ref, computed, defineModel } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  label: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['change']);
const modelValue = defineModel({
  type: [String, Number],
  default: null,
});

const MENU_ITEM_TYPES = {
  INBOX: 'inbox',
};

const MENU_ACTIONS = {
  SELECT: 'select',
};

const { t } = useI18n();
const [showDropdown, toggleDropdown] = useToggle();

const searchQuery = ref('');

const inboxesList = useMapGetter('inboxes/getInboxes');

const inboxesSection = computed(() => {
  const inboxes = inboxesList.value?.map(inbox => {
    const transformedInbox = useCamelCase(inbox, { deep: true });
    return {
      label: transformedInbox.name,
      value: transformedInbox.id,
      action: MENU_ACTIONS.SELECT,
      type: MENU_ITEM_TYPES.INBOX,
      thumbnail: {
        name: transformedInbox.name,
        src: transformedInbox.avatarUrl,
      },
      isSelected: modelValue.value === transformedInbox.id,
    };
  });

  if (!searchQuery.value) return inboxes;

  return inboxes.filter(inbox =>
    inbox.label.toLowerCase().includes(searchQuery.value.toLowerCase())
  );
});

const menuSections = computed(() => {
  return [
    {
      title: t('SEARCH.FILTERS.INBOXES'),
      items: inboxesSection.value,
      emptyState: t('SEARCH.FILTERS.NO_INBOXES'),
    },
  ];
});

const selectedLabel = computed(() => {
  if (!modelValue.value) return props.label;

  // Find the selected inbox
  const inbox = inboxesList.value?.find(i => i.id === modelValue.value);
  if (inbox) return `${props.label}: ${inbox.name}`;

  return `${props.label}: ${modelValue.value}`;
});

const handleAction = item => {
  if (modelValue.value === item.value) {
    modelValue.value = null;
  } else {
    modelValue.value = item.value;
  }
  toggleDropdown(false);
  emit('change');
};

const onToggleDropdown = () => {
  if (!showDropdown.value) {
    searchQuery.value = '';
  }
  toggleDropdown();
};
</script>

<template>
  <div
    v-on-click-outside="() => toggleDropdown(false)"
    class="relative flex items-center group min-w-0 max-w-full"
  >
    <Button
      sm
      :variant="showDropdown ? 'faded' : 'ghost'"
      slate
      :label="selectedLabel"
      trailing-icon
      icon="i-lucide-chevron-down"
      class="!px-2 max-w-full"
      @click="onToggleDropdown"
    />
    <DropdownMenu
      v-if="showDropdown"
      :menu-sections="menuSections"
      show-search
      disable-local-filtering
      class="mt-1 ltr:right-0 rtl:left-0 top-full w-64 max-h-80 overflow-y-auto"
      @search="searchQuery = $event"
      @action="handleAction"
    />
  </div>
</template>
