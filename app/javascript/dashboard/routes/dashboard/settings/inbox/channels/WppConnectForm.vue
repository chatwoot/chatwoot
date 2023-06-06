<!-- eslint-disable no-console -->
<template>
  <form class="row" @submit.prevent="generateQrCode()">
    <div class="medium-8 columns">
      <label :class="{ error: $v.inboxName.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
        <input
          v-model.trim="inboxName"
          :disabled="disabledTyping"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.PLACEHOLDER')"
          @blur="$v.inboxName.$touch"
        />
        <span v-if="$v.inboxName.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
        </span>
      </label>
    </div>

    <div class="medium-8 columns">
      <label :class="{ error: $v.phoneNumber.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.LABEL') }}
        <input
          v-model.trim="phoneNumber"
          :disabled="disabledTyping"
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
        style="width: 100%; max-width: 400px; margin-bottom: 8px;"
      />
    </div>

    <div v-if="messageShown" class="medium-12 columns">
      <p>{{ messageShown }}</p>
    </div>

    <div class="medium-12 columns">
      <woot-submit-button
        :loading="uiFlags.isCreating"
        :button-text="$t('INBOX_MGMT.ADD.WHATSAPP.QRCODE_MESSAGES.GENERATE')"
        :disabled="disabledTyping"
      />
      <span v-if="disabledTyping" class="spinner" />
    </div>
  </form>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import router from '../../../../index';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';
import WppConnectAPI from './WppConnectAPI';

export default {
  mixins: [alertMixin],
  data() {
    return {
      inboxName: '',
      phoneNumber: '',
      imgSrc: '',
      messageShown: '',
      disabledTyping: false,
      apiToken: '',
      maxAttempts: 5,
      attempts: 0,
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required, isPhoneE164OrEmpty },
  },
  methods: {
    async createChannel() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      try {
        const whatsappChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.inboxName,
            channel: {
              type: 'common_whatsapp',
              phone_number: this.phoneNumber,
              token: this.apiToken,
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
        this.showAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE'));
      }
    },

    async generateQrCode(isRec = false) {
      if (!isRec) {
        if (this.disabledTyping) return;
        this.$v.$touch();
        if (this.$v.$invalid) {
          return;
        }
      }

      this.disabledTyping = true;
      this.messageShown = '';
      this.imgSrc = '';

      const { data } = await WppConnectAPI.getQrCode(
        this.phoneNumber,
        this.inbox
      );

      await WppConnectAPI.waitInSeconds(2);

      if (data.success && data.qrcode) {
        const { qrcode } = data;
        this.imgSrc = qrcode.includes('data:image')
          ? qrcode
          : 'data:image/png;base64,' + qrcode;

        this.checkConnectionStatus();
      } else {
        if (this.attempts <= this.maxAttempts) {
          // eslint-disable-next-line no-plusplus
          this.attempts++;
          this.generateQrCode(true);
          return;
        }
        this.messageShown = $t('INBOX_MGMT.ADD.WHATSAPP.QRCODE_MESSAGES.FAILED_OBTAIN');
        this.disabledTyping = false;
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

      this.messageShown = $t('INBOX_MGMT.ADD.WHATSAPP.QRCODE_MESSAGES.SUCCESS_ON_CONNECTION');
      this.imgSrc = '';
      this.apiToken = data.token;
      this.createChannel();
    },
  },
};
</script>
