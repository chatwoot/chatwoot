<template>
  <woot-button variant="link" class="current-user" @click="handleClick">
    <thumbnail
      :src="currentUser.avatar_url"
      :username="currentUser.name"
      :status="statusOfAgent"
      should-show-status-always
      size="32px"
    />
  </woot-button>
</template>
<script>
import { mapGetters } from 'vuex';
import Thumbnail from '../../widgets/Thumbnail';

export default {
  components: {
    Thumbnail,
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      allAgents: 'agents/getAgents',
      currentRole: 'getCurrentRole',
    }),
    statusOfAgent() {
      const { id: currentAgentId } = this.currentUser;
      const agentInfo =
        this.allAgents.find(agent => agent.id === currentAgentId) || {};
      return agentInfo.availability_status;
    },
  },
  methods: {
    handleClick() {
      this.$emit('toggle-menu');
    },
  },
};
</script>

<style scoped lang="scss">
.current-user {
  align-items: center;
  display: flex;
  border-radius: 50%;
  border: 2px solid var(--white);
}
</style>
