<script>
// CUSTOMIZAÇÃO_SYNAPSEOS
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';

export default {
  components: { NextButton },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      inboxName: '',
      phoneNumber: '',
      apiKey: '',
      phoneNumberId: '',
      businessAccountId: '',
      apiBaseUrl: '',
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required, isPhoneE164OrEmpty },
    apiKey: { required },
    phoneNumberId: { required },
    businessAccountId: { required },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) return;

      try {
        const whatsappChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.inboxName?.trim(),
            channel: {
              type: 'whatsapp',
              phone_number: this.phoneNumber,
              provider: 'hyperflow',
              provider_config: {
                api_key: this.apiKey,
                phone_number_id: this.phoneNumberId,
                business_account_id: this.businessAccountId,
                api_base_url: this.apiBaseUrl?.trim(),
              },
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: { page: 'new', inbox_id: whatsappChannel.id },
        });
      } catch (error) {
        useAlert(error.message || this.$t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<template>
  <form class="flex flex-col gap-4 mx-0" @submit.prevent="createChannel()">
    <label :class="{ error: v$.inboxName.$error }">
      {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
      <input
        v-model="inboxName"
        type="text"
        :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.PLACEHOLDER')"
      >
      <span v-if="v$.inboxName.$error" class="message">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
      </span>
    </label>

    <label :class="{ error: v$.phoneNumber.$error }">
      {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.LABEL') }}
      <input v-model="phoneNumber" type="text" placeholder="+5511999999999">
      <span v-if="v$.phoneNumber.$error" class="message">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.ERROR') }}
      </span>
    </label>

    <label :class="{ error: v$.apiKey.$error }">
      Hyperflow API key
      <input v-model="apiKey" type="text" placeholder="Hyperflow access token">
    </label>

    <label :class="{ error: v$.phoneNumberId.$error }">
      Phone number ID
      <input v-model="phoneNumberId" type="text" placeholder="Hyperflow phone_number_id">
    </label>

    <label :class="{ error: v$.businessAccountId.$error }">
      Business account ID
      <input v-model="businessAccountId" type="text" placeholder="WABA ID">
    </label>

    <label>
      API base URL (optional)
      <input v-model="apiBaseUrl" type="text" placeholder="https://api.hyperflow.com.br">
    </label>

    <div class="flex justify-end mt-4">
      <NextButton
        type="submit"
        :disabled="uiFlags.isCreating"
        :label="$t('INBOX_MGMT.ADD.WHATSAPP.SUBMIT_BUTTON')"
      />
    </div>
  </form>
</template>
