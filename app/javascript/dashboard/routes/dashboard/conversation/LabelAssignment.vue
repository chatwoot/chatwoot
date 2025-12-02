<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { vOnClickOutside } from '@vueuse/components';
import { useToggle } from '@vueuse/core';
import { useConversationLabels } from 'dashboard/composables/useConversationLabels';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useMapGetter } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const {
  activeLabels,
  accountLabels,
  addLabelToConversation,
  removeLabelFromConversation,
} = useConversationLabels();

const conversationUiFlags = useMapGetter('conversationLabels/getUIFlags');

const triggerRef = ref(null);
const dropdownRef = ref(null);

const [openLabelsList, toggleLabels] = useToggle(false);

const { positionClasses, updatePosition } = useDropdownPosition(
  triggerRef,
  dropdownRef,
  openLabelsList
);

// Update position of dropdown when labels change
watch(
  activeLabels,
  async () => {
    if (openLabelsList.value) {
      await nextTick();
      updatePosition();
    }
  },
  { deep: true }
);

const keyboardEvents = {
  KeyL: {
    action: e => {
      e.preventDefault();
      toggleLabels();
    },
  },
  Escape: {
    action: () => {
      if (openLabelsList.value) {
        toggleLabels();
      }
    },
    allowOnFocusedInput: true,
  },
};
useKeyboardEvents(keyboardEvents);

const labelMenuItems = computed(() => {
  return accountLabels.value.map(label => ({
    label: label.title,
    value: label.id,
    color: label.color,
    isSelected: activeLabels.value.some(active => active.id === label.id),
    action: 'toggleLabel',
  }));
});

const handleLabelAction = ({ value }) => {
  const label = accountLabels.value.find(l => l.id === value);
  if (!label) return;

  const isSelected = activeLabels.value.some(active => active.id === value);

  if (isSelected) {
    removeLabelFromConversation(label.title);
  } else {
    addLabelToConversation(label);
  }
};
</script>

<template>
  <div class="flex flex-wrap gap-3 w-full items-start pt-3">
    <Spinner
      v-if="conversationUiFlags.isFetching"
      :size="22"
      class="text-n-slate-10"
    />
    <div v-else class="flex flex-wrap gap-2.5">
      <div
        v-for="(label, index) in activeLabels"
        :key="label ? label.id : index"
        data-label
        :title="label.description"
        class="bg-n-button-color px-2.5 h-8 gap-1.5 rounded-lg -outline-offset-1 outline outline-1 outline-n-container inline-flex items-center flex-shrink-0"
      >
        <span
          class="rounded-sm size-2 flex-shrink-0"
          :style="{ background: label.color }"
        />
        <span class="font-420 text-sm text-n-slate-12 whitespace-nowrap">
          {{ label.title }}
        </span>
      </div>
      <div
        v-on-click-outside="() => toggleLabels(false)"
        class="relative w-fit"
      >
        <Button
          ref="triggerRef"
          :label="$t('CONTACT_PANEL.LABELS.CONVERSATION.ADD_BUTTON')"
          slate
          sm
          icon="i-lucide-plus"
          :variant="openLabelsList ? 'faded' : 'solid'"
          class="font-460 !-outline-offset-1"
          @click="toggleLabels()"
        />
        <DropdownMenu
          v-if="openLabelsList"
          ref="dropdownRef"
          :menu-items="labelMenuItems"
          show-search
          :search-placeholder="
            $t('CONTACT_PANEL.LABELS.LABEL_SELECT.PLACEHOLDER')
          "
          class="z-[100] w-56 overflow-y-auto max-h-60"
          :class="positionClasses"
          @action="handleLabelAction"
        >
          <template #thumbnail="{ item }">
            <span
              class="rounded-sm size-2 flex-shrink-0"
              :style="{ background: item.color }"
            />
          </template>
          <template #trailing-icon="{ item }">
            <Icon
              v-if="item.isSelected"
              icon="i-lucide-check"
              class="size-4 text-n-blue-11 flex-shrink-0"
            />
          </template>
        </DropdownMenu>
      </div>
    </div>
  </div>
</template>
