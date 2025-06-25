<template>
  <form class="row" @submit.prevent="createChannel()">
    <div class="medium-8 columns">
      <label :class="{ error: $v.inboxName.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.INBOX_NAME.LABEL') }}
        <input
          v-model.trim="inboxName"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.INBOX_NAME.PLACEHOLDER')
          "
          @blur="$v.inboxName.$touch"
        />
        <span v-if="$v.inboxName.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.INBOX_NAME.ERROR')
        }}</span>
      </label>
    </div>

    <div class="medium-8 columns">
      <label :class="{ error: $v.phoneNumber.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.PHONE_NUMBER.LABEL') }}
        <input
          v-model.trim="phoneNumber"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.PHONE_NUMBER.PLACEHOLDER')
          "
          @blur="$v.phoneNumber.$touch"
        />
        <span v-if="$v.phoneNumber.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.PHONE_NUMBER.ERROR')
        }}</span>
      </label>
    </div>

    <div class="medium-8 columns">
      <label :class="{ error: $v.accountId.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.ACCOUNT_ID.LABEL') }}
        <input
          v-model.trim="accountId"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.ACCOUNT_ID.PLACEHOLDER')
          "
          @blur="$v.accountId.$touch"
        />
        <span v-if="$v.accountId.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.ACCOUNT_ID.ERROR')
        }}</span>
      </label>
    </div>

    <div class="medium-8 columns">
      <label :class="{ error: $v.applicationId.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.APPLICATION_ID.LABEL') }}
        <input
          v-model.trim="applicationId"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.APPLICATION_ID.PLACEHOLDER')
          "
          @blur="$v.applicationId.$touch"
        />
        <span v-if="$v.applicationId.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.APPLICATION_ID.ERROR')
        }}</span>
      </label>
    </div>

    <div class="medium-8 columns">
      <label :class="{ error: $v.apiKey.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.API_KEY.LABEL') }}
        <input
          v-model.trim="apiKey"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.SMS.BANDWIDTH.API_KEY.PLACEHOLDER')"
          @blur="$v.apiKey.$touch"
        />
        <span v-if="$v.apiKey.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.API_KEY.ERROR')
        }}</span>
      </label>
    </div>

    <div class="medium-8 columns">
      <label :class="{ error: $v.apiSecret.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.API_SECRET.LABEL') }}
        <input
          v-model.trim="apiSecret"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.API_SECRET.PLACEHOLDER')
          "
          @blur="$v.apiSecret.$touch"
        />
        <span v-if="$v.apiSecret.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.API_SECRET.ERROR')
        }}</span>
      </label>
    </div>

    <div class="medium-12 columns">
      <woot-submit-button
        :loading="uiFlags.isCreating"
        :button-text="$t('INBOX_MGMT.ADD.SMS.BANDWIDTH.SUBMIT_BUTTON')"
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
  data() {
    return {
      accountId: '',
      apiKey: '',
      apiSecret: '',
      applicationId: '',
      inboxName: '',
      phoneNumber: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
      globalConfig: 'globalConfig/get',
    }),
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required, shouldStartWithPlusSign },
    apiKey: { required },
    apiSecret: { required },
    applicationId: { required },
    accountId: { required },
  },
  methods: {
    async createChannel() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      try {
        const smsChannel = await this.$store.dispatch('inboxes/createChannel', {
          name: this.inboxName,
          channel: {
            type: 'sms',
            phone_number: this.phoneNumber,
            provider_config: {
              api_key: this.apiKey,
              api_secret: this.apiSecret,
              application_id: this.applicationId,
              account_id: this.accountId,
            },
          },
        });

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: smsChannel.id,
          },
        });
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.ADD.SMS.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
