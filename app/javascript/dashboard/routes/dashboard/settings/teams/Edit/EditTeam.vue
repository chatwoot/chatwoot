<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('TEAMS_SETTINGS.ADD.AUTH.TITLE')"
      :header-content="$t('TEAMS_SETTINGS.ADD.AUTH.DESC')"
    />
    <div class="row channels">
      <team-form
        v-if="showTeamForm"
        :on-submit="updateTeam"
        :modal-title="null"
        :modal-description="null"
        :submit-in-progress="false"
        :submit-button-text="$t('TEAMS_SETTINGS.FORM.UPDATE')"
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
    account() {
      return this.$store.getters['accounts/getAccount'](this.accountId);
    },
    teamData() {
      const { team_id: teamId } = this.$route.params;
      return this.$store.getters['teams/getTeam'](teamId);
    },
    showTeamForm() {
      const { id } = this.teamData;
      return !!id;
    },
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
  },
  mounted() {
    this.initializeEnabledFeatures();
  },
  methods: {
    async initializeEnabledFeatures() {
      await this.$store.dispatch('accounts/get', this.accountId);
      this.enabledFeatures = this.account.features;
    },
    async updateTeam(data) {
      try {
        const { team_id: teamId } = this.$route.params;

        await this.$store.dispatch('teams/update', {
          id: teamId,
          ...data,
        });

        router.replace({
          name: 'settings_teams_edit_members',
          params: {
            page: 'edit',
            team_id: teamId,
          },
        });
      } catch (error) {
        this.showAlert(
          this.$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>
