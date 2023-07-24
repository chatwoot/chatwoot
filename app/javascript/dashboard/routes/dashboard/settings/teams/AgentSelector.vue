<template>
  <div>
    <div class="add-agents__header" />
    <table class="woot-table">
      <thead>
        <tr>
          <td>
            <div class="checkbox-wrap">
              <input
                name="select-all-agents"
                type="checkbox"
                :checked="allAgentsSelected ? 'checked' : ''"
                :title="$t('TEAMS_SETTINGS.AGENTS.SELECT_ALL')"
                @click.self="selectAllAgents"
              />
            </div>
          </td>
          <td>{{ $t('TEAMS_SETTINGS.AGENTS.AGENT') }}</td>
          <td>{{ $t('TEAMS_SETTINGS.AGENTS.EMAIL') }}</td>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="agent in agentList"
          :key="agent.id"
          :class="agentRowClass(agent.id)"
        >
          <td class="checkbox-cell">
            <div class="checkbox-wrap">
              <input
                type="checkbox"
                :checked="isAgentSelected(agent.id)"
                @click.self="() => handleSelectAgent(agent.id)"
              />
            </div>
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
    <div class="add-agents__footer">
      <p>
        {{
          $t('TEAMS_SETTINGS.AGENTS.SELECTED_COUNT', {
            selected: selectedAgents.length,
            total: agentList.length,
          })
        }}
      </p>
      <woot-submit-button
        :button-text="submitButtonText"
        :loading="isWorking"
        :disabled="disableSubmitButton"
      />
    </div>
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
    isWorking: {
      type: Boolean,
      default: false,
    },
    submitButtonText: {
      type: String,
      default: '',
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
    disableSubmitButton() {
      return this.selectedAgentCount === 0;
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
  margin-left: var(--space-small);
}

.add-agents__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.checkbox-wrap {
  display: flex;
  align-items: center;

  input {
    margin: 0;
  }
}
.checkbox-cell {
  width: var(--space-larger);
}
</style>
