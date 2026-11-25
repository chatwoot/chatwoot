<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import { isPhoneE164OrEmpty, isNumber } from 'shared/helpers/Validators';
import InboxesAPI from 'dashboard/api/inboxes';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    mode: {
      type: String,
      default: 'create',
      validator: value => ['create', 'convert'].includes(value),
    },
    inbox: {
      type: Object,
      default: null,
    },
    enableCallingOnComplete: {
      type: Boolean,
      default: false,
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    const isConvert = this.mode === 'convert';
    return {
      inboxName: isConvert ? this.inbox?.name || '' : '',
      phoneNumber: isConvert ? this.inbox?.phone_number || '' : '',
      apiKey: '',
      appSecret: '',
      phoneNumberId: '',
      businessAccountId: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
    isConvertMode() {
      return this.mode === 'convert';
    },
    submitButtonLabel() {
      return this.isConvertMode
        ? this.$t('INBOX_MGMT.CONVERT.SUBMIT_BUTTON')
        : this.$t('INBOX_MGMT.ADD.WHATSAPP.SUBMIT_BUTTON');
    },
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required, isPhoneE164OrEmpty },
    apiKey: { required },
    appSecret: { required },
    phoneNumberId: { required, isNumber },
    businessAccountId: { required, isNumber },
  },
  methods: {
    buildProviderConfig() {
      return {
        api_key: this.apiKey,
        app_secret: this.appSecret,
        phone_number_id: this.phoneNumberId,
        business_account_id: this.businessAccountId,
      };
    },
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        if (this.isConvertMode) {
          await this.$store.dispatch('inboxes/convertProvider', {
            inboxId: this.inbox.id,
            provider: 'whatsapp_cloud',
            providerConfig: this.buildProviderConfig(),
          });

          useAlert(this.$t('INBOX_MGMT.CONVERT.API.SUCCESS_MESSAGE'));
          router.replace({
            name: 'settings_inbox_show',
            params: {
              accountId: router.currentRoute.value.params.accountId,
              inboxId: this.inbox.id,
            },
          });
          return;
        }

        const whatsappChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.inboxName?.trim(),
            channel: {
              type: 'whatsapp',
              phone_number: this.phoneNumber,
              provider: 'whatsapp_cloud',
              provider_config: this.buildProviderConfig(),
            },
          }
        );

        if (this.enableCallingOnComplete) {
          try {
            await InboxesAPI.enableWhatsappCalling(whatsappChannel.id);
          } catch (_) {
            useAlert(this.$t('INBOX_MGMT.WHATSAPP_CALLING.ENABLE_FAILED'));
          }
        }

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: whatsappChannel.id,
          },
        });
      } catch (error) {
        useAlert(
          error.message ||
            this.$t(
              this.isConvertMode
                ? 'INBOX_MGMT.CONVERT.API.ERROR_MESSAGE'
                : 'INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE'
            )
        );
      }
    },
  },
};
</script>

<template>
  <form class="flex flex-wrap flex-col mx-0" @submit.prevent="createChannel()">
    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.inboxName.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
        <input
          v-model="inboxName"
          type="text"
          :disabled="isConvertMode"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.PLACEHOLDER')"
          @blur="v$.inboxName.$touch"
        />
        <span v-if="v$.inboxName.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
        </span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.phoneNumber.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.LABEL') }}
        <input
          v-model="phoneNumber"
          type="text"
          :disabled="isConvertMode"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.PLACEHOLDER')"
          @blur="v$.phoneNumber.$touch"
        />
        <span v-if="v$.phoneNumber.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.ERROR') }}
        </span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.phoneNumberId.$error }">
        <span>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER_ID.LABEL') }}
        </span>
        <input
          v-model="phoneNumberId"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER_ID.PLACEHOLDER')
          "
          @blur="v$.phoneNumberId.$touch"
        />
        <span v-if="v$.phoneNumberId.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER_ID.ERROR') }}
        </span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.businessAccountId.$error }">
        <span>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.BUSINESS_ACCOUNT_ID.LABEL') }}
        </span>
        <input
          v-model="businessAccountId"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP.BUSINESS_ACCOUNT_ID.PLACEHOLDER')
          "
          @blur="v$.businessAccountId.$touch"
        />
        <span v-if="v$.businessAccountId.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.BUSINESS_ACCOUNT_ID.ERROR') }}
        </span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.apiKey.$error }">
        <span>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.LABEL') }}
        </span>
        <input
          v-model="apiKey"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.PLACEHOLDER')"
          @blur="v$.apiKey.$touch"
        />
        <span v-if="v$.apiKey.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.ERROR') }}
        </span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.appSecret.$error }">
        <span>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.APP_SECRET.LABEL') }}
        </span>
        <input
          v-model="appSecret"
          type="password"
          autocomplete="off"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.APP_SECRET.PLACEHOLDER')
          "
          @blur="v$.appSecret.$touch"
        />
        <span class="help-text">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.MANUAL_SETUP.APP_SECRET.HELP') }}
        </span>
        <span v-if="v$.appSecret.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.ERROR') }}
        </span>
      </label>
    </div>

    <div class="w-full mt-4">
      <NextButton
        :disabled="uiFlags.isCreating || uiFlags.isUpdating"
        :is-loading="uiFlags.isCreating || uiFlags.isUpdating"
        type="submit"
        solid
        blue
        :label="submitButtonLabel"
      />
    </div>
  </form>
</template>
