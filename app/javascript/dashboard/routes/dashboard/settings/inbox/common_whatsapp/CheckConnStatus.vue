<!-- eslint-disable -->
<template>
  <form class="row" @submit.prevent="generateQrCode()">
    <div class="medium-8 columns">
      <label :class="{ error: $v.phoneNumber.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.LABEL') }}
        <input
          v-model.trim="phoneNumber"
          disabled
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.PLACEHOLDER')"
          @blur="$v.phoneNumber.$touch"
        />
        <span v-if="$v.phoneNumber.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.ERROR') }}
        </span>
      </label>
    </div>

    <div v-if="imgSrc" id="qr-code-container" class="medium-12 columns">
      <img
        :src="imgSrc"
        alt="qr-code"
        style="width: 100%; max-width: 400px; margin-bottom: 8px"
      />
    </div>

    <div v-if="messageShown" class="medium-12 columns">
      <p>{{ messageShown }}</p>
    </div>

    <div class="medium-12 columns">
      <woot-submit-button
        :loading="uiFlags.isCreating"
        :button-text="$t('INBOX_MGMT.ADD.WHATSAPP.QRCODE_MESSAGES.GENERATE')"
        :disabled="(loadingSpinner || disabledButton) && !isConnected"
      />
      <woot-button
        v-if="!loadingSpinner && isConnected"
        color-scheme="alert"
        @click="clearSession"
      >
        Refresh Connection
      </woot-button>
      <span v-if="loadingSpinner" class="spinner" />
    </div>
  </form>
</template>

<script>
import WppConnectAPI from '../channels/WppConnectAPI';
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';

export default {
  mixins: [alertMixin],
  props: {
    phoneNumber: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      inboxName: '',
      imgSrc: '',
      messageShown: '',
      loadingSpinner: false,
      disabledButton: false,
      apiToken: '',
      isConnected: false,
      maxAttempts: 5,
      attempts: 0,
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  validations: {
    phoneNumber: { required, isPhoneE164OrEmpty },
  },
  mounted() {
    this.connectionTries = 6;
    this.checkConnectionStatus();
  },
  methods: {
    async generateQrCode(isRec = false) {
      if(!isRec) {
        if (this.loadingSpinner) return;
        this.$v.$touch();
        if (this.$v.$invalid) {
          return;
        }
      }

      this.loadingSpinner = true;
      this.messageShown = '';
      this.imgSrc = '';

      const { data } = await WppConnectAPI.getQrCode(
        this.phoneNumber,
        this.inbox
      );
      if (data.success && data.qrcode) {
        const { qrcode } = data;
        this.imgSrc = qrcode.includes('data:image')
          ? qrcode
          : 'data:image/png;base64,' + qrcode;

        // await this.waitInSeconds(7);
        this.checkConnectionStatus();
      } else {
        if (this.attempts <= this.maxAttempts) {
          // eslint-disable-next-line no-plusplus
          this.attempts++;
          this.generateQrCode(true);
          return;
        }
        this.messageShown = $t('INBOX_MGMT.ADD.WHATSAPP.QRCODE_MESSAGES.FAILED_OBTAIN');
        this.loadingSpinner = false;
      }
    },

    async checkConnectionStatus() {
      const { data } = await WppConnectAPI.checkConnectionStatus(
        this.phoneNumber,
        this.inbox
      );
      const { qrcode } = data;
      if (
        data.success !== true ||
        ['QRCODE', 'INITIALIZING', 'CLOSED'].includes(data.status)
      ) {
        if (qrcode)
          this.imgSrc = qrcode.includes('data:image')
            ? qrcode
            : 'data:image/png;base64,' + qrcode;
        await WppConnectAPI.waitInSeconds(5);
        this.checkConnectionStatus();
        return;
      }
      if (data.status === 'CLOSED') {
        this.isConnected = false;
        return;
      }

      this.messageShown = $t('INBOX_MGMT.ADD.WHATSAPP.QRCODE_MESSAGES.SUCCESS_ON_CONNECTION');
      this.imgSrc = '';
      this.disabledButton = true;
      this.apiToken = data.token;
      this.isConnected = true;
    },

    async clearSession() {
      this.loadingSpinner = true;
      this.messageShown = '';
      let data;
      try {
        const { data: dataReq } = await WppConnectAPI.closeAndClearSession(
          this.phoneNumber,
          this.inbox
        );
        data = dataReq;
      } catch (error) {
        this.messageShown = $t('INBOX_MGMT.ADD.WHATSAPP.QRCODE_MESSAGES.FAILED_REFRESH');
        return;
      }

      this.loadingSpinner = false;

      if (!data.success) {
        this.messageShown = $t('INBOX_MGMT.ADD.WHATSAPP.QRCODE_MESSAGES.FAILED_REFRESH');
        return;
      }

      this.isConnected = false;
    },
  },
};
</script>
