<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useToggle } from '@vueuse/core';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useTrack } from 'dashboard/composables';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';
import { CONVERSATION_PRIORITY } from 'shared/constants/messages';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import CardPriorityIcon from 'dashboard/components-next/Conversation/ConversationCard/CardPriorityIcon.vue';

const { t } = useI18n();
const store = useStore();

const triggerRef = ref(null);
const dropdownRef = ref(null);

const [openPriorityList, togglePriorityList] = useToggle(false);

const { positionClasses } = useDropdownPosition(triggerRef, dropdownRef);

const currentChat = useMapGetter('getSelectedChat');

const priorityOptions = [
  {
    id: 0,
    name: t('CONVERSATION.PRIORITY.OPTIONS.NONE'),
    priority: null,
  },
  {
    id: CONVERSATION_PRIORITY.URGENT,
    name: t('CONVERSATION.PRIORITY.OPTIONS.URGENT'),
    priority: CONVERSATION_PRIORITY.URGENT,
  },
  {
    id: CONVERSATION_PRIORITY.HIGH,
    name: t('CONVERSATION.PRIORITY.OPTIONS.HIGH'),
    priority: CONVERSATION_PRIORITY.HIGH,
  },
  {
    id: CONVERSATION_PRIORITY.MEDIUM,
    name: t('CONVERSATION.PRIORITY.OPTIONS.MEDIUM'),
    priority: CONVERSATION_PRIORITY.MEDIUM,
  },
  {
    id: CONVERSATION_PRIORITY.LOW,
    name: t('CONVERSATION.PRIORITY.OPTIONS.LOW'),
    priority: CONVERSATION_PRIORITY.LOW,
  },
];

const assignedPriority = computed({
  get() {
    const selectedOption = priorityOptions.find(
      opt => opt.priority === currentChat.value?.priority
    );
    return selectedOption || priorityOptions[0];
  },
  set(priorityItem) {
    const conversationId = currentChat.value.id;
    const oldValue = currentChat.value?.priority;
    const priority = priorityItem ? priorityItem.priority : null;

    store.dispatch('setCurrentChatPriority', {
      priority,
      conversationId,
    });
    store.dispatch('assignPriority', { conversationId, priority }).then(() => {
      useTrack(CONVERSATION_EVENTS.CHANGE_PRIORITY, {
        oldValue,
        newValue: priority,
        from: 'Conversation Sidebar',
      });
      useAlert(
        t('CONVERSATION.PRIORITY.CHANGE_PRIORITY.SUCCESSFUL', {
          priority: priorityItem.name,
          conversationId,
        })
      );
    });
  },
});

const assignedPriorityName = computed(() => {
  return (
    assignedPriority.value?.name || t('CONVERSATION.PRIORITY.OPTIONS.NONE')
  );
});

const priorityMenuItems = computed(() => {
  return priorityOptions.map(option => ({
    label: option.name,
    value: option.id,
    priority: option.priority,
    isSelected: assignedPriority.value?.id === option.id,
    action: 'assignPriority',
  }));
});

const handlePriorityAction = ({ value }) => {
  const selectedPriority = priorityOptions.find(opt => opt.id === value);
  if (assignedPriority.value?.id === value) {
    assignedPriority.value = priorityOptions[0]; // Set to "None"
  } else {
    assignedPriority.value = selectedPriority;
  }
  openPriorityList.value = false;
};
</script>

<template>
  <div class="grid grid-cols-[30%_1fr] gap-3 w-full items-center h-9">
    <span class="text-sm font-420 text-n-slate-11 truncate whitespace-nowrap">
      {{ $t('CONVERSATION.PRIORITY.TITLE') }}
    </span>
    <div
      v-on-click-outside="() => togglePriorityList(false)"
      class="relative w-fit"
    >
      <Button
        ref="triggerRef"
        slate
        :variant="openPriorityList ? 'faded' : 'ghost'"
        :label="assignedPriorityName"
        no-animation
        class="!px-1 !py-1 h-7 !rounded-lg !font-420 !gap-1.5 w-fit !justify-start"
        @click="togglePriorityList()"
      >
        <template #icon>
          <CardPriorityIcon :priority="assignedPriority.priority" show-empty />
        </template>
        <div class="grid grid-cols-[1fr_auto] items-center gap-1.5 min-w-0">
          <span class="truncate min-w-0 font-420">
            {{ assignedPriorityName }}
          </span>
          <Icon
            :icon="
              openPriorityList ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'
            "
            class="size-4 text-n-slate-11 flex-shrink-0"
          />
        </div>
      </Button>
      <DropdownMenu
        v-if="openPriorityList"
        ref="dropdownRef"
        :menu-items="priorityMenuItems"
        :search-placeholder="
          $t('CONVERSATION.PRIORITY.CHANGE_PRIORITY.INPUT_PLACEHOLDER')
        "
        class="z-[100] w-48 overflow-y-auto max-h-60"
        :class="positionClasses"
        @action="handlePriorityAction"
      >
        <template #icon="{ item }">
          <CardPriorityIcon
            :priority="item.priority"
            show-empty
            class="flex-shrink-0"
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
</template>
