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
    <Transition
      enter-active-class="transition-all duration-150 ease-out origin-bottom"
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
      leave-active-class="transition-all duration-100 ease-in origin-bottom"
      leave-from-class="opacity-100 scale-100"
      leave-to-class="opacity-0 scale-95"
    >
      <DropdownMenu
        v-if="showDropdown"
        v-on-click-outside="[
          () => toggleDropdown(false),
          { ignore: [containerRef] },
        ]"
        :menu-items="updateMenuItems"
        class="ltr:-right-[4.5rem] rtl:-left-[4.5rem] ltr:2xl:right-0 rtl:2xl:left-0 bottom-8 w-36"
        @action="handleUpdate"
      />
    </Transition>
  </div>
</template>
