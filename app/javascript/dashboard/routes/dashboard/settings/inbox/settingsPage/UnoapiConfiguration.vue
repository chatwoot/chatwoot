<template>
  <div class="my-2 mx-8 text-base">
    <form class="flex flex-col" @submit.prevent="updateInbox()">
      <div class="w-1/4">
        <label :class="{ error: v$.url.$error }">
          <span>
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.URL.LABEL') }}
          </span>
          <input
            v-model.trim="url"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.URL.PLACEHOLDER')"
            @blur="v$.url.$touch"
          />
          <span v-if="v$.url.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.URL.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-1/4">
        <label :class="{ error: v$.apiKey.$error }">
          <span>
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.LABEL') }}
          </span>
          <input
            v-model.trim="apiKey"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.PLACEHOLDER')"
            @blur="v$.apiKey.$touch"
          />
          <span v-if="v$.apiKey.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-1/4">
        <label :class="{ error: v$.wavoipToken.$error }">
          <span>
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.WAVOIP_TOKEN.LABEL') }}
          </span>
          <input
            v-model.trim="wavoipToken"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.WAVOIP_TOKEN.PLACEHOLDER')"
            @blur="v$.wavoipToken.$touch"
          />
          <span v-if="v$.wavoipToken.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.WAVOIP_TOKEN.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-1/4">
        <label :class="{ error: v$.rejectCalls.$error }">
          <span>
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.REJECT_CALLS.LABEL') }}
          </span>
          <input
            v-model.trim="rejectCalls"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.REJECT_CALLS.PLACEHOLDER')"
            @blur="v$.rejectCalls.$touch"
          />
          <span v-if="v$.rejectCalls.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.REJECT_CALLS.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-1/4">
        <label :class="{ error: v$.messageCallsWebhook.$error }">
          <span>
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.MESSAGE_CALLS_WEBHOOK.LABEL') }}
          </span>
          <input
            v-model.trim="messageCallsWebhook"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.MESSAGE_CALLS_WEBHOOK.PLACEHOLDER')"
            @blur="v$.messageCallsWebhook.$touch"
          />
          <span v-if="v$.messageCallsWebhook.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.MESSAGE_CALLS_WEBHOOK.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-3/4 pb-4 config-helptext">
        <label :class="{ error: v$.sendAgentName.$error }" style="display: flex; align-items: center;">
          <woot-switch
            v-model="sendAgentName"
            :value="sendAgentName"
            style="flex: 0 0 auto; margin-right: 10px;"
          />
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SEND_AGENT_NAME.LABEL') }}
          <span v-if="v$.sendAgentName.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.SEND_AGENT_NAME.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-3/4 pb-4 config-helptext">
        <label :class="{ error: v$.ignoreGroupMessages.$error }" style="display: flex; align-items: center;">
          <woot-switch
            v-model="ignoreGroupMessages"
            :value="ignoreGroupMessages"
            style="flex: 0 0 auto; margin-right: 10px;"
          />
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.IGNORE_GROUPS.LABEL') }}
          <span v-if="v$.ignoreGroupMessages.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.IGNORE_GROUPS.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-3/4 pb-4 config-helptext">
        <label :class="{ error: v$.ignoreHistoryMessages.$error }" style="display: flex; align-items: center;">
          <woot-switch
            v-model="ignoreHistoryMessages"
            :value="ignoreHistoryMessages"
            style="flex: 0 0 auto; margin-right: 10px;"
          />
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.IGNORE_HISTORY.LABEL') }}
          <span v-if="v$.ignoreHistoryMessages.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.IGNORE_HISTORY.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-3/4 pb-4 config-helptext">
        <label :class="{ error: v$.webhookSendNewMessages.$error }" style="display: flex; align-items: center;">
          <woot-switch
            v-model="webhookSendNewMessages"
            :value="webhookSendNewMessages"
            style="flex: 0 0 auto; margin-right: 10px;"
          />
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.WEBWOOK_SEND_NEW_MESSAGES.LABEL') }}
          <span v-if="v$.webhookSendNewMessages.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.WEBWOOK_SEND_NEW_MESSAGES.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-3/4 pb-4 config-helptext">
        <label :class="{ error: v$.ignoreBroadcastStatuses.$error }" style="display: flex; align-items: center;">
          <woot-switch
            v-model="ignoreBroadcastStatuses"
            :value="ignoreBroadcastStatuses"
            style="flex: 0 0 auto; margin-right: 10px;"
          />
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.IGNORE_BROADCAST_STATUSES.LABEL') }}
          <span v-if="v$.ignoreBroadcastStatuses.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.IGNORE_BROADCAST_STATUSES.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-3/4 pb-4 config-helptext">
        <label :class="{ error: v$.ignoreBroadcastMessages.$error }" style="display: flex; align-items: center;">
          <woot-switch
            v-model="ignoreBroadcastMessages"
            :value="ignoreBroadcastMessages"
            style="flex: 0 0 auto; margin-right: 10px;"
          />
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.IGNORE_BROADCAST_MESSAGES.LABEL') }}
          <span v-if="v$.ignoreBroadcastMessages.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.IGNORE_BROADCAST_MESSAGES.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-3/4 pb-4 config-helptext">
        <label :class="{ error: v$.ignoreOwnMessages.$error }" style="display: flex; align-items: center;">
          <woot-switch
            v-model="ignoreOwnMessages"
            :value="ignoreOwnMessages"
            style="flex: 0 0 auto; margin-right: 10px;"
          />
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.IGNORE_OWN_MESSAGES.LABEL') }}
          <span v-if="v$.ignoreOwnMessages.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.IGNORE_OWN_MESSAGES.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-3/4 pb-4 config-helptext">
        <label :class="{ error: v$.ignoreYourselfMessages.$error }" style="display: flex; align-items: center;">
          <woot-switch
            v-model="ignoreYourselfMessages"
            :value="ignoreYourselfMessages"
            style="flex: 0 0 auto; margin-right: 10px;"
          />
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.IGNORE_YOURSELF_MESSAGES.LABEL') }}
          <span v-if="v$.ignoreYourselfMessages.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.IGNORE_YOURSELF_MESSAGES.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-3/4 pb-4 config-helptext">
        <label :class="{ error: v$.sendConnectionStatus.$error }" style="display: flex; align-items: center;">
          <woot-switch
            v-model="sendConnectionStatus"
            :value="sendConnectionStatus"
            style="flex: 0 0 auto; margin-right: 10px;"
          />
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SEND_CONNECTION_STATUS.LABEL') }}
          <span v-if="v$.sendConnectionStatus.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.SEND_CONNECTION_STATUS.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-3/4 pb-4 config-helptext">
        <label :class="{ error: v$.notifyFailedMessages.$error }" style="display: flex; align-items: center;">
          <woot-switch
            v-model="notifyFailedMessages"
            :value="notifyFailedMessages"
            style="flex: 0 0 auto; margin-right: 10px;"
          />
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.NOTIFY_FAILED_MESSAGES.LABEL') }}
          <span v-if="v$.notifyFailedMessages.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.NOTIFY_FAILED_MESSAGES.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-3/4 pb-4 config-helptext">
        <label :class="{ error: v$.composingMessage.$error }" style="display: flex; align-items: center;">
          <woot-switch
            v-model="composingMessage"
            :value="composingMessage"
            style="flex: 0 0 auto; margin-right: 10px;"
          />
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.COMPOSING_MESSAGE.LABEL') }}
          <span v-if="v$.composingMessage.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.COMPOSING_MESSAGE.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-3/4 pb-4 config-helptext">
        <label :class="{ error: v$.sendReactionAsReply.$error }" style="display: flex; align-items: center;">
          <woot-switch
            v-model="sendReactionAsReply"
            :value="sendReactionAsReply"
            style="flex: 0 0 auto; margin-right: 10px;"
          />
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SEND_REACTION_AS_REPLY.LABEL') }}
          <span v-if="v$.sendReactionAsReply.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.SEND_REACTION_AS_REPLY.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-3/4 pb-4 config-helptext">
        <label :class="{ error: v$.sendProfilePicture.$error }" style="display: flex; align-items: center;">
          <woot-switch
            v-model="sendProfilePicture"
            :value="sendProfilePicture"
            style="flex: 0 0 auto; margin-right: 10px;"
          />
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SEND_PROFILE_PICTURE.LABEL') }}
          <span v-if="v$.sendProfilePicture.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.SEND_PROFILE_PICTURE.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-3/4 pb-4 config-helptext">
        <img v-if="qrcode" :src="qrcode" />
        <div v-if="notice">{{ notice }}</div>
      </div>

      <div class="my-4 w-auto">
        <woot-submit-button
          :loading="uiFlags.isUpdating"
          :button-text="`${$t(
          'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_BUTTON'
          )} and ${$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_CONNECT')}`"
          @click="connect = true"
        />
        <woot-submit-button
          :loading="uiFlags.isUpdating"
          :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_DISCONNECT')"
          @click="disconnect = true"
        />
        <woot-submit-button
          :loading="uiFlags.isUpdating"          
          :button-text="$t('INBOX_MGMT.ADD.WHATSAPP.GENERATE_API_KEY.LABEL')"
          @click="generateToken"
        />
      </div>
    </form>
  </div>
</template>

<script type="module">
import { io } from 'socket.io-client';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import inboxMixin from 'shared/mixins/inboxMixin';
import { required } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
// import { createConsumer } from '@rails/actioncable';

export default {
  setup() {
    return { v$: useVuelidate() };
  },
  components: {},
  mixins: [inboxMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      apiKey: '',
      wavoipToken: '',
      url: 'https://unoapi.cloud',
      ignoreGroupMessages: true,
      ignoreHistoryMessages: true,
      webhookSendNewMessages: true,
      sendAgentName: true,
      ignoreBroadcastStatuses: true,
      ignoreBroadcastMessages: true,
      ignoreOwnMessages: true,
      ignoreYourselfMessages: true,
      sendConnectionStatus: true,
      notifyFailedMessages: true,
      composingMessage: true,
      sendReactionAsReply: true,
      sendProfilePicture: true,       
      connect: false,
      disconnect: false,
      qrcode: '',
      notice: '',
      rejectCalls: '',
      messageCallsWebhook: '',      
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  validations: {
    apiKey: { required },
    ignoreGroupMessages: { required },
    ignoreHistoryMessages: { required },
    webhookSendNewMessages: { required },
    sendAgentName: { required },
    url: { required },
    ignoreBroadcastStatuses: { required },
    ignoreBroadcastMessages: { required },
    ignoreOwnMessages: { required },
    ignoreYourselfMessages: { required },
    sendConnectionStatus: { required },
    notifyFailedMessages: { required },
    composingMessage: { required },
    sendReactionAsReply: { required },
    sendProfilePicture: { required },
    rejectCalls: { required },
    messageCallsWebhook: { required },
    wavoipToken: { required },
  },
  watch: {
    inbox() {
      this.setDefaults();
    },
  },
  mounted() {
    this.setDefaults();
    this.listenerQrCode();
  },
  methods: {
    setDefaults() {
      this.apiKey = this.inbox.provider_config.api_key;
      this.wavoipToken = this.inbox.provider_config.wavoip_token;
      this.url = this.inbox.provider_config.url;
      this.ignoreGroupMessages = this.inbox.provider_config.ignore_group_messages;
      this.ignoreHistoryMessages = this.inbox.provider_config.ignore_history_messages;
      this.webhookSendNewMessages = this.inbox.provider_config.webhook_send_new_messages;
      this.sendAgentName = this.inbox.provider_config.send_agent_name;
      this.ignoreBroadcastStatuses = this.inbox.provider_config.ignore_broadcast_statuses;
      this.ignoreBroadcastMessages = this.inbox.provider_config.ignore_broadcast_messages;
      this.ignoreOwnMessages = this.inbox.provider_config.ignore_own_messages;
      this.ignoreYourselfMessages = this.inbox.provider_config.ignore_yourself_messages;
      this.sendConnectionStatus = this.inbox.provider_config.send_connection_status;
      this.notifyFailedMessages = this.inbox.provider_config.notify_failed_messages;
      this.composingMessage = this.inbox.provider_config.composing_message;
      this.sendReactionAsReply = this.inbox.provider_config.send_reaction_as_reply;
      this.sendProfilePicture = this.inbox.provider_config.send_profile_picture;
      this.rejectCalls = this.inbox.provider_config.reject_calls;
      this.messageCallsWebhook = this.inbox.provider_config.message_calls_webhook;
      this.connect = false;
      this.disconnect = false;
    },
    listenerQrCode() {
      const url = `${this.inbox.provider_config.url}`
        .replace('https', 'wss')
        .replace('http', 'ws');
      const socket = io(url, { path: '/ws' });
      socket.on('broadcast', data => {
        console.log('data', data)
        if (data.phone !== this.inbox.provider_config.phone_number_id) {
          this.notice = `Received message from ${data.phone} but the current number in chatwoot is ${this.inbox.provider_config.phone_number_id}`;
          this.qrcode = '';
          // broadcast phone is other
          return;
        }
        if (data.type === 'status') {
          this.notice = data.content;
          this.qrcode = '';
        } else if (data.type === 'qrcode') {
          this.qrcode = data.content;
          this.notice = '';
        }
      });
      // const url = `${this.inbox.provider_config.url}/ws`;
      // const cable = createConsumer(url);
      // cable.subscriptions.create(
      //   {
      //     channel: 'broadcast',
      //     phone_number: this.inbox.provider_config.phone_number_id,
      //   },
      //   {
      //     broadcast: data => {
      //       console.log('broadcast');
      //       this.qrcode = data;
      //     },
      //     connected: () => {
      //       console.log('connected');
      //       this.qrcode = 'waiting for qrcode';
      //     },
      //   }
      // );
    },
    generateToken() {
      const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
      let token = '';
      for (let i = 0; i < 64; i++) {
        token += characters.charAt(Math.floor(Math.random() * characters.length));
      }

      if (this.apiKey) {
        if (confirm('A token already exists. Do you want to replace it?')) {
          this.apiKey = token;
        }
      } else {
        this.apiKey = token;
      }
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            provider_config: {
              ...this.inbox.provider_config,
              api_key: this.apiKey,
              wavoip_token: this.wavoipToken,
              ignore_history_messages: this.ignoreHistoryMessages,
              ignore_group_messages: this.ignoreGroupMessages,
              send_agent_name: this.sendAgentName,
              webhook_send_new_messages: this.webhookSendNewMessages,
              url: this.url,
              ignore_broadcast_statuses: this.ignoreBroadcastStatuses,
              ignore_broadcast_messages: this.ignoreBroadcastMessages,
              ignore_own_messages: this.ignoreOwnMessages,
              ignore_yourself_messages: this.ignoreYourselfMessages,
              send_connection_status: this.sendConnectionStatus,
              notify_failed_messages: this.notifyFailedMessages,
              composing_message: this.composingMessage,
              send_reaction_as_reply: this.sendReactionAsReply,
              send_profile_picture: this.sendProfilePicture,
              reject_calls: this.rejectCalls,
              message_calls_webhook: this.messageCallsWebhook,              
              connect: this.connect,
              disconnect: this.disconnect,
            },
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.whatsapp-settings--content {
  ::v-deep input {
    margin-bottom: 0;
  }
}

.switch {
  flex: 0 0 auto;
  margin-right: 10px;
}

.switch-label {
  display: flex;
  align-items: center;
}

.flex-shrink div .messagingServiceHelptext{
 width:343px;
 max-width:343px;
 margin-bottom:8px;
}

.flex-shrink div .w-1\/4{
 min-width:700px;
 height:77px;
}

#app .flex .w-full{
 transform:translatex(0px) translatey(0px);
}

/* Config helptext */
#app .flex-grow-0 .overflow-hidden .justify-between .flex-shrink div .text-base .flex-col .config-helptext{
 width:100% !important;
}

.flex-shrink div .config-helptext{
 min-height:2px;
 height:30px;
}

.flex-shrink .messagingServiceHelptext label{
 width:204%;
 transform:translatex(0px) translatey(0px);
 position:relative;
 top:6px;
}

.flex-shrink .config-helptext div{
 margin-top:10px;
}

.flex-shrink div img{
 transform:translatex(407px) translatey(-347px);
 width:300px;
 height:300px;
}

.flex-shrink div .message{
 margin-top:-20px;
 font-size:11px;
}
</style>
