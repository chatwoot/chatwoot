<script setup>
import { useTemplateRef, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';

import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  showResolve: {
    type: Boolean,
    default: true,
  },
  showReopen: {
    type: Boolean,
    default: true,
  },
  showSnooze: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['update']);

const { t } = useI18n();

const containerRef = useTemplateRef('containerRef');
const [showDropdown, toggleDropdown] = useToggle(false);

const updateMenuItems = computed(() => {
  const items = [];

  if (props.showResolve) {
    items.push({
      action: 'update',
      value: 'resolved',
      label: t('CONVERSATION.HEADER.RESOLVE_ACTION'),
      icon: 'i-lucide-check',
    });
  }

  if (props.showReopen) {
    items.push({
      action: 'update',
      value: 'open',
      label: t('CONVERSATION.HEADER.REOPEN_ACTION'),
      icon: 'i-lucide-redo',
    });
  }

  if (props.showSnooze) {
    items.push({
      action: 'update',
      value: 'snoozed',
      label: t('BULK_ACTION.UPDATE.SNOOZE_UNTIL'),
      icon: 'i-lucide-alarm-clock',
    });
  }

  return items;
});

const handleUpdate = item => {
  if (item.value === 'snoozed') {
    // If the user clicks on the snooze option from the bulk action change status dropdown.
    // Open the snooze option for bulk action in the cmd bar.
    const ninja = document.querySelector('ninja-keys');
    ninja?.open({ parent: 'bulk_action_snooze_conversation' });
  } else {
    emit('update', item.value);
  }
  toggleDropdown(false);
};
</script>

<template>
  <div ref="containerRef" class="relative">
    <Button
      v-tooltip="$t('BULK_ACTION.UPDATE.CHANGE_STATUS')"
      icon="i-lucide-circle-fading-arrow-up"
      slate
      xs
      ghost
      :class="{ 'bg-n-alpha-2': showDropdown }"
      @click="toggleDropdown()"
    />
    <DropdownMenu
      v-if="showDropdown"
      v-on-click-outside="[
        () => toggleDropdown(false),
        { ignore: [containerRef] },
      ]"
      :menu-items="updateMenuItems"
      class="ltr:left-0 rtl:right-0 top-8 w-36"
      @action="handleUpdate"
    />
  </div>
</template>
