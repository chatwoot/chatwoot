<!-- eslint-disable no-console -->
<template>
  <form class="row" @submit.prevent="generateQrCode()">
    <div class="medium-8 columns">
      <label :class="{ error: $v.inboxName.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
        <input
          v-model.trim="inboxName"
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
      <img :src="imgSrc" alt="qr-code" style="width: 100%; max-width: 400px" />
    </div>

    <div v-if="errorMessage" class="medium-12 columns">
      <p>{{ errorMessage }}</p>
    </div>

    <div class="medium-12 columns">
      <woot-submit-button
        :loading="uiFlags.isCreating"
        :button-text="'Generate QrCode'"
      />
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
      errorMessage: '',
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
      this.errorMessage = '';
      this.imgSrc = '';

      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      const { data } = await WppConnectAPI.getQrCode('a', 'b');
      if (data.success && data.qrcode) {
        const { qrcode } = data;
        this.imgSrc = qrcode.includes('data:image')
          ? qrcode
          : 'data:image/png;base64,' + qrcode;
      } else {
        this.errorMessage = 'Falha ao obter o qrCode, tente novamente';
      }
    },
  },
};
</script>
