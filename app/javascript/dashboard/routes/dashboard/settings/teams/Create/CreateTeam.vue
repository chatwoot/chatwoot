<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <page-header
      :header-title="$t('TEAMS_SETTINGS.CREATE_FLOW.CREATE.TITLE')"
      :header-content="$t('TEAMS_SETTINGS.CREATE_FLOW.CREATE.DESC')"
    />
    <div class="flex flex-wrap">
      <team-form
        :on-submit="createTeam"
        :submit-in-progress="false"
        :submit-button-text="$t('TEAMS_SETTINGS.FORM.SUBMIT_CREATE')"
      />
    </div>
  </div>
</template>

<script>
import { useAlert } from 'dashboard/composables';
import TeamForm from '../TeamForm.vue';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';

export default {
  components: {
    TeamForm,
    PageHeader,
  },
  data() {
    return {
      enabledFeatures: {},
    };
  },
  methods: {
    async createTeam(data) {
      try {
        const team = await this.$store.dispatch('teams/create', {
          ...data,
        });

        router.replace({
          name: 'settings_teams_add_agents',
          params: {
            page: 'new',
            teamId: team.id,
          },
        });
      } catch (error) {
        useAlert(this.$t('TEAMS_SETTINGS.TEAM_FORM.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
