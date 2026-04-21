<script>
// CUSTOMIZAÇÃO_SYNAPSEOS
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required, url as urlValidator } from '@vuelidate/validators';
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
      n8nOutgoingUrl: '',
      webhookSecret: '',
      acknowledgedRisk: false,
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
    incomingWebhookUrl() {
      if (!this.phoneNumber) return '';
      return `${window.location.origin}/webhooks/avisa/${encodeURIComponent(this.phoneNumber)}`;
    },
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required, isPhoneE164OrEmpty },
    n8nOutgoingUrl: { required, urlValidator },
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
                n8n_outgoing_url: this.n8nOutgoingUrl.trim(),
                webhook_secret: this.webhookSecret?.trim() || '',
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
    <div class="p-3 rounded-md bg-s-warning-soft text-s-warning-text text-sm leading-relaxed">
      ⚠️ {{ $t('INBOX_MGMT.ADD.WHATSAPP.AVISA.RISK_WARNING') }}
    </div>

    <div class="p-3 rounded-md bg-s-brand-soft text-s-brand-text text-sm leading-relaxed">
      ℹ️ {{ $t('INBOX_MGMT.ADD.WHATSAPP.AVISA.EXPLAINER') }}
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

    <label :class="{ error: v$.n8nOutgoingUrl.$error }">
      {{ $t('INBOX_MGMT.ADD.WHATSAPP.AVISA.N8N_URL_LABEL') }}
      <input
        v-model="n8nOutgoingUrl"
        type="url"
        placeholder="https://n8n.seudominio.com/webhook/avisa-outgoing"
      >
      <span class="text-xs text-s-muted mt-1 block">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.AVISA.N8N_URL_HINT') }}
      </span>
    </label>

    <label>
      {{ $t('INBOX_MGMT.ADD.WHATSAPP.AVISA.SECRET_LABEL') }}
      <input v-model="webhookSecret" type="text" placeholder="optional shared secret">
      <span class="text-xs text-s-muted mt-1 block">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.AVISA.SECRET_HINT') }}
      </span>
    </label>

    <div v-if="incomingWebhookUrl" class="p-3 rounded-md bg-s-subtle text-s-primary text-sm">
      <div class="font-medium mb-1">{{ $t('INBOX_MGMT.ADD.WHATSAPP.AVISA.INCOMING_URL_LABEL') }}</div>
      <code class="text-xs break-all">{{ incomingWebhookUrl }}</code>
      <div class="text-xs text-s-muted mt-2">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.AVISA.INCOMING_URL_HINT') }}
      </div>
    </div>

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
