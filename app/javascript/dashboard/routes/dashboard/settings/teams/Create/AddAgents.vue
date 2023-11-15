<template>
  <div
    class="wizard-body w-[75%] flex-shrink-0 flex-grow-0 max-w-[75%] overflow-y-auto"
  >
    <form class="mx-0 flex flex-wrap" @submit.prevent="addAgents">
      <div class="w-full">
        <page-header
          :header-title="headerTitle"
          :header-content="$t('TEAMS_SETTINGS.ADD.DESC')"
        />
      </div>

      <div class="w-full">
        <div v-if="$v.selectedAgents.$error">
          <p class="error-message">
            {{ $t('TEAMS_SETTINGS.ADD.AGENT_VALIDATION_ERROR') }}
          </p>
        </div>
        <agent-selector
          :agent-list="agentList"
          :selected-agents="selectedAgents"
          :update-selected-agents="updateSelectedAgents"
          :is-working="isCreating"
          :submit-button-text="$t('TEAMS_SETTINGS.ADD.BUTTON_TEXT')"
        />
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import alertMixin from 'shared/mixins/alertMixin';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
import AgentSelector from '../AgentSelector.vue';

export default {
  components: {
    PageHeader,
    AgentSelector,
  },
  mixins: [alertMixin],
  props: {
    team: {
      type: Object,
      default: () => {},
    },
  },
  validations: {
    selectedAgents: {
      isEmpty() {
        return !!this.selectedAgents.length;
      },
    },
  },

  data() {
    return {
      selectedAgents: [],
      isCreating: false,
    };
  },

  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
    }),

    teamId() {
      return this.$route.params.teamId;
    },
    headerTitle() {
      return this.$t('TEAMS_SETTINGS.ADD.TITLE', {
        teamName: this.currentTeam.name,
      });
    },
    currentTeam() {
      return this.$store.getters['teams/getTeam'](this.teamId);
    },
  },

  mounted() {
    this.$store.dispatch('agents/get');
  },

  methods: {
    updateSelectedAgents(newAgentList) {
      this.$v.selectedAgents.$touch();
      this.selectedAgents = [...newAgentList];
    },
    selectAllAgents() {
      this.selectedAgents = this.agentList.map(agent => agent.id);
    },
    async addAgents() {
      this.isCreating = true;
      const { teamId, selectedAgents } = this;

      try {
        await this.$store.dispatch('teamMembers/create', {
          teamId,
          agentsList: selectedAgents,
        });
        router.replace({
          name: 'settings_teams_finish',
          params: {
            page: 'new',
            teamId,
          },
        });
        this.$store.dispatch('teams/get');
      } catch (error) {
        this.showAlert(error.message);
      }
      this.isCreating = false;
    },
  },
};
</script>
