<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';

import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
import AgentSelector from '../AgentSelector.vue';
import { useVuelidate } from '@vuelidate/core';

export default {
  components: {
    PageHeader,
    AgentSelector,
  },
  validations: {
    selectedAgents: {
      isEmpty() {
        return !!this.selectedAgents.length;
      },
    },
  },

  setup() {
    return { v$: useVuelidate() };
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
      this.v$.selectedAgents.$touch();
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
        useAlert(error.message);
      }
      this.isCreating = false;
    },
  },
};
</script>

<template>
  <div
    class="border border-n-weak bg-n-solid-1 rounded-t-lg border-b-0 h-full w-full p-6 col-span-6 overflow-auto"
  >
    <form
      class="flex flex-wrap mx-0 overflow-x-auto"
      @submit.prevent="addAgents"
    >
      <div class="w-full">
        <PageHeader
          :header-title="headerTitle"
          :header-content="$t('TEAMS_SETTINGS.ADD.DESC')"
        />
      </div>

      <div class="w-full">
        <div v-if="v$.selectedAgents.$error">
          <p class="error-message">
            {{ $t('TEAMS_SETTINGS.ADD.AGENT_VALIDATION_ERROR') }}
          </p>
        </div>
        <AgentSelector
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
