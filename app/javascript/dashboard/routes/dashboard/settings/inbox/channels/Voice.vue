<script>
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { mapGetters } from 'vuex';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
// Using a regex validator for phone numbers
const validPhoneNumber = value => {
  if (!value) return true;
  return /^\+[1-9]\d{1,14}$/.test(value);
};

export default {
  components: {
    PageHeader,
    NextButton,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      provider: 'twilio',
      phoneNumber: '',
      accountSid: '',
      authToken: '',
      apiKeySid: '',
      apiKeySecret: '',
      twimlAppSid: '',
      providerOptions: [
        { value: 'twilio', label: 'Twilio' },
        // Add more providers as needed
        // { value: 'other_provider', label: 'Other Provider' },
      ],
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations() {
    return {
      phoneNumber: {
        required,
        validPhoneNumber,
      },
      accountSid: {
        required: this.provider === 'twilio',
      },
      authToken: {
        required: this.provider === 'twilio',
      },
      apiKeySid: {
        required: this.provider === 'twilio',
      },
      apiKeySecret: {
        required: this.provider === 'twilio',
      },
      // TwiML App SID is not required, but if provided it must follow Twilio's format
      twimlAppSid: {
        // Optional - will not be required
      },
    };
  },
  methods: {
    onProviderChange() {
      // Reset fields when provider changes
      this.v$.$reset();
    },
    getProviderConfig() {
      if (this.provider === 'twilio') {
        const config = {
          account_sid: this.accountSid,
          auth_token: this.authToken,
          api_key_sid: this.apiKeySid,
          api_key_secret: this.apiKeySecret,
        };
        
        // Add the TwiML App SID if provided
        if (this.twimlAppSid) {
          config.outgoing_application_sid = this.twimlAppSid;
        }
        
        return config;
      }
      // Add handler for other providers here
      return {};
    },
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const providerConfig = this.getProviderConfig();

        const channel = await this.$store.dispatch(
          'inboxes/createVoiceChannel',
          {
            voice: {
              name: `Voice (${this.phoneNumber})`,
              phone_number: this.phoneNumber,
              provider: this.provider,
              provider_config: JSON.stringify(providerConfig),
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: channel.id,
          },
        });
      } catch (error) {
        useAlert(
          error.response?.data?.message ||
            this.$t('INBOX_MGMT.ADD.VOICE.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <div>
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.VOICE.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.VOICE.DESC')"
    />

    <form
      class="flex flex-wrap flex-col gap-4 p-2"
      @submit.prevent="createChannel"
    >
      <div class="flex-shrink-0 flex-grow-0">
        <label>
          {{ $t('INBOX_MGMT.ADD.VOICE.PROVIDER.LABEL') }}
          <select
            v-model="provider"
            class="p-2 bg-white border border-n-blue-100 rounded"
            @change="onProviderChange"
          >
            <option
              v-for="option in providerOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>
      </div>

      <!-- Twilio Provider Config -->
      <div v-if="provider === 'twilio'" class="flex-shrink-0 flex-grow-0">
        <div class="flex-shrink-0 flex-grow-0">
          <label :class="{ error: v$.phoneNumber.$error }">
            {{ $t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBER.LABEL') }}
            <input
              v-model.trim="phoneNumber"
              type="text"
              :placeholder="$t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBER.PLACEHOLDER')"
              @blur="v$.phoneNumber.$touch"
            />
            <span v-if="v$.phoneNumber.$error" class="message">
              {{ $t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBER.ERROR') }}
            </span>
          </label>
        </div>

        <div class="flex-shrink-0 flex-grow-0">
          <label :class="{ error: v$.accountSid.$error }">
            {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.ACCOUNT_SID.LABEL') }}
            <input
              v-model.trim="accountSid"
              type="text"
              :placeholder="
                $t('INBOX_MGMT.ADD.VOICE.TWILIO.ACCOUNT_SID.PLACEHOLDER')
              "
              @blur="v$.accountSid.$touch"
            />
            <span v-if="v$.accountSid.$error" class="message">
              {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.ACCOUNT_SID.REQUIRED') }}
            </span>
          </label>
        </div>

        <div class="flex-shrink-0 flex-grow-0">
          <label :class="{ error: v$.authToken.$error }">
            {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.AUTH_TOKEN.LABEL') }}
            <input
              v-model.trim="authToken"
              type="text"
              :placeholder="
                $t('INBOX_MGMT.ADD.VOICE.TWILIO.AUTH_TOKEN.PLACEHOLDER')
              "
              @blur="v$.authToken.$touch"
            />
            <span v-if="v$.authToken.$error" class="message">
              {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.AUTH_TOKEN.REQUIRED') }}
            </span>
          </label>
        </div>

        <div class="flex-shrink-0 flex-grow-0">
          <label :class="{ error: v$.apiKeySid.$error }">
            {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.LABEL', 'API Key SID') }}
            <input
              v-model.trim="apiKeySid"
              type="text"
              :placeholder="
                $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.PLACEHOLDER', 'Enter your Twilio API Key SID')
              "
              @blur="v$.apiKeySid.$touch"
            />
            <span v-if="v$.apiKeySid.$error" class="message">
              {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.REQUIRED', 'API Key SID is required') }}
            </span>
            <span class="help-text">
              {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.HELP', 'You can create API keys in the Twilio Console') }}
            </span>
          </label>
        </div>

        <div class="flex-shrink-0 flex-grow-0">
          <label :class="{ error: v$.apiKeySecret.$error }">
            {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.LABEL', 'API Key Secret') }}
            <input
              v-model.trim="apiKeySecret"
              type="text"
              :placeholder="
                $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.PLACEHOLDER', 'Enter your Twilio API Key Secret')
              "
              @blur="v$.apiKeySecret.$touch"
            />
            <span v-if="v$.apiKeySecret.$error" class="message">
              {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.REQUIRED', 'API Key Secret is required') }}
            </span>
          </label>
        </div>
        
        <div class="flex-shrink-0 flex-grow-0">
          <label>
            {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.TWIML_APP_SID.LABEL', 'TwiML App SID (Recommended)') }}
            <input
              v-model.trim="twimlAppSid"
              type="text"
              :placeholder="
                $t('INBOX_MGMT.ADD.VOICE.TWILIO.TWIML_APP_SID.PLACEHOLDER', 'Enter your Twilio TwiML App SID (starts with AP)')
              "
            />
            <span class="help-text">
              {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.TWIML_APP_SID.HELP', 'Required for browser-based calling. Create a TwiML App in the Twilio Console with Voice URLs pointing to your Chatwoot instance.') }}
            </span>
          </label>
        </div>
      </div>

      <!-- Add other provider configs here -->

      <div class="mt-4">
        <NextButton
          :is-loading="uiFlags.isCreating"
          :is-disabled="v$.$invalid"
          :label="$t('INBOX_MGMT.ADD.VOICE.SUBMIT_BUTTON')"
          type="submit"
          color="blue"
          @click="createChannel"
        />
      </div>
    </form>
  </div>
</template>
