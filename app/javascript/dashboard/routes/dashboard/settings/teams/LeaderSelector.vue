<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <form
      class="flex flex-wrap flex-shrink-0 flex-grow-0 w-full md:w-[65%]"
      @submit.prevent="updateLeader"
    >
      <div class="w-full">
        <page-header
          :header-title="$t('TEAMS_SETTINGS.LEADER.TITLE')"
          :header-content="$t('TEAMS_SETTINGS.LEADER.DESC')"
        />
      </div>

      <div class="w-[50%]">
        <label>
          {{ $t('TEAMS_SETTINGS.LEADER.LABEL') }}
        </label>
        <multiselect
          v-model="leader"
          class="multiselect-wrap--small"
          placeholder=""
          label="name"
          track-by="id"
          :selected-label="$t('PIPELINE_PAGE.DROPDOWN.SELECTED_LABEL')"
          :select-label="$t('PIPELINE_PAGE.DROPDOWN.SELECT_LABEL')"
          :deselect-label="$t('PIPELINE_PAGE.DROPDOWN.DESELECT_LABEL')"
          :options="teamMembers"
          :max-height="160"
        />
      </div>

      <div class="w-full">
        <woot-submit-button
          :button-text="$t('TEAMS_SETTINGS.LEADER.BUTTON_TEXT')"
        />
      </div>
    </form>
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import router from '../../../index';
import PageHeader from '../SettingsSubPageHeader.vue';

export default {
  components: {
    PageHeader,
  },
  mixins: [alertMixin],

  data() {
    return {
      leader: null,
    };
  },

  computed: {
    teamId() {
      return this.$route.params.teamId;
    },
    teamMembers() {
      return this.$store.getters['teamMembers/getTeamMembers'](this.teamId);
    },
    currentTeam() {
      return this.$store.getters['teams/getTeam'](this.teamId);
    },
  },

  async mounted() {
    this.leader = this.currentTeam.leader;
  },

  methods: {
    async updateLeader() {
      try {
        await this.$store.dispatch('teams/updateLeader', {
          teamId: this.teamId,
          userId: this.leader?.id,
        });
        router.replace({
          name: 'settings_teams_edit_finish',
          params: {
            page: 'edit',
            teamId: this.teamId,
          },
        });
        this.$store.dispatch('teams/get');
      } catch (error) {
        this.showAlert(error.message);
      }
    },
  },
};
</script>
