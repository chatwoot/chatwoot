<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.TWILIO.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.TWILIO.DESC')"
    />
    <woot-loading-state
      v-if="isCreating"
      message="Creating Website Support Channel"
    >
    </woot-loading-state>
    <form v-if="!isCreating" class="row" @submit.prevent="createChannel()">
      <div class="medium-12 columns">
        <label>
          {{ $t('INBOX_MGMT.ADD.TWILIO.ACCOUNT_SID.LABEL') }}
          <input
            v-model.trim="accountSID"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.TWILIO.ACCOUNT_SID.PLACEHOLDER')"
          />
        </label>
      </div>
      <div class="medium-12 columns">
        <label>
          {{ $t('INBOX_MGMT.ADD.TWILIO.AUTH_TOKEN.LABEL') }}
          <input
            v-model.trim="authToken"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.TWILIO.AUTH_TOKEN.PLACEHOLDER')"
          />
        </label>
      </div>
      <div class="medium-12 columns">
        <label>
          {{ $t('INBOX_MGMT.ADD.TWILIO.PHONE_NUMBER.LABEL') }}
          <input
            v-model.trim="phoneNumber"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.TWILIO.PHONE_NUMBER.PLACEHOLDER')"
          />
        </label>
      </div>

      <div class="modal-footer">
        <div class="medium-12 columns">
          <woot-submit-button
            :loading="uiFlags.isCreating"
            :disabled="!authToken || !accountSID || !phoneNumber"
            :button-text="$t('INBOX_MGMT.ADD.TWILIO.SUBMIT_BUTTON')"
          />
        </div>
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader';

export default {
  components: {
    PageHeader,
  },
  mixins: [alertMixin],
  data() {
    return {
      accountSID: '',
      authToken: '',
      phoneNumber: '',
      isCreating: false,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  methods: {
    async createChannel() {
      try {
        const twilioChannel = await this.$store.dispatch(
          'inboxes/createTwilioChannel',
          {
            account_sid: this.accountSID,
            auth_token: this.authToken,
            phone_number: this.phoneNumber,
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
