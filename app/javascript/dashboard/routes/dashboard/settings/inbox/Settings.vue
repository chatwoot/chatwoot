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
          :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS_SUB_TEXT')"
          :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
          :is-updating="isUpdating"
          @update="updateAgents"
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
        :is-updating="isUpdating"
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
  </div>
</template>

<script>
/* eslint no-console: 0 */
/* eslint-disable no-useless-escape */
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
      isUpdating: false,
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
    }),
    currentInboxId() {
      return this.$route.params.inboxId;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](
        Number(this.currentInboxId)
      );
    },
    webWidgetScript() {
      return createWebsiteWidgetScript(this.inbox.website_token);
    },
    messengerScript() {
      return createMessengerScript(this.inbox.pageId);
    },
  },
  mounted() {
    this.$store.dispatch('agents/get');
    this.$store.dispatch('inboxes/get').then(() => {
      this.fetchAttachedAgents();
    });
  },
  methods: {
    async fetchAttachedAgents() {
      try {
        const {
          data: { payload },
        } = await this.$store.dispatch('listInboxAgents', {
          inboxId: this.currentInboxId,
        });
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
      this.isUpdating = true;
      try {
        await this.$store.dispatch('updateInboxAgents', {
          inboxId: this.currentInboxId,
          agentList,
        });
        bus.$emit(
          'newToastMessage',
          this.$t('AGENT_MGMT.EDIT.API.SUCCESS_MESSAGE')
        );
      } catch (error) {
        bus.$emit(
          'newToastMessage',
          this.$t('AGENT_MGMT.EDIT.API.ERROR_MESSAGE')
        );
      }
      this.isUpdating = false;
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
