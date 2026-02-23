<script>
import { mapGetters } from 'vuex';
import router from '../../../../index';
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import PageHeader from '../../SettingsSubPageHeader.vue';
import AgentSelector from '../AgentSelector.vue';

export default {
  components: {
    Spinner,
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
      uiFlags: 'teamMembers/getUIFlags',
    }),

    teamId() {
      return this.$route.params.teamId;
    },
    headerTitle() {
      return this.$t('TEAMS_SETTINGS.EDIT_FLOW.AGENTS.TITLE', {
        teamName: this.currentTeam.name,
      });
    },
    currentTeam() {
      return this.$store.getters['teams/getTeam'](this.teamId);
    },
    teamMembers() {
      return this.$store.getters['teamMembers/getTeamMembers'](this.teamId);
    },
    showAgentsList() {
      const { id } = this.currentTeam;
      return id && !this.uiFlags.isFetching;
    },
  },

  async mounted() {
    const { teamId } = this.$route.params;
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
  },

  methods: {
    updateSelectedAgents(newAgentList) {
      this.v$.selectedAgents.$touch();
      this.selectedAgents = [...newAgentList];
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
  <div class="h-full w-full p-8 col-span-6 overflow-auto">
    <form class="flex flex-col gap-4 mx-0" @submit.prevent="addAgents">
      <PageHeader
        :header-title="headerTitle"
        :header-content="$t('TEAMS_SETTINGS.EDIT_FLOW.AGENTS.DESC')"
      />

      <div class="w-full h-full">
        <div v-if="v$.selectedAgents.$error">
          <p class="error-message pb-2">
            {{ $t('TEAMS_SETTINGS.ADD.AGENT_VALIDATION_ERROR') }}
          </p>
        </div>
        <AgentSelector
          v-if="showAgentsList"
          :agent-list="agentList"
          :selected-agents="selectedAgents"
          :update-selected-agents="updateSelectedAgents"
          :is-working="isCreating"
          :submit-button-text="
            $t('TEAMS_SETTINGS.EDIT_FLOW.AGENTS.BUTTON_TEXT')
          "
        />
        <div v-else class="flex items-center justify-center py-6">
          <Spinner class="text-n-blue-11" />
        </div>
      </div>
    </form>
  </div>
</template>
