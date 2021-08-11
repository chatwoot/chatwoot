<!-- Deprecated in favour of separate files for SMS and Whatsapp and also to implement new providers for each platform in the future-->
<template>
  <form class="row" @submit.prevent="createChannel()">
    <div class="medium-8 columns">
      <label :class="{ error: $v.channelName.$error }">
        {{ $t('INBOX_MGMT.ADD.TWILIO.CHANNEL_NAME.LABEL') }}
        <input
          v-model.trim="channelName"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.TWILIO.CHANNEL_NAME.PLACEHOLDER')"
          @blur="$v.channelName.$touch"
        />
        <span v-if="$v.channelName.$error" class="message">{{
          $t('INBOX_MGMT.ADD.TWILIO.CHANNEL_NAME.ERROR')
        }}</span>
      </label>
    </div>

    <div class="medium-8 columns">
      <label :class="{ error: $v.phoneNumber.$error }">
        {{ $t('INBOX_MGMT.ADD.TWILIO.PHONE_NUMBER.LABEL') }}
        <input
          v-model.trim="phoneNumber"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.TWILIO.PHONE_NUMBER.PLACEHOLDER')"
          @blur="$v.phoneNumber.$touch"
        />
        <span v-if="$v.phoneNumber.$error" class="message">{{
          $t('INBOX_MGMT.ADD.TWILIO.PHONE_NUMBER.ERROR')
        }}</span>
      </label>
    </div>

    <div class="medium-8 columns">
      <label :class="{ error: $v.accountSID.$error }">
        {{ $t('INBOX_MGMT.ADD.TWILIO.ACCOUNT_SID.LABEL') }}
        <input
          v-model.trim="accountSID"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.TWILIO.ACCOUNT_SID.PLACEHOLDER')"
          @blur="$v.accountSID.$touch"
        />
        <span v-if="$v.accountSID.$error" class="message">{{
          $t('INBOX_MGMT.ADD.TWILIO.ACCOUNT_SID.ERROR')
        }}</span>
      </label>
    </div>
    <div class="medium-8 columns">
      <label :class="{ error: $v.authToken.$error }">
        {{ $t('INBOX_MGMT.ADD.TWILIO.AUTH_TOKEN.LABEL') }}
        <input
          v-model.trim="authToken"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.TWILIO.AUTH_TOKEN.PLACEHOLDER')"
          @blur="$v.authToken.$touch"
        />
        <span v-if="$v.authToken.$error" class="message">{{
          $t('INBOX_MGMT.ADD.TWILIO.AUTH_TOKEN.ERROR')
        }}</span>
      </label>
    </div>

    <div class="medium-12 columns">
      <woot-submit-button
        :loading="uiFlags.isCreating"
        :button-text="$t('INBOX_MGMT.ADD.TWILIO.SUBMIT_BUTTON')"
      />
    </div>
  </form>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import router from '../../../../index';

const shouldStartWithPlusSign = (value = '') => value.startsWith('+');

export default {
  mixins: [alertMixin],
	props: {
		type: {
			type: String,
			required: true,
    },
	},
  data() {
    return {
      accountSID: '',
      authToken: '',
      medium: this.type,
      channelName: '',
      phoneNumber: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    channelName: { required },
    phoneNumber: { required, shouldStartWithPlusSign },
    authToken: { required },
    accountSID: { required },
    medium: { required },
  },
  methods: {
    async createChannel() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      try {
        const twilioChannel = await this.$store.dispatch(
          'inboxes/createTwilioChannel',
          {
            twilio_channel: {
              name: this.channelName,
              medium: this.medium,
              account_sid: this.accountSID,
              auth_token: this.authToken,
              phone_number: `+${this.phoneNumber.replace(/\D/g, '')}`,
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: twilioChannel.id,
          },
        });
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.ADD.TWILIO.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
