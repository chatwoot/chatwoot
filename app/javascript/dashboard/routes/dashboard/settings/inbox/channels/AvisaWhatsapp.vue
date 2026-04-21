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
      token: '',
      apiBaseUrl: '',
      acknowledgedRisk: false,
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required, isPhoneE164OrEmpty },
    token: { required },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) return;
      if (!this.acknowledgedRisk) {
        useAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP.AVISA.RISK_REQUIRED'));
        return;
      }

      try {
        const whatsappChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.inboxName?.trim(),
            channel: {
              type: 'whatsapp',
              phone_number: this.phoneNumber,
              provider: 'avisa',
              provider_config: {
                token: this.token,
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
    <div class="p-3 rounded-md bg-n-amber-3 text-n-amber-12 text-sm">
      ⚠️ {{ $t('INBOX_MGMT.ADD.WHATSAPP.AVISA.RISK_WARNING') }}
    </div>

    <label :class="{ error: v$.inboxName.$error }">
      {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
      <input
        v-model="inboxName"
        type="text"
        :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.PLACEHOLDER')"
      >
    </label>

    <label :class="{ error: v$.phoneNumber.$error }">
      {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.LABEL') }}
      <input v-model="phoneNumber" type="text" placeholder="+5511999999999">
    </label>

    <label :class="{ error: v$.token.$error }">
      Avisa API token
      <input v-model="token" type="text" placeholder="Avisa API token">
    </label>

    <label>
      API base URL (optional)
      <input v-model="apiBaseUrl" type="text" placeholder="https://api.avisaapi.com.br">
    </label>

    <label class="inline-flex items-center gap-2 text-sm">
      <input v-model="acknowledgedRisk" type="checkbox">
      {{ $t('INBOX_MGMT.ADD.WHATSAPP.AVISA.ACKNOWLEDGE') }}
    </label>

    <div class="flex justify-end mt-4">
      <NextButton
        type="submit"
        :disabled="uiFlags.isCreating || !acknowledgedRisk"
        :label="$t('INBOX_MGMT.ADD.WHATSAPP.SUBMIT_BUTTON')"
      />
    </div>
  </form>
</template>
