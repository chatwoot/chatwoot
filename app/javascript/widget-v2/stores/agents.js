import { defineStore } from 'pinia';
import { computed, ref } from 'vue';
import { fetchInboxMembers } from 'widget-v2/api/agents';

export const useAgentsStore = defineStore('agents', () => {
  const agents = ref([]);

  const onlineAgents = computed(() =>
    agents.value.filter(agent => agent.availability_status === 'online')
  );
  const hasOnlineAgents = computed(() => onlineAgents.value.length > 0);

  const load = async () => {
    if (agents.value.length) return;
    const { payload } = await fetchInboxMembers();
    agents.value = payload;
  };

  // presence.update cable payload carries { users: { <id>: 'online' | ... } }.
  const updatePresence = (users = {}) => {
    agents.value = agents.value.map(agent => ({
      ...agent,
      availability_status: users[agent.id] || 'offline',
    }));
  };

  return { agents, onlineAgents, hasOnlineAgents, load, updatePresence };
});
