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
  teamsList: {
    type: Array,
    default: () => [],
  },
});

const { t } = useI18n();
const store = useStore();

const triggerRef = ref(null);
const dropdownRef = ref(null);

const [openTeamsList, toggleTeamsList] = useToggle(false);

const { positionClasses } = useDropdownPosition(
  triggerRef,
  dropdownRef,
  openTeamsList
);

const currentChat = useMapGetter('getSelectedChat');

const assignedTeam = computed({
  get() {
    return currentChat.value?.meta?.team;
  },
  set(team) {
    const conversationId = currentChat.value.id;
    const teamId = team ? team.id : 0;
    store.dispatch('setCurrentChatTeam', { team, conversationId });
    store.dispatch('assignTeam', { conversationId, teamId }).then(() => {
      useAlert(t('CONVERSATION.CHANGE_TEAM'));
    });
  },
});

const assignedTeamName = computed(() => {
  return assignedTeam.value?.name || t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER');
});

const teamMenuItems = computed(() => {
  const items = [];

  // Add "None" option as first item
  items.push({
    label: t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER'),
    value: 0,
    isSelected: !assignedTeam.value,
    thumbnail: { name: t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER') },
    action: 'unassignTeam',
  });

  // Add all teams, sorted by selection and then by name
  const teamItems = props.teamsList
    .filter(team => team.id !== 0) // Filter out the "None" option if it exists in teamsList
    .map(team => ({
      label: team.name,
      value: team.id,
      thumbnail: { name: team.name },
      isSelected: assignedTeam.value?.id === team.id,
      action: 'assignTeam',
    }))
    .toSorted((a, b) => {
      if (a.isSelected !== b.isSelected) {
        return Number(b.isSelected) - Number(a.isSelected);
      }
      return a.label.localeCompare(b.label);
    });

  return [...items, ...teamItems];
});

const handleTeamAction = ({ action, value }) => {
  if (action === 'unassignTeam') {
    // Unassign team (set to null)
    assignedTeam.value = null;
    toggleTeamsList(false);
  } else if (action === 'assignTeam') {
    // Assign selected team
    const selectedTeam = props.teamsList.find(team => team.id === value);
    if (assignedTeam.value && assignedTeam.value.id === value) {
      assignedTeam.value = null;
    } else {
      assignedTeam.value = selectedTeam;
    }
    toggleTeamsList(false);
  }
};
</script>

<template>
  <div class="grid grid-cols-[30%_1fr] gap-3 w-full items-center h-9">
    <span class="text-sm font-420 text-n-slate-11 truncate whitespace-nowrap">
      {{ $t('CONVERSATION_SIDEBAR.TEAM_LABEL') }}
    </span>
    <div
      v-on-click-outside="() => toggleTeamsList(false)"
      class="relative w-fit"
    >
      <Button
        ref="triggerRef"
        slate
        :variant="openTeamsList ? 'faded' : 'ghost'"
        :label="assignedTeamName"
        no-animation
        class="!px-1 !py-1 h-7 !rounded-lg !font-420 !gap-1.5 w-fit !justify-start"
        @click="toggleTeamsList()"
      >
        <template #icon>
          <Avatar
            v-if="assignedTeam"
            :name="assignedTeamName"
            :size="16"
            rounded-full
          />
        </template>
        <div class="grid grid-cols-[1fr_auto] items-center gap-1.5 min-w-0">
          <span class="truncate min-w-0 font-420">
            {{ assignedTeamName }}
          </span>
          <Icon
            :icon="
              openTeamsList ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'
            "
            class="size-4 text-n-slate-11 flex-shrink-0"
          />
        </div>
      </Button>
      <DropdownMenu
        v-if="openTeamsList"
        ref="dropdownRef"
        :menu-items="teamMenuItems"
        show-search
        :thumbnail-size="16"
        :rounded-thumbnail="false"
        :search-placeholder="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.TEAM')
        "
        class="z-[100] w-52 overflow-y-auto max-h-60"
        :class="positionClasses"
        @action="handleTeamAction"
      >
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
