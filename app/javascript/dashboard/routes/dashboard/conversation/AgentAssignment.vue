<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useToggle } from '@vueuse/core';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';

import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  agentsList: {
    type: Array,
    default: () => [],
  },
});

const { t } = useI18n();
const store = useStore();

const triggerRef = ref(null);
const dropdownRef = ref(null);

const [openAgentsList, toggleAgentsList] = useToggle(false);

const { positionClasses } = useDropdownPosition(
  triggerRef,
  dropdownRef,
  openAgentsList
);

const currentChat = useMapGetter('getSelectedChat');
const currentUser = useMapGetter('getCurrentUser');

const assignedAgent = computed({
  get() {
    return currentChat.value?.meta?.assignee;
  },
  set(agent) {
    const agentId = agent ? agent.id : 0;
    store.dispatch('setCurrentChatAssignee', agent);
    store
      .dispatch('assignAgent', {
        conversationId: currentChat.value.id,
        agentId,
      })
      .then(() => {
        useAlert(t('CONVERSATION.CHANGE_AGENT'));
      });
  },
});

const showSelfAssign = computed(() => {
  if (!assignedAgent.value) {
    return true;
  }
  if (assignedAgent.value.id !== currentUser.value.id) {
    return true;
  }
  return false;
});

const assignedAgentName = computed(() => {
  return (
    assignedAgent.value?.name ||
    assignedAgent.value?.available_name ||
    t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')
  );
});

const assignedAgentThumbnail = computed(() => {
  return assignedAgent.value?.thumbnail;
});

const agentMenuItems = computed(() => {
  const items = [];

  // Add "Self Assign" option if applicable
  if (showSelfAssign.value) {
    items.push({
      label: t('CONVERSATION_SIDEBAR.SELF_ASSIGN'),
      value: currentUser.value.id,
      icon: 'i-lucide-user-round-check',
      isSelected: false,
      action: 'selfAssign',
    });
  }

  // Map all agents and sort with "None" (id: 0) first, then selected, then alphabetically
  const agentItems = props.agentsList
    .map(agent => ({
      label: agent.name || agent.available_name,
      value: agent.id,
      thumbnail: {
        name: agent.name || agent.available_name,
        src: agent.thumbnail,
      },
      isSelected: assignedAgent.value?.id === agent.id,
      action: agent.id === 0 ? 'unassignAgent' : 'assignAgent',
    }))
    .toSorted((a, b) => {
      // "None" option (id: 0) always first
      if (a.value === 0) return -1;
      if (b.value === 0) return 1;

      // Then sort by selection
      if (a.isSelected !== b.isSelected) {
        return Number(b.isSelected) - Number(a.isSelected);
      }

      // Finally sort alphabetically
      return a.label.localeCompare(b.label);
    });

  return [...items, ...agentItems];
});

const onSelfAssign = () => {
  const {
    account_id,
    availability_status,
    available_name,
    email,
    id,
    name,
    role,
    avatar_url,
  } = currentUser.value;
  const selfAssign = {
    account_id,
    availability_status,
    available_name,
    email,
    id,
    name,
    role,
    thumbnail: avatar_url,
  };
  assignedAgent.value = selfAssign;
  toggleAgentsList(false);
};

const handleAgentAction = ({ action, value }) => {
  if (action === 'unassignAgent') {
    assignedAgent.value = null;
    toggleAgentsList(false);
  } else if (action === 'selfAssign') {
    // Self assign current user
    onSelfAssign();
  } else if (action === 'assignAgent') {
    // Assign selected agent
    const selectedAgent = props.agentsList.find(agent => agent.id === value);
    if (assignedAgent.value && assignedAgent.value.id === value) {
      assignedAgent.value = null;
    } else {
      assignedAgent.value = selectedAgent;
    }
    toggleAgentsList(false);
  }
};
</script>

<template>
  <div class="grid grid-cols-[30%_1fr] gap-3 w-full items-center h-9">
    <span class="text-sm font-420 text-n-slate-11 truncate whitespace-nowrap">
      {{ $t('CONVERSATION_SIDEBAR.ASSIGNEE_LABEL') }}
    </span>
    <div
      v-on-click-outside="() => toggleAgentsList(false)"
      class="relative w-fit"
    >
      <Button
        ref="triggerRef"
        slate
        :variant="openAgentsList ? 'faded' : 'ghost'"
        :label="assignedAgentName"
        no-animation
        class="!px-1 !py-1 h-7 !rounded-lg !font-420 !gap-1.5 w-fit !justify-start"
        @click="toggleAgentsList()"
      >
        <template #icon>
          <Avatar
            v-if="assignedAgent"
            :name="assignedAgentName"
            :src="assignedAgentThumbnail"
            :size="16"
            rounded-full
          />
        </template>
        <div class="grid grid-cols-[1fr_auto] items-center gap-1.5 min-w-0">
          <span class="truncate min-w-0 font-420">
            {{ assignedAgentName }}
          </span>
          <Icon
            :icon="
              openAgentsList ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'
            "
            class="size-4 text-n-slate-11 flex-shrink-0"
          />
        </div>
      </Button>
      <DropdownMenu
        v-if="openAgentsList"
        ref="dropdownRef"
        :menu-items="agentMenuItems"
        show-search
        :thumbnail-size="16"
        :rounded-thumbnail="false"
        :search-placeholder="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
        "
        class="z-[100] w-52 overflow-y-auto max-h-60"
        :class="positionClasses"
        @action="handleAgentAction"
      >
        <template #icon="{ item }">
          <Icon
            v-if="item.icon"
            :icon="item.icon"
            class="flex-shrink-0 size-4 font-420"
            :class="
              item.action === 'selfAssign'
                ? 'text-n-blue-11'
                : 'text-n-slate-11'
            "
          />
        </template>
        <template #label="{ item }">
          <span
            v-if="item.label"
            class="min-w-0 text-sm truncate"
            :class="item.action === 'selfAssign' ? 'text-n-blue-11' : ''"
          >
            {{ item.label }}
          </span>
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
