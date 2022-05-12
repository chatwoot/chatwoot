<template>
  <div>
    <settings-section
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS_SUB_TEXT')"
    >
      <multiselect
        v-model="selectedAgents"
        :options="agentList"
        track-by="id"
        label="name"
        :multiple="true"
        :close-on-select="false"
        :clear-on-select="false"
        :hide-selected="true"
        placeholder="Pick some"
        selected-label
        :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
        :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
        @select="$v.selectedAgents.$touch"
      />

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
      <label class="medium-9 columns settings-item">
        <div class="enter-to-send--checkbox">
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

        <p class="help-text">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT_SUB_TEXT') }}
        </p>
      </label>
    </settings-section>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import SettingsSection from '../../../../../components/SettingsSection';

export default {
  components: {
    SettingsSection,
  },
  mixins: [alertMixin],
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
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
    }),
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
    handleEnableAutoAssignment() {
      this.updateInbox();
    },
    async updateAgents() {
      const agentList = this.selectedAgents.map(el => el.id);
      this.isAgentListUpdating = true;
      try {
        await this.$store.dispatch('inboxMembers/create', {
          inboxId: this.inbox.id,
          agentList,
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
  },
};
</script>
