<template>
  <strong></strong>
</template>

<script>
export default {
  components: {},
  props: {
    agentList: {
      type: Array,
      default: () => [],
    },
    selectedAgents: {
      type: Array,
      default: () => [],
    },
    onSelectAgent: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {};
  },
  computed: {
    agentRowClass(agentId) {
      return { 'is-active': this.isAgentSelected(agentId) };
    },
  },
  methods: {
    isAgentSelected(agentId) {
      return this.selectedAgents.includes(agentId);
    },
    handleSelectAgent(agentId) {
      this.onSelectAgent(agentId);
    },
  },
};
</script>

<style scoped lang="scss"></style>
