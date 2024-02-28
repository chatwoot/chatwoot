<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <empty-state
      :title="$t('INBOX_MGMT.FINISH.TITLE')"
      :message="message"
      :button-text="$t('INBOX_MGMT.FINISH.BUTTON_TEXT')"
    >
      <div class="w-full text-center">
        <div class="my-4 mx-auto max-w-[70%]">
          <woot-code
            v-if="currentInbox.web_widget_script"
            :script="currentInbox.web_widget_script"
          />
        </div>
        <div class="w-[50%] max-w-[50%] ml-[25%]">
          <woot-code
            v-if="isATwilioInbox"
            lang="html"
            :script="currentInbox.callback_webhook_url"
          />
        </div>
        <div v-if="isWhatsAppCloudInbox" class="w-[50%] max-w-[50%] ml-[25%]">
          <p class="text-slate-700 dark:text-slate-200 font-medium mt-8">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.WEBHOOK_URL') }}
          </p>
          <woot-code lang="html" :script="currentInbox.callback_webhook_url" />
          <p class="text-slate-700 dark:text-slate-200 font-medium mt-8">
            {{
              $t(
                'INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.WEBHOOK_VERIFICATION_TOKEN'
              )
            }}
          </p>
          <woot-code
            lang="html"
            :script="currentInbox.provider_config.webhook_verify_token"
          />
        </div>
        <div class="w-[50%] max-w-[50%] ml-[25%]">
          <woot-code
            v-if="isALineInbox"
            lang="html"
            :script="currentInbox.callback_webhook_url"
          />
        </div>
        <div class="w-[50%] max-w-[50%] ml-[25%]">
          <woot-code
            v-if="isASmsInbox"
            lang="html"
            :script="currentInbox.callback_webhook_url"
          />
        </div>
        <div
          v-if="isAEmailInbox && !currentInbox.provider"
          class="w-[50%] max-w-[50%] ml-[25%]"
        >
          <woot-code lang="html" :script="currentInbox.forward_to_email" />
        </div>
        <div class="flex justify-center gap-2 mt-4">
          <router-link
            class="button hollow primary rounded"
            :to="{
              name: 'settings_inbox_show',
              params: { inboxId: $route.params.inbox_id },
            }"
          >
            {{ $t('INBOX_MGMT.FINISH.MORE_SETTINGS') }}
          </router-link>
          <router-link
            class="button success rounded"
            :to="{
              name: 'inbox_dashboard',
              params: { inboxId: $route.params.inbox_id },
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
import EmptyState from '../../../../components/widgets/EmptyState.vue';

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
    isWhatsAppCloudInbox() {
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

      if (this.isWhatsAppCloudInbox) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.SUBTITLE'
        )}`;
      }

      if (this.isAEmailInbox && !this.currentInbox.provider) {
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
