<template>
  <div class="wizard-body columns content-box small-9">
    <form class="row" @submit.prevent="addAgents()">
      <div class="medium-12 columns">
        <page-header
          :header-title="headerTitle"
          :header-content="$t('TEAMS_SETTINGS.EDIT.DESC')"
        />
      </div>

      <div class="medium-12 columns">
        <label :class="{ error: $v.selectedAgents.$error }">
          <span v-if="$v.selectedAgents.$error" class="message">
            {{ $t('TEAMS_SETTINGS.ADD.AGENTS.VALIDATION_ERROR') }}
          </span>
        </label>
        <agent-selector
          :agent-list="agentList"
          :selected-agents="selectedAgents"
          :update-selected-agents="updateSelectedAgents"
          :is-working="isCreating"
          :submit-button-text="$t('TEAMS_SETTINGS.AGENTS.EDIT.BUTTON_TEXT')"
        />
      </div>
    </form>
  </div>
</template>

<script>
/* eslint no-console: 0 */
import { mapGetters } from 'vuex';

import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader';
import AgentSelector from '../AgentSelector';

export default {
  components: {
    PageHeader,
    AgentSelector,
  },

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
      uiFlags: 'teamMembers/getUIFlags',
    }),

    teamId() {
      return this.$route.params.team_id;
    },
    headerTitle() {
      return this.$t('TEAMS_SETTINGS.EDIT.TITLE', {
        teamName: this.currentTeam.name,
      });
    },
    currentTeam() {
      return this.$store.getters['teams/getTeam'](this.teamId);
    },
    teamMembers() {
      return this.$store.getters['teamMembers/getTeamMembers'](this.teamId);
    },
  },

  async mounted() {
    const { team_id: teamId } = this.$route.params;
    this.$store.dispatch('agents/get');
    try {
      await this.$store.dispatch('teamMembers/get', {
        teamId,
      });
      const members = this.teamMembers.map(item => item.id);
      this.updateSelectedAgents(members);
    } catch {
      this.updateSelectedAgents([]);
    }
    console.log(this.teamMembers);
  },

  methods: {
    updateSelectedAgents(newAgentList) {
      this.selectedAgents = [...newAgentList];
    },
    selectAllAgents() {
      this.selectedAgents = this.agentList.map(agent => agent.id);
    },
    async addAgents() {
      this.isCreating = true;
      const { teamId, selectedAgents } = this;

      try {
        await this.$store.dispatch('teamMembers/update', {
          teamId,
          agentsList: selectedAgents,
        });
        router.replace({
          name: 'settings_teams_edit_finish',
          params: {
            page: 'edit',
            team_id: this.$route.params.team_id,
          },
        });
      } catch (error) {
        bus.$emit('newToastMessage', error.message);
      }
      this.isCreating = false;
    },
  },
};
</script>
