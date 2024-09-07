<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <form class="mx-0 flex flex-wrap" @submit.prevent="addAgents()">
      <div class="w-full">
        <page-header
          :header-title="$t('INBOX_MGMT.ADD.AGENTS.TITLE')"
          :header-content="$t('INBOX_MGMT.ADD.AGENTS.DESC')"
        />
      </div>
      <div class="w-3/5">
        <div class="w-full">
          <label>
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.AGENT_SELECTION') }}
            <multiselect
              v-model="selectedAgents"
              :options="agentList"
              track-by="id"
              label="name"
              :multiple="true"
              :close-on-select="false"
              :clear-on-select="false"
              :hide-selected="true"
              selected-label
              :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
              :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
              :placeholder="$t('INBOX_MGMT.ADD.AGENTS.PICK_AGENTS')"
              @select="onAgentSelected"
            />
          </label>
        </div>
        <div class="w-[50%]">
          <label>
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.TEAM_SELECTION') }}
          </label>
          <multiselect
            v-model="selectedTeam"
            placeholder=""
            label="name"
            track-by="id"
            :options="teamList"
            :max-height="160"
            :close-on-select="true"
            :show-labels="false"
            @select="onTeamSelected"
          />
        </div>
        <div class="w-full">
          <woot-submit-button
            :button-text="$t('INBOX_MGMT.AGENTS.BUTTON_TEXT')"
            :loading="isCreating"
          />
        </div>
      </div>
    </form>
  </div>
</template>

<script>
/* eslint no-console: 0 */
import { mapGetters } from 'vuex';

import alertMixin from 'shared/mixins/alertMixin';
import InboxMembersAPI from '../../../../api/inboxMembers';
import StringeeChannelAPI from '../../../../api/channel/stringeeChannel';
import router from '../../../index';
import PageHeader from '../SettingsSubPageHeader.vue';

export default {
  components: {
    PageHeader,
  },
  mixins: [alertMixin],
  validations: {
    selectedAgents: {
      isEmpty() {
        return !!this.selectedAgents.length;
      },
    },
  },

  data() {
    return {
      selectedAgents: [],
      isCreating: false,
      selectedTeam: null,
    };
  },

  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
      teamList: 'teams/getTeams',
    }),
  },

  mounted() {
    this.$store.dispatch('agents/get');
  },

  methods: {
    onAgentSelected() {
      if (!this.selectedTeam) return;
      this.showAlert(
        this.$t('INBOX_MGMT.SETTINGS_POPUP.AGENT_SELECTION_MESSAGE')
      );
      this.selectedTeam = null;
    },
    onTeamSelected() {
      if (this.selectedAgents.length === 0) return;
      this.showAlert(
        this.$t('INBOX_MGMT.SETTINGS_POPUP.TEAM_SELECTION_MESSAGE')
      );
      this.selectedAgents = [];
    },
    async addAgents() {
      this.isCreating = true;
      const inboxId = this.$route.params.inbox_id;
      const selectedAgents = this.selectedAgents.map(x => x.id);

      try {
        if (this.$route.params.channel_type === 'Channel::StringeePhoneCall') {
          await StringeeChannelAPI.updateAgents({
            inboxId,
            agentList: selectedAgents,
          });
        }

        await InboxMembersAPI.update({
          inboxId,
          agentList: selectedAgents,
          teamId: this.selectedTeam?.id,
        });
        router.replace({
          name: 'settings_inbox_finish',
          params: {
            page: 'new',
            inbox_id: this.$route.params.inbox_id,
          },
        });
      } catch (error) {
        bus.$emit('newToastMessage', error.message);
      }
      this.isCreating = false;
    },
  },
};
</script>
