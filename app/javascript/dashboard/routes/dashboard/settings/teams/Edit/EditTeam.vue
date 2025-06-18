<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';

import TeamForm from '../TeamForm.vue';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    TeamForm,
    PageHeader,
    Spinner,
  },
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
      :header-title="$t('TEAMS_SETTINGS.EDIT_FLOW.CREATE.TITLE')"
      :header-content="$t('TEAMS_SETTINGS.EDIT_FLOW.CREATE.DESC')"
    />
    <div class="flex flex-wrap">
      <TeamForm
        v-if="showTeamForm"
        :on-submit="updateTeam"
        :submit-in-progress="false"
        :submit-button-text="$t('TEAMS_SETTINGS.EDIT_FLOW.CREATE.BUTTON_TEXT')"
        :form-data="teamData"
      />
      <Spinner v-else />
    </div>
  </div>
</template>
