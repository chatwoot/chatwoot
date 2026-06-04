<template>
  <form class="mx-0 flex flex-wrap" @submit.prevent="createChannel()">
    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: v$.inboxName.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
        <input
          v-model.trim="inboxName"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.PLACEHOLDER')"
          @blur="v$.inboxName.$touch"
        />
        <span v-if="v$.inboxName.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
        </span>
      </label>
    </div>

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: v$.phoneNumber.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.LABEL') }}
        <input
          v-model.trim="phoneNumber"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.PLACEHOLDER')"
          @blur="v$.phoneNumber.$touch"
        />
        <span v-if="v$.phoneNumber.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.ERROR') }}
        </span>
      </label>
    </div>

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
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

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: v$.url.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.URL.LABEL') }}
        <input
          v-model.trim="url"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.URL.PLACEHOLDER')"
        />
        <span v-if="v$.url.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.URL.ERROR') }}
        </span>
      </label>
    </div>

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%] config-helptext">
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

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%] config-helptext">
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

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%] config-helptext">
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

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%] config-helptext">
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

    <div class="w-full" style="margin-top: 20px;">
      <woot-submit-button
        :loading="uiFlags.isCreating"
        :button-text="$t('INBOX_MGMT.ADD.WHATSAPP.SUBMIT_BUTTON')"
      />
      <woot-submit-button
        :loading="uiFlags.isUpdating"          
        :button-text="$t('INBOX_MGMT.ADD.WHATSAPP.GENERATE_API_KEY.LABEL')"
        @click="generateToken"
      /> 
    </div>    
  </form>
</template>

<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';

export default {
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      inboxName: '',
      phoneNumber: '',
      apiKey: '',
      url: 'https://unoapi.cloud',
      ignoreGroupMessages: true,
      ignoreHistoryMessages: true,
      sendAgentName: true,
      webhookSendNewMessages: true,
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required, isPhoneE164OrEmpty },
    apiKey: { required },
    ignoreGroupMessages: { required },
    ignoreHistoryMessages: { required },
    sendAgentName: { required },
    webhookSendNewMessages: { required },
    url: { required },
  },
  methods: {
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
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const whatsappChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.inboxName,
            channel: {
              type: 'whatsapp',
              phone_number: this.phoneNumber,
              provider: 'unoapi',
              provider_config: {
                api_key: this.apiKey,
                phone_number: this.phoneNumber,
                phone_number_id: this.phoneNumber.replace('+', ''),
                business_account_id: this.phoneNumber.replace('+', ''),
                ignore_history_messages: this.ignoreHistoryMessages,
                ignore_group_messages: this.ignoreGroupMessages,
                send_agent_name: this.sendAgentName,
                webhook_send_new_messages: this.webhookSendNewMessages,
                url: this.url,
              },
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: whatsappChannel.id,
          },
        });
      } catch (error) {
        useAlert(
          this.$t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE') +
            '\n detail:' +
            error
        );
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.switch {
  flex: 0 0 auto;
  margin-right: 10px;
}
.switch-label {
  display: flex;
  align-items: center;
}
</style>
