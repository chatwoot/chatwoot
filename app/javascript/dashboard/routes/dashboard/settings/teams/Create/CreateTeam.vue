<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('TEAMS_SETTINGS.CREATE_FLOW.CREATE.TITLE')"
      :header-content="$t('TEAMS_SETTINGS.CREATE_FLOW.CREATE.DESC')"
    />
    <div class="row channels">
      <team-form
        :on-submit="createTeam"
        :submit-in-progress="false"
        :submit-button-text="$t('TEAMS_SETTINGS.FORM.SUBMIT_CREATE')"
      />
    </div>
  </div>
</template>

<script>
import TeamForm from '../TeamForm';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    TeamForm,
    PageHeader,
  },
  mixins: [alertMixin],
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
        this.showAlert(this.$t('TEAMS_SETTINGS.TEAM_FORM.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
