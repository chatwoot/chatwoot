<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import NextButton from 'dashboard/components-next/button/Button.vue';
import WhatsappUnofficialAPI from 'dashboard/api/channel/whatsappUnofficialClient';

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
      channel: null,
      qrCode: '',
      status: 'idle',
      qrError: '',
      pollingInterval: null,
      qrTimeoutTimer: null,
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required },
  },
  beforeUnmount() {
    this.stopPolling();
  },
  methods: {
    async trialReuseExistingChannel() {
      try {
        const { data } = await WhatsappUnofficialAPI.findByPhone({
          phone_number: this.phoneNumber,
        });
        if (data?.channel_id) {
          return data;
        }
      } catch (_) {
        // No existing channel for this number; fall through to creating one.
      }
      return null;
    },

    async reuseExistingChannel() {
      const existingChannel = await this.trialReuseExistingChannel();
      if (!existingChannel) {
        return false;
      }
      this.channel = {
        id: existingChannel.inbox_id,
        channelId: existingChannel.channel_id,
      };
      await this.connectAndPoll();
      return true;
    },

    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      // An aborted scan leaves its channel row behind (create is atomic), so
      // retrying the same number would hit phone_number uniqueness. Resume the
      // existing channel instead of failing with a duplicate-number 422.
      if (await this.reuseExistingChannel()) {
        return;
      }

      try {
        const inbox = await this.$store.dispatch('inboxes/createChannel', {
          name: this.inboxName?.trim(),
          channel: {
            type: 'whatsapp',
            phone_number: this.phoneNumber,
            provider: 'whatsapp_unofficial',
          },
        });

        // Inboxes API returns { id: inbox_id, channel_id: whatsapp_channel_id }
        // QR/status endpoints need the whatsapp channel id, while post-connect
        // navigation needs the inbox id.
        this.channel = {
          id: inbox.id,
          channelId: inbox.channel_id || inbox.channelId,
        };
        await this.connectAndPoll();
      } catch (error) {
        // Fall back to resuming the existing channel if the create failed
        // because the number is already taken (e.g. concurrent scan).
        if (!(await this.reuseExistingChannel())) {
          useAlert(
            error.message || this.$t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE')
          );
        }
      }
    },

    async connectAndPoll() {
      this.status = 'scanning';
      this.qrError = '';
      try {
        await WhatsappUnofficialAPI.connect({
          phone_number: this.phoneNumber,
        });
      } catch (error) {
        this.status = 'error';
        this.qrError = error.message || 'Failed to contact companion';
        return;
      }
      this.startPolling();
    },

    startPolling() {
      this.stopPolling();
      this.poll();
      this.pollingInterval = setInterval(this.poll, 3000);
      // A QR should appear quickly. If the companion never emits one (e.g. its
      // WhatsApp websocket is unreachable), stop waiting so the setup flow
      // doesn't hang indefinitely on "Generating QR code…".
      this.qrTimeoutTimer = setTimeout(this.onQrTimeout, 60000);
    },

    stopPolling() {
      if (this.pollingInterval) {
        clearInterval(this.pollingInterval);
        this.pollingInterval = null;
      }
      if (this.qrTimeoutTimer) {
        clearTimeout(this.qrTimeoutTimer);
        this.qrTimeoutTimer = null;
      }
    },

    onQrTimeout() {
      this.stopPolling();
      this.status = 'error';
      this.qrError = this.$t('INBOX_MGMT.UNOFFICIAL_WHATSAPP.QR_TIMEOUT');
    },

    resetToForm() {
      this.stopPolling();
      this.status = 'idle';
      this.qrCode = '';
      this.qrError = '';
    },

    async retryScan() {
      this.connectAndPoll();
    },

    async poll() {
      if (!this.channel) return;
      const pollingChannelId = this.channel.channelId || this.channel.id;
      try {
        const { data } = await WhatsappUnofficialAPI.getQr(pollingChannelId);
        this.qrCode = data.qr || '';
        // Companion returns 204 when connected or before QR; handle via status check
        if (!data?.qr) {
          try {
            const { data: statusData } = await WhatsappUnofficialAPI.getStatus(pollingChannelId);
            if (statusData?.status === 'connected') {
              this.status = 'connected';
              this.stopPolling();
              this.finishSetup();
              return;
            }
          } catch (_) {
            // ignore status errors, keep polling
          }
        }
        this.status = data.status || 'scanning';
        if (this.status === 'connected') {
          this.stopPolling();
          this.finishSetup();
        }
      } catch (error) {
        // keep polling; transient companion errors are non-fatal
        this.status = 'scanning';
      }
    },

    async finishSetup() {
      router.replace({
        name: 'settings_inboxes_add_agents',
        params: {
          page: 'new',
          inbox_id: this.channel.id,
        },
      });
    },
  },
};
</script>

<template>
  <div class="flex flex-col gap-6">
    <form
      v-if="status === 'idle'"
      class="flex flex-wrap flex-col mx-0"
      @submit.prevent="createChannel()"
    >
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.inboxName.$error }">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
          <input
            v-model="inboxName"
            type="text"
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
            :placeholder="
              $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.PLACEHOLDER')
            "
            @blur="v$.phoneNumber.$touch"
          />
          <span v-if="v$.phoneNumber.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-full mt-4">
        <NextButton
          :disabled="uiFlags.isCreating"
          :is-loading="uiFlags.isCreating"
          type="submit"
          solid
          blue
          :label="$t('INBOX_MGMT.ADD.WHATSAPP.SUBMIT_BUTTON')"
        />
      </div>
    </form>

    <div
      v-else
      class="flex flex-col items-center gap-4 p-6 rounded-2xl border border-n-weak"
    >
      <p class="text-sm font-medium text-n-slate-12">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.UNOFFICIAL.QR_TITLE') }}
      </p>
      <img v-if="qrCode" :src="qrCode" alt="WhatsApp QR" class="size-56" />
      <p v-else class="text-sm text-n-slate-11">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.UNOFFICIAL.QR_WAITING') }}
      </p>
      <p v-if="status === 'scanning'" class="text-xs text-n-slate-10">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.UNOFFICIAL.QR_SCANNING') }}
      </p>
      <p v-if="status === 'error'" class="text-xs text-n-ruby-10 text-center">
        {{ qrError }}
      </p>
      <div v-if="status === 'error'" class="flex flex-wrap gap-3">
        <NextButton
          sm
          blue
          :label="$t('INBOX_MGMT.UNOFFICIAL_WHATSAPP.RECONNECT_BUTTON')"
          @click="retryScan"
        />
        <NextButton
          sm
          gray
          :label="$t('INBOX_MGMT.UNOFFICIAL_WHATSAPP.BACK_BUTTON')"
          @click="resetToForm"
        />
      </div>
    </div>
  </div>
</template>
