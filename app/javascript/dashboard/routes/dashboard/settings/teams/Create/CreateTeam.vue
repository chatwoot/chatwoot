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

<template>
  <div
    class="border border-n-weak bg-n-solid-1 rounded-t-lg border-b-0 h-full w-full p-6 col-span-6 overflow-auto"
  >
    <PageHeader
      :header-title="$t('TEAMS_SETTINGS.CREATE_FLOW.CREATE.TITLE')"
      :header-content="$t('TEAMS_SETTINGS.CREATE_FLOW.CREATE.DESC')"
    />
    <div class="flex flex-wrap">
      <TeamForm
        :on-submit="createTeam"
        :submit-in-progress="false"
        :submit-button-text="$t('TEAMS_SETTINGS.FORM.SUBMIT_CREATE')"
      />
    </div>
  </div>
</template>
