<script setup>
import { computed, ref } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  assigneeId: {
    type: Number,
    default: null,
  },
  teamId: {
    type: Number,
    default: null,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select']);

const { t } = useI18n();

const agents = useMapGetter('agents/getVerifiedAgents');
const teams = useMapGetter('teams/getTeams');

const isOpen = ref(false);

const selectedAgent = computed(
  () => agents.value.find(agent => agent.id === props.assigneeId) || null
);

const selectedTeam = computed(
  () => teams.value.find(team => team.id === props.teamId) || null
);

const label = computed(
  () =>
    selectedAgent.value?.name ||
    selectedTeam.value?.name ||
    t('TICKETS.TASKS.OWNER_PLACEHOLDER')
);

const menuSections = computed(() => [
  {
    items: [
      {
        label: t('TICKETS.TASKS.OWNER_NONE'),
        value: null,
        action: 'none',
        isSelected: !props.assigneeId && !props.teamId,
      },
    ],
  },
  {
    title: t('TICKETS.TASKS.AGENTS'),
    items: agents.value.map(agent => ({
      label: agent.name,
      value: agent.id,
      action: 'agent',
      thumbnail: { name: agent.name, src: agent.thumbnail },
      isSelected: props.assigneeId === agent.id,
    })),
  },
  {
    title: t('TICKETS.TASKS.TEAMS'),
    items: teams.value.map(team => ({
      label: team.name,
      value: team.id,
      action: 'team',
      isSelected: props.teamId === team.id,
    })),
  },
]);

// A task is owned by one party: picking an agent clears the team and vice versa.
const onAction = ({ action, value }) => {
  isOpen.value = false;
  emit('select', {
    assignee_id: action === 'agent' ? value : null,
    team_id: action === 'team' ? value : null,
  });
};
</script>

<template>
  <OnClickOutside class="relative shrink-0" @trigger="isOpen = false">
    <Button
      variant="ghost"
      color="slate"
      size="xs"
      :disabled="disabled"
      class="max-w-32 !h-6 !px-1.5"
      :class="assigneeId || teamId ? 'text-n-slate-12' : 'text-n-slate-10'"
      @click="isOpen = !isOpen"
    >
      <template v-if="selectedAgent" #icon>
        <Avatar
          :src="selectedAgent.thumbnail"
          :name="selectedAgent.name"
          :size="14"
          rounded-full
        />
      </template>
      <span class="truncate">{{ label }}</span>
    </Button>
    <DropdownMenu
      v-if="isOpen"
      :menu-sections="menuSections"
      show-search
      class="z-20 mt-1 end-0 top-full w-52 max-h-72"
      @action="onAction"
    />
  </OnClickOutside>
</template>
