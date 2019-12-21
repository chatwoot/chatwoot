<template>
  <woot-modal class-name="settings-modal" :show.sync="show" :on-close="onClose">
    <div class="settings">
      <woot-modal-header
        :header-image="inbox.avatarUrl"
        :header-title="inbox.label"
      />
      <div
        v-if="inbox.channelType === 'Channel::FacebookPage'"
        class="settings--content"
      >
        <settings-form-header
          :title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_HEADING')"
          :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_SUB_HEAD')"
        >
        </settings-form-header>
        <woot-code :script="messengerScript"></woot-code>
      </div>
      <div v-else-if="inbox.channelType === 'Channel::WebWidget'">
        <div class="settings--content">
          <settings-form-header
            :title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_HEADING')"
            :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_SUB_HEAD')"
          >
          </settings-form-header>
          <woot-code :script="webWidgetScript"></woot-code>
        </div>
        <!-- <div class="settings--content">
          <settings-form-header
            :title="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.WIDGET_COLOR.LABEL')"
            :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS_SUB_TEXT')"
            :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
            :is-updating="isUpdating"
            v-on:update="updateAgents"
          >
          </settings-form-header>
          <Compact v-model="widgetColor" />
        </div> -->
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
  </woot-modal>
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
import SettingsFormHeader from '../../../../components/SettingsFormHeader.vue';

export default {
  components: {
    SettingsFormHeader,
  },
  props: ['onClose', 'inbox', 'show'],
  data() {
    return {
      selectedAgents: [],
      isUpdating: false,
      widgetColor: { hex: this.inbox.widgetColor },
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
    }),
    webWidgetScript() {
      return createWebsiteWidgetScript(this.inbox.websiteToken);
    },
    messengerScript() {
      return createMessengerScript(this.inbox.pageId);
    },
  },
  mounted() {
    this.$store.dispatch('agents/get').then(() => {
      this.fetchAttachedAgents();
    });
  },
  methods: {
    fetchAttachedAgents() {
      this.$store
        .dispatch('listInboxAgents', {
          inboxId: this.inbox.channel_id,
        })
        .then(response => {
          const { payload } = response.data;
          payload.forEach(el => {
            const [item] = this.agentList.filter(
              agent => agent.id === el.user_id
            );
            if (item) this.selectedAgents.push(item);
          });
        })
        .catch(error => {
          console.log(error);
        });
    },
    updateAgents() {
      const agentList = this.selectedAgents.map(el => el.id);
      this.isUpdating = true;
      this.$store
        .dispatch('updateInboxAgents', {
          inboxId: this.inbox.channel_id,
          agentList,
        })
        .then(() => {
          this.isUpdating = false;
          bus.$emit(
            'newToastMessage',
            this.$t('AGENT_MGMT.EDIT.API.SUCCESS_MESSAGE')
          );
        })
        .catch(() => {
          this.isUpdating = false;
          bus.$emit(
            'newToastMessage',
            this.$t('AGENT_MGMT.EDIT.API.ERROR_MESSAGE')
          );
        });
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
