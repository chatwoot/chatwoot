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

    <!-- <div class="medium-12 columns">
      <woot-submit-button
        :loading="uiFlags.isCreating"
        :button-text="$t('INBOX_MGMT.ADD.WHATSAPP.SUBMIT_BUTTON')"
      />
    </div> -->

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
        :button-text="'Generate QrCode'"
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
      connectionTries: 0,
      maxTries: 6,
      apiToken: '',
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

    async generateQrCode() {
      if (this.disabledTyping) return;
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      this.disabledTyping = true;
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
        this.messageShown = 'Falha ao obter o qrCode, tente novamente';
        this.disabledTyping = false;
      }
    },

    async checkConnectionStatus() {
      const { data } = await WppConnectAPI.checkConnectionStatus(
        this.phoneNumber,
        this.inbox
      );
      if (data.success !== true && this.connectionTries <= this.maxTries) {
        const { qrcode } = data;
        if (qrcode)
          this.imgSrc = qrcode.includes('data:image')
            ? qrcode
            : 'data:image/png;base64,' + qrcode;
        // eslint-disable-next-line no-plusplus
        this.connectionTries++;
        await this.waitInSeconds(5);
        this.checkConnectionStatus();
      } else {
        this.messageShown = 'Sucesso ao conectar!';
        this.imgSrc = '';
        this.apiToken = data.token;
        this.createChannel();
      }
    },

    waitInSeconds(t = 1) {
      return new Promise(resolve =>
        setTimeout(() => {
          resolve();
        }, t * 1000)
      );
    },
  },
};
</script>
