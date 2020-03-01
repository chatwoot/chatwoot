<template>
  <div class="settings columns container">
    <woot-modal-header
      :header-image="inbox.avatarUrl"
      :header-title="inbox.name"
    />
    <div
      v-if="inbox.channel_type === 'Channel::FacebookPage'"
      class="settings--content"
    >
      <settings-form-header
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_HEADING')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_SUB_HEAD')"
      >
      </settings-form-header>
      <woot-code :script="messengerScript"></woot-code>
    </div>
    <div v-else-if="inbox.channel_type === 'Channel::WebWidget'">
      <div class="settings--content">
        <settings-form-header
          :title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_HEADING')"
          :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_SUB_HEAD')"
        >
        </settings-form-header>
        <woot-code :script="webWidgetScript"></woot-code>
      </div>
      <div class="settings--content">
        <settings-form-header
          :title="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.WIDGET_COLOR.LABEL')"
          :sub-title="
            $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.WIDGET_COLOR.PLACEHOLDER')
          "
          :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
          :is-updating="uiFlags.isUpdating"
          @update="updateWidgetColor"
        >
        </settings-form-header>
        <Compact v-model="inbox.widget_color" class="widget-color--selector" />
      </div>
    </div>
    <div class="settings--content">
      <settings-form-header
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS_SUB_TEXT')"
        :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
        :is-updating="isAgentListUpdating"
        @update="updateAgents"
      >
      </settings-form-header>
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
        @select="$v.selectedAgents.$touch"
      />
    </div>
    <div class="settings--content">
      <settings-form-header
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.AUTO_ASSIGNMENT_SUB_TEXT')"
        :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
        :is-updating="uiFlags.isUpdatingAutoAssignment"
        @update="updateAutoAssignment"
      >
      </settings-form-header>
      <select v-model="autoAssignment">
        <option value="true">{{ $t('INBOX_MGMT.EDIT.AUTO_ASSIGNMENT.ENABLED') }}</option>
        <option value="false">{{ $t('INBOX_MGMT.EDIT.AUTO_ASSIGNMENT.DISABLED') }}</option>
      </select>
    </div>
  </div>
</template>

<script>
/* eslint no-console: 0 */
/* global bus */
import { mapGetters } from 'vuex';
import {
  createWebsiteWidgetScript,
  createMessengerScript,
} from 'dashboard/helper/scriptGenerator';
import { Compact } from 'vue-color';
import SettingsFormHeader from '../../../../components/SettingsFormHeader.vue';

export default {
  components: {
    Compact,
    SettingsFormHeader,
  },
  data() {
    return {
      selectedAgents: [],
      autoAssignment: false,
      isUpdating: false,
      isAgentListUpdating: false,
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
      uiFlags: 'inboxes/getUIFlags',
    }),
    currentInboxId() {
      return this.$route.params.inboxId;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.currentInboxId);
    },
    webWidgetScript() {
      return createWebsiteWidgetScript(this.inbox.website_token);
    },
    messengerScript() {
      return createMessengerScript(this.inbox.page_id);
    },
  },
  watch: {
    $route(to) {
      if (to.name === 'settings_inbox_show') {
        this.fetchInboxSettings();
      }
    },
  },
  mounted() {
    this.fetchInboxSettings();
  },
  methods: {
    showAlert(message) {
      bus.$emit('newToastMessage', message);
    },
    fetchInboxSettings() {
      this.selectedAgents = [];
      this.$store.dispatch('agents/get');
      this.$store.dispatch('inboxes/get').then(() => {
        this.fetchAttachedAgents();
        this.autoAssignment = this.inbox.enable_auto_assignment;
      });
    },
    async fetchAttachedAgents() {
      try {
        const response = await this.$store.dispatch('inboxMembers/get', {
          inboxId: this.currentInboxId,
        });
        const {
          data: { payload },
        } = response;
        payload.forEach(el => {
          const [item] = this.agentList.filter(
            agent => agent.id === el.user_id
          );
          if (item) {
            this.selectedAgents.push(item);
          }
        });
      } catch (error) {
        console.log(error);
      }
    },
    async updateAgents() {
      const agentList = this.selectedAgents.map(el => el.id);
      this.isAgentListUpdating = true;
      try {
        await this.$store.dispatch('inboxMembers/create', {
          inboxId: this.currentInboxId,
          agentList,
        });
        this.showAlert(this.$t('AGENT_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('AGENT_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
      this.isAgentListUpdating = false;
    },
    async updateWidgetColor() {
      try {
        await this.$store.dispatch('inboxes/updateWebsiteChannel', {
          id: this.inbox.channel_id,
          website: {
            widget_color: this.getWidgetColor(this.inbox.widget_color),
          },
        });
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      }
    },
    async updateAutoAssignment() {
      try {
        await this.$store.dispatch('inboxes/updateAutoAssignment', {
          id: this.currentInboxId,
          inbox: {
            enable_auto_assignment: this.autoAssignment,
          },
        });
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.AUTO_ASSIGNMENT_SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.AUTO_ASSIGNMENT_SUCCESS_MESSAGE'));
      }
    },
    getWidgetColor() {
      return typeof this.inbox.widget_color !== 'object'
        ? this.inbox.widget_color
        : this.inbox.widget_color.hex;
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
