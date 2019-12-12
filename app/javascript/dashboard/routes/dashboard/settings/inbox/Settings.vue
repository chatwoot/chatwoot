<template>
  <woot-modal class-name="settings-modal" :show.sync="show" :on-close="onClose">
    <div class="settings">
      <woot-modal-header
        :header-image="inbox.avatarUrl"
        :header-title="inbox.label"
      />
      <div
        v-if="inbox.channelType === 'Channel::FacebookPage'"
        class="code-wrapper"
      >
        <p class="title">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_HEADING') }}
        </p>
        <p class="sub-head">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_SUB_HEAD') }}
        </p>
        <woot-code :script="messengerScript"></woot-code>
      </div>
      <div
        v-else-if="inbox.channelType === 'Channel::WebWidget'"
        class="code-wrapper"
      >
        <p class="title">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_HEADING') }}
        </p>
        <p class="sub-head">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_SUB_HEAD') }}
        </p>
        <woot-code :script="webWidgetScript"></woot-code>
      </div>
      <div class="agent-wrapper">
        <p class="title">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS') }}
        </p>
        <p class="sub-head">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.INBOX_AGENTS_SUB_TEXT') }}
        </p>
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
        <div @click="updateAgents()">
          <woot-submit-button
            :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
            :loading="isUpdating"
          />
        </div>
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

export default {
  props: ['onClose', 'inbox', 'show'],
  data() {
    return {
      selectedAgents: [],
      isUpdating: false,
    };
  },
  computed: {
    ...mapGetters({
      agentList: 'getAgents',
    }),
    webWidgetScript() {
      return createWebsiteWidgetScript(this.inbox.websiteToken);
    },
    messengerScript() {
      return createMessengerScript(this.inbox.pageId);
    },
  },
  mounted() {
    this.$store.dispatch('fetchAgents').then(() => {
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
