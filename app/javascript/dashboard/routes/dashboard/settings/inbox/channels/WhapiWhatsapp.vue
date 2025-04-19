<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      inboxName: '',
      phoneNumber: '',
      apiKey: '',
      webhookSecret: '',
      channelId: ''
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required, isPhoneE164OrEmpty },
    apiKey: { required },
    webhookSecret: { required },
    channelId: { required }
  },
  methods: {
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
              provider: 'whapi',
              provider_config: {
                api_key: this.apiKey,
                webhook_secret: this.webhookSecret,
                channel_id: this.channelId
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
          error.message || this.$t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <div class="wizard-body small-9 columns">
    <form class="mb-0" @submit.prevent="createChannel">
      <div class="mb-4">
        <label>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
          <input
            v-model="inboxName"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.PLACEHOLDER')
            "
            :class="{ error: v$.inboxName.$error }"
          />
        </label>
        <span v-if="v$.inboxName.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
        </span>
      </div>

      <div class="mb-4">
        <label>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.LABEL') }}
          <input
            v-model="phoneNumber"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.PLACEHOLDER')
            "
            :class="{ error: v$.phoneNumber.$error }"
          />
        </label>
        <span v-if="v$.phoneNumber.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.ERROR') }}
        </span>
      </div>

      <div class="mb-4">
        <label>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.LABEL') }}
          <input
            v-model="apiKey"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.PLACEHOLDER')
            "
            :class="{ error: v$.apiKey.$error }"
          />
        </label>
        <span v-if="v$.apiKey.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.ERROR') }}
        </span>
      </div>

      <div class="mb-4">
        <label>
          Webhook Secret
          <input
            v-model="webhookSecret"
            type="text"
            placeholder="Enter the webhook secret from Whapi.cloud"
            :class="{ error: v$.webhookSecret.$error }"
          />
        </label>
        <span v-if="v$.webhookSecret.$error" class="message">
          Webhook secret is required
        </span>
      </div>

      <div class="mb-4">
        <label>
          Whapi Channel ID
          <input
            v-model="channelId"
            type="text"
            placeholder="Enter the channel_id from Whapi.cloud (e.g. AQUAMN-8EFCZ)"
            :class="{ error: v$.channelId.$error }"
          />
        </label>
        <span v-if="v$.channelId.$error" class="message">
          Whapi Channel ID is required
        </span>
      </div>

      <div class="mb-0">
        <NextButton
          button-text="Connect"
          :is-loading="uiFlags.isCreating"
          button-type="submit"
        />
      </div>
    </form>
  </div>
</template>