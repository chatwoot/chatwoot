<template>
  <grouped-avatars :users="users" />
</template>

<script>
import GroupedAvatars from 'widget/components/GroupedAvatars.vue';

export default {
  name: 'AvailableAgents',
  components: { GroupedAvatars },
  props: {
    agents: {
      type: Array,
      default: () => [],
    },
  },
  computed: {
    users() {
      return this.agents.slice(0, 4).map(agent => ({
        id: agent.id,
        avatar: agent.avatar_url,
        name: agent.name,
      }));
    },
  },
};
</script>
