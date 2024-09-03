<template>
  <div>
    <settings-section
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS_SUB_TEXT')"
    >
      <div class="w-full">
        <label>
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.AGENT_SELECTION') }}
        </label>
        <multiselect
          v-model="selectedAgents"
          :options="agentList"
          track-by="id"
          label="name"
          :multiple="true"
          :close-on-select="false"
          :clear-on-select="false"
          :hide-selected="true"
          :placeholder="
            $t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS_PLACEHOLDER')
          "
          selected-label
          :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
          :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
          @select="onAgentSelected"
        />
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

      <woot-submit-button
        :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
        :loading="isAgentListUpdating"
        @click="updateAgents"
      />
    </settings-section>

    <settings-section
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.AGENT_ASSIGNMENT')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.AGENT_ASSIGNMENT_SUB_TEXT')"
    >
      <label class="w-3/4 settings-item">
        <div class="flex items-center gap-2">
          <input
            id="enableAutoAssignment"
            v-model="enableAutoAssignment"
            type="checkbox"
            @change="handleEnableAutoAssignment"
          />
          <label for="enableAutoAssignment">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT') }}
          </label>
        </div>

        <p class="pb-1 text-sm not-italic text-slate-600 dark:text-slate-400">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT_SUB_TEXT') }}
        </p>
      </label>

      <div
        v-if="enableAutoAssignment && isEnterprise"
        class="max-assignment-container"
      >
        <woot-input
          v-model.trim="maxAssignmentLimit"
          type="number"
          :class="{ error: $v.maxAssignmentLimit.$error }"
          :error="maxAssignmentLimitErrors"
          :label="$t('INBOX_MGMT.AUTO_ASSIGNMENT.MAX_ASSIGNMENT_LIMIT')"
          @blur="$v.maxAssignmentLimit.$touch"
        />

        <p class="pb-1 text-sm not-italic text-slate-600 dark:text-slate-400">
          {{ $t('INBOX_MGMT.AUTO_ASSIGNMENT.MAX_ASSIGNMENT_LIMIT_SUB_TEXT') }}
        </p>

        <woot-submit-button
          :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
          :disabled="$v.maxAssignmentLimit.$invalid"
          @click="updateInbox"
        />
      </div>
    </settings-section>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { minValue } from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
import SettingsSection from '../../../../../components/SettingsSection.vue';
import StringeeChannelAPI from '../../../../../api/channel/stringeeChannel';

export default {
  components: {
    SettingsSection,
  },
  mixins: [alertMixin, configMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      selectedAgents: [],
      isAgentListUpdating: false,
      enableAutoAssignment: false,
      maxAssignmentLimit: null,
      selectedTeam: null,
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
      teamList: 'teams/getTeams',
    }),
    maxAssignmentLimitErrors() {
      if (this.$v.maxAssignmentLimit.$error) {
        return this.$t(
          'INBOX_MGMT.AUTO_ASSIGNMENT.MAX_ASSIGNMENT_LIMIT_RANGE_ERROR'
        );
      }
      return '';
    },
  },
  watch: {
    inbox() {
      this.setDefaults();
    },
  },
  mounted() {
    this.setDefaults();
  },
  methods: {
    setDefaults() {
      this.enableAutoAssignment = this.inbox.enable_auto_assignment;
      this.maxAssignmentLimit =
        this.inbox?.auto_assignment_config?.max_assignment_limit || null;
      this.selectedTeam = this.inbox?.team || null;
      this.fetchAttachedAgents();
    },
    async fetchAttachedAgents() {
      try {
        const response = await this.$store.dispatch('inboxMembers/get', {
          inboxId: this.inbox.id,
        });
        const {
          data: { payload: inboxMembers },
        } = response;
        this.selectedAgents = inboxMembers;
      } catch (error) {
        //  Handle error
      }
    },
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
    handleEnableAutoAssignment() {
      this.updateInbox();
    },
    async updateAgents() {
      const agentList = this.selectedAgents.map(el => el.id);
      this.isAgentListUpdating = true;
      try {
        if (this.inbox.channel_type === 'Channel::StringeePhoneCall') {
          await StringeeChannelAPI.updateAgents({
            inboxId: this.inbox.id,
            agentList,
          });
        }

        await this.$store.dispatch('inboxMembers/create', {
          inboxId: this.inbox.id,
          agentList,
          teamId: this.selectedTeam?.id,
        });
        this.showAlert(this.$t('AGENT_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('AGENT_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
      this.isAgentListUpdating = false;
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          enable_auto_assignment: this.enableAutoAssignment,
          auto_assignment_config: {
            max_assignment_limit: this.maxAssignmentLimit,
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      }
    },
  },
  validations: {
    selectedAgents: {
      isEmpty() {
        return !!this.selectedAgents.length;
      },
    },
    maxAssignmentLimit: {
      minValue: minValue(1),
    },
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';

.max-assignment-container {
  padding-top: var(--space-slab);
  padding-bottom: var(--space-slab);
}
</style>
