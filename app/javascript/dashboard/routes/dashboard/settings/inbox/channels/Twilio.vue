<!-- Deprecated in favour of separate files for SMS and Whatsapp and also to implement new providers for each platform in the future-->
<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';

export default {
  props: {
    type: {
      type: String,
      required: true,
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      accountSID: '',
      apiKeySID: '',
      authToken: '',
      medium: this.type,
      channelName: '',
      messagingServiceSID: '',
      useMessagingService: false,
      useAPIKey: false,
      phoneNumber: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
    authTokeni18nKey() {
      return this.useAPIKey ? 'API_KEY_SECRET' : 'AUTH_TOKEN';
    },
  },
  validations() {
    let validations = {
      channelName: { required },

      authToken: { required },
      accountSID: { required },
      medium: { required },
    };
    if (this.phoneNumber) {
      validations = {
        ...validations,
        phoneNumber: { required, isPhoneE164OrEmpty },
        messagingServiceSID: {},
      };
    } else {
      validations = {
        ...validations,
        messagingServiceSID: { required },
        phoneNumber: {},
      };
    }

    if (this.useAPIKey) {
      validations = {
        ...validations,
        apiKeySID: { required },
      };
    }
    return validations;
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const twilioChannel = await this.$store.dispatch(
          'inboxes/createTwilioChannel',
          {
            twilio_channel: {
              name: this.channelName,
              medium: this.medium,
              account_sid: this.accountSID,
              api_key_sid: this.apiKeySID,
              auth_token: this.authToken,
              messaging_service_sid: this.messagingServiceSID,
              phone_number: this.messagingServiceSID
                ? null
                : `+${this.phoneNumber.replace(/\D/g, '')}`,
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: twilioChannel.id,
          },
        });
      } catch (error) {
        const errorMessage =
          parseAPIErrorResponse(error) ||
          this.$t('INBOX_MGMT.ADD.TWILIO.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
  },
};
</script>

<template>
  <form class="flex flex-wrap mx-0" @submit.prevent="createChannel()">
    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: v$.channelName.$error }">
        {{ $t('INBOX_MGMT.ADD.TWILIO.CHANNEL_NAME.LABEL') }}
        <input
          v-model="channelName"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.TWILIO.CHANNEL_NAME.PLACEHOLDER')"
          @blur="v$.channelName.$touch"
        />
        <span v-if="v$.channelName.$error" class="message">{{
          $t('INBOX_MGMT.ADD.TWILIO.CHANNEL_NAME.ERROR')
        }}</span>
      </label>
    </div>

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label
        v-if="useMessagingService"
        :class="{ error: v$.messagingServiceSID.$error }"
      >
        {{ $t('INBOX_MGMT.ADD.TWILIO.MESSAGING_SERVICE_SID.LABEL') }}
        <input
          v-model="messagingServiceSID"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.TWILIO.MESSAGING_SERVICE_SID.PLACEHOLDER')
          "
          @blur="v$.messagingServiceSID.$touch"
        />
        <span v-if="v$.messagingServiceSID.$error" class="message">{{
          $t('INBOX_MGMT.ADD.TWILIO.MESSAGING_SERVICE_SID.ERROR')
        }}</span>
      </label>
    </div>

    <div
      v-if="!useMessagingService"
      class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]"
    >
      <label :class="{ error: v$.phoneNumber.$error }">
        {{ $t('INBOX_MGMT.ADD.TWILIO.PHONE_NUMBER.LABEL') }}
        <input
          v-model="phoneNumber"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.TWILIO.PHONE_NUMBER.PLACEHOLDER')"
          @blur="v$.phoneNumber.$touch"
        />
        <span v-if="v$.phoneNumber.$error" class="message">{{
          $t('INBOX_MGMT.ADD.TWILIO.PHONE_NUMBER.ERROR')
        }}</span>
      </label>
    </div>

    <div class="max-w-[65%] w-full messagingServiceHelptext">
      <label for="useMessagingService">
        <input
          id="useMessagingService"
          v-model="useMessagingService"
          type="checkbox"
          class="checkbox"
        />
        {{
          $t(
            'INBOX_MGMT.ADD.TWILIO.MESSAGING_SERVICE_SID.USE_MESSAGING_SERVICE'
          )
        }}
      </label>
    </div>

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: v$.accountSID.$error }">
        {{ $t('INBOX_MGMT.ADD.TWILIO.ACCOUNT_SID.LABEL') }}
        <input
          v-model="accountSID"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.TWILIO.ACCOUNT_SID.PLACEHOLDER')"
          @blur="v$.accountSID.$touch"
        />
        <span v-if="v$.accountSID.$error" class="message">{{
          $t('INBOX_MGMT.ADD.TWILIO.ACCOUNT_SID.ERROR')
        }}</span>
      </label>
    </div>
    <div class="max-w-[65%] w-full messagingServiceHelptext">
      <label for="useAPIKey">
        <input
          id="useAPIKey"
          v-model="useAPIKey"
          type="checkbox"
          class="checkbox"
        />
        {{ $t('INBOX_MGMT.ADD.TWILIO.API_KEY.USE_API_KEY') }}
      </label>
    </div>
    <div v-if="useAPIKey" class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: v$.apiKeySID.$error }">
        {{ $t('INBOX_MGMT.ADD.TWILIO.API_KEY.LABEL') }}
        <input
          v-model="apiKeySID"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.TWILIO.API_KEY.PLACEHOLDER')"
          @blur="v$.apiKeySID.$touch"
        />
        <span v-if="v$.apiKeySID.$error" class="message">{{
          $t('INBOX_MGMT.ADD.TWILIO.API_KEY.ERROR')
        }}</span>
      </label>
    </div>
    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: v$.authToken.$error }">
        {{ $t(`INBOX_MGMT.ADD.TWILIO.${authTokeni18nKey}.LABEL`) }}
        <input
          v-model="authToken"
          type="text"
          :placeholder="
            $t(`INBOX_MGMT.ADD.TWILIO.${authTokeni18nKey}.PLACEHOLDER`)
          "
          @blur="v$.authToken.$touch"
        />
        <span v-if="v$.authToken.$error" class="message">
          {{ $t(`INBOX_MGMT.ADD.TWILIO.${authTokeni18nKey}.ERROR`) }}
        </span>
      </label>
    </div>

    <div class="w-full">
      <woot-submit-button
        :loading="uiFlags.isCreating"
        :button-text="$t('INBOX_MGMT.ADD.TWILIO.SUBMIT_BUTTON')"
      />
    </div>
  </form>
</template>

<style lang="scss" scoped>
.messagingServiceHelptext {
  margin-top: -10px;
  margin-bottom: 15px;

  .checkbox {
    margin: 0px 4px;
  }
}
</style>
