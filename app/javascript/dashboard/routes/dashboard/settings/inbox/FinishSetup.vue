<template>
  <div class="wizard-body columns content-box small-9">
    <empty-state
      :title="$t('INBOX_MGMT.FINISH.TITLE')"
      :message="message"
      :button-text="$t('INBOX_MGMT.FINISH.BUTTON_TEXT')"
    >
      <div class="medium-12 columns text-center">
        <div class="website--code">
          <woot-code
            v-if="currentInbox.web_widget_script"
            :script="currentInbox.web_widget_script"
          >
          </woot-code>
        </div>
        <div class="medium-6 small-offset-3">
          <woot-code
            v-if="isATwilioInbox"
            lang="html"
            :script="twilioCallbackURL"
          >
          </woot-code>
        </div>
        <div class="medium-6 small-offset-3">
          <woot-code
            v-if="isAEmailInbox"
            lang="html"
            :script="currentInbox.forward_to_email"
          >
          </woot-code>
        </div>
        <div class="footer">
          <woot-button
            v-if="isAWebWidgetInbox"
            color-scheme="primary"
            class="settings-button"
            @click="verifyWidgetInstallation"
          >
            {{ $t('INBOX_MGMT.FINISH.VERIFY_WIDGET_INSTALLATION') }}
          </woot-button>
          <router-link
            class="button hollow primary settings-button"
            :to="{
              name: 'settings_inbox_show',
              params: { inboxId: this.$route.params.inbox_id },
            }"
          >
            {{ $t('INBOX_MGMT.FINISH.MORE_SETTINGS') }}
          </router-link>
          <router-link
            class="button success"
            :to="{
              name: 'inbox_dashboard',
              params: { inboxId: this.$route.params.inbox_id },
            }"
          >
            {{ $t('INBOX_MGMT.FINISH.BUTTON_TEXT') }}
          </router-link>
        </div>
      </div>
    </empty-state>
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
import EmptyState from '../../../../components/widgets/EmptyState';

export default {
  components: {
    EmptyState,
  },
  mixins: [configMixin, alertMixin],
  data() {
    return {
      alertMessage: null,
    };
  },
  computed: {
    currentInbox() {
      return this.$store.getters['inboxes/getInbox'](
        this.$route.params.inbox_id
      );
    },
    isATwilioInbox() {
      return this.currentInbox.channel_type === 'Channel::TwilioSms';
    },
    isAEmailInbox() {
      return this.currentInbox.channel_type === 'Channel::Email';
    },
    isAWebWidgetInbox() {
      return this.currentInbox.channel_type === 'Channel::WebWidget';
    },
    message() {
      if (this.isATwilioInbox) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.ADD.TWILIO.API_CALLBACK.SUBTITLE'
        )}`;
      }

      if (this.isAEmailInbox) {
        return this.$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.FINISH_MESSAGE');
      }

      if (!this.currentInbox.web_widget_script) {
        return this.$t('INBOX_MGMT.FINISH.MESSAGE');
      }
      return this.$t('INBOX_MGMT.FINISH.WEBSITE_SUCCESS');
    },
  },
  methods: {
    async verifyWidgetInstallation() {
      try {
        const result = await this.$store.dispatch(
          'inboxes/verifyWidgetInstallation',
          this.$route.params.inbox_id
        );
        this.alertMessage = result;
      } catch (error) {
        const errorMessage = error?.response?.data?.message;
        this.alertMessage =
          errorMessage ||
          this.$t('INBOX_MGMT.FINISH.ERRORS.VERIFY_INSTALLATION_ERROR');
      } finally {
        this.showAlert(this.alertMessage);
      }
    },
  },
};
</script>
<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';

.website--code {
  margin: $space-normal auto;
  max-width: 70%;
}

.footer {
  display: flex;
  justify-content: center;
}

.settings-button {
  margin-right: var(--space-small);
}
</style>
