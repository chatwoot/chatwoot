<template>
  <div>
    <div class="table__meta">
      <p>
        {{
          $t('TEAMS_SETTINGS.AGENTS.SELECTED_COUNT', {
            selected: selectedAgents.length,
            total: agentList.length,
          })
        }}
      </p>
      <label @click="selectAllAgents">
        <input
          name="select-all-agents"
          type="checkbox"
          :checked="allAgentsSelected ? 'checked' : ''"
        />
        {{ $t('TEAMS_SETTINGS.AGENTS.SELECT_ALL') }}
      </label>
    </div>
    <table class="woot-table">
      <thead></thead>
      <tbody>
        <tr
          v-for="agent in agentList"
          :key="agent.id"
          :class="agentRowClass(agent.id)"
        >
          <td>
            <input
              type="checkbox"
              :checked="isAgentSelected(agent.id)"
              @click.self="() => handleSelectAgent(agent.id)"
            />
          </td>
          <td>
            <div class="user-info-wrap">
              <thumbnail
                :src="agent.thumbnail"
                size="24px"
                :username="agent.name"
                :status="agent.availability_status"
              />
              <h4 class="sub-block-title user-name">
                {{ agent.name }}
              </h4>
            </div>
          </td>
          <td>
            {{ agent.email || '---' }}
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  components: {
    Thumbnail,
  },
  props: {
    agentList: {
      type: Array,
      default: () => [],
    },
    selectedAgents: {
      type: Array,
      default: () => [],
    },
    updateSelectedAgents: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {};
  },
  computed: {
    selectedAgentCount() {
      return this.selectedAgents.length;
    },
    allAgentsSelected() {
      return this.selectedAgents.length === this.agentList.length;
    },
  },
  methods: {
    isAgentSelected(agentId) {
      return this.selectedAgents.includes(agentId);
    },
    handleSelectAgent(agentId) {
      const shouldRemove = this.isAgentSelected(agentId);

      let result = [];
      if (shouldRemove) {
        result = this.selectedAgents.filter(item => item !== agentId);
      } else {
        result = [...this.selectedAgents, agentId];
      }

      this.updateSelectedAgents(result);
    },
    selectAllAgents() {
      const result = this.agentList.map(item => item.id);
      this.updateSelectedAgents(result);
    },
    agentRowClass(agentId) {
      return { 'is-active': this.isAgentSelected(agentId) };
    },
  },
};
</script>

<style scoped lang="scss">
.table__meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--space-small);
}

.user-info-wrap {
  display: flex;
  align-items: center;
}

.user-name {
  margin-bottom: 0;
  margin-left: var(--space-smaller);
}
</style>
