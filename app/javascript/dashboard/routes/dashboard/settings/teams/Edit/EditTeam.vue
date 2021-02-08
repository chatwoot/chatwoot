<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('TEAMS_SETTINGS.EDIT_FLOW.CREATE.TITLE')"
      :header-content="$t('TEAMS_SETTINGS.EDIT_FLOW.CREATE.DESC')"
    />
    <div class="row channels">
      <team-form
        v-if="showTeamForm"
        :on-submit="updateTeam"
        :submit-in-progress="false"
        :submit-button-text="$t('TEAMS_SETTINGS.EDIT_FLOW.CREATE.BUTTON_TEXT')"
        :form-data="teamData"
      />
      <spinner v-else />
    </div>
  </div>
</template>

<script>
import TeamForm from '../TeamForm';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader';
import alertMixin from 'shared/mixins/alertMixin';

import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner';

export default {
  components: {
    TeamForm,
    PageHeader,
    Spinner,
  },
  mixins: [alertMixin],
  data() {
    return {
      enabledFeatures: {},
    };
  },
  computed: {
    teamData() {
      const { teamId } = this.$route.params;
      return this.$store.getters['teams/getTeam'](teamId);
    },
    showTeamForm() {
      const { id } = this.teamData;
      return id && !this.uiFlags.isFetching;
    },
    ...mapGetters({
      uiFlags: 'teams/getUIFlags',
    }),
  },
  methods: {
    async updateTeam(data) {
      try {
        const { teamId } = this.$route.params;

        await this.$store.dispatch('teams/update', {
          id: teamId,
          ...data,
        });

        router.replace({
          name: 'settings_teams_edit_members',
          params: {
            page: 'edit',
            teamId,
          },
        });
      } catch (error) {
        this.showAlert(this.$t('TEAMS_SETTINGS.TEAM_FORM.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
