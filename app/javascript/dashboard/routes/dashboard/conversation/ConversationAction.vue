<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAgentsList } from 'dashboard/composables/useAgentsList';
import AgentAssignment from './AgentAssignment.vue';
import TeamAssignment from './TeamAssignment.vue';
import PriorityAssignment from './PriorityAssignment.vue';
import ParticipantAssignment from './ParticipantAssignment.vue';
import LabelAssignment from './LabelAssignment.vue';

defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { agentsList } = useAgentsList();

const teams = useMapGetter('teams/getTeams');

const teamsList = computed(() => teams.value);
</script>

<template>
  <div>
    <AgentAssignment :agents-list="agentsList" />
    <TeamAssignment :teams-list="teamsList" />
    <PriorityAssignment />
    <ParticipantAssignment :conversation-id="conversationId" />
    <LabelAssignment />
  </div>
</template>
