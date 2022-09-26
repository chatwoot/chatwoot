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
          />
        </div>
        <div class="medium-6 small-offset-3">
          <woot-code
            v-if="isATwilioInbox"
            lang="html"
            :script="currentInbox.callback_webhook_url"
          />
        </div>
        <div class="medium-6 small-offset-3">
          <woot-code
            v-if="isAWhatsappWhatsappCloudInbox"
            lang="html"
            :script="currentInbox.callback_webhook_url"
          />
        </div>
        <div class="medium-6 small-offset-3">
          <woot-code
            v-if="isALineInbox"
            lang="html"
            :script="currentInbox.callback_webhook_url"
          />
        </div>
        <div class="medium-6 small-offset-3">
          <woot-code
            v-if="isASmsInbox"
            lang="html"
            :script="currentInbox.callback_webhook_url"
          />
        </div>
        <div class="medium-6 small-offset-3">
          <woot-code
            v-if="isAEmailInbox"
            lang="html"
            :script="currentInbox.forward_to_email"
          />
        </div>
        <div class="footer">
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
import configMixin from 'shared/mixins/configMixin';
import EmptyState from '../../../../components/widgets/EmptyState';

export default {
  components: {
    EmptyState,
  },
  mixins: [configMixin],
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
    isALineInbox() {
      return this.currentInbox.channel_type === 'Channel::Line';
    },
    isASmsInbox() {
      return this.currentInbox.channel_type === 'Channel::Sms';
    },
    isAWhatsappWhatsappCloudInbox() {
      return (
        this.currentInbox.channel_type === 'Channel::Whatsapp' &&
        this.currentInbox.provider === 'whatsapp_cloud'
      );
    },
    message() {
      if (this.isATwilioInbox) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.ADD.TWILIO.API_CALLBACK.SUBTITLE'
        )}`;
      }

      if (this.isASmsInbox) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.ADD.SMS.BANDWIDTH.API_CALLBACK.SUBTITLE'
        )}`;
      }

      if (this.isALineInbox) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.SUBTITLE'
        )}`;
      }

      if (this.isAWhatsappWhatsappCloudInbox) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.SUBTITLE'
        )}`;
      }

      if (this.isAEmailInbox) {
        return this.$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.FINISH_MESSAGE');
      }

      if (this.currentInbox.web_widget_script) {
        return this.$t('INBOX_MGMT.FINISH.WEBSITE_SUCCESS');
      }

      return this.$t('INBOX_MGMT.FINISH.MESSAGE');
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
