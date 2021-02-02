<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('TEAMS_SETTINGS.ADD.AUTH.TITLE')"
      :header-content="$t('TEAMS_SETTINGS.ADD.AUTH.DESC')"
    />
    <div class="row channels">
      <team-form
        :on-submit="createTeam"
        :modal-title="null"
        :modal-description="null"
        :submit-in-progress="false"
        :submit-button-text="$t('TEAMS_SETTINGS.FORM.CREATE')"
      />
    </div>
  </div>
</template>

<script>
import TeamForm from '../TeamForm';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader';
import alertMixin from 'shared/mixins/alertMixin';

import { mapGetters } from 'vuex';

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
  computed: {
    account() {
      return this.$store.getters['accounts/getAccount'](this.accountId);
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
    async createTeam(data) {
      try {
        const team = await this.$store.dispatch('teams/create', {
          ...data,
        });

        router.replace({
          name: 'settings_teams_add_agents',
          params: {
            page: 'new',
            team_id: team.id,
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
