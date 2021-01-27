<template>
  <mention-box :items="items" @mention-select="handleMentionClick" />
</template>

<script>
import { mapGetters } from 'vuex';
import MentionBox from '../mentions/MentionBox.vue';

export default {
  components: { MentionBox },
  props: {
    searchKey: {
      type: String,
      default: '',
    },
  },
  computed: {
    ...mapGetters({
      agents: 'agents/getVerifiedAgents',
    }),
    items() {
      if (!this.searchKey) {
        return this.agents.map(agent => ({
          label: agent.name,
          key: agent.id,
          description: agent.email,
        }));
      }

      return this.agents
        .filter(agent =>
          agent.name
            .toLocaleLowerCase()
            .includes(this.searchKey.toLocaleLowerCase())
        )
        .map(agent => ({
          label: agent.name,
          key: agent.id,
          description: agent.email,
        }));
    },
  },
  methods: {
    handleMentionClick(item = {}) {
      this.$emit('click', item);
    },
  },
};
</script>
