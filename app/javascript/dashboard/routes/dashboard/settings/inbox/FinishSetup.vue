<script>
import QRCode from 'qrcode';
import EmptyState from '../../../../components/widgets/EmptyState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import DuplicateInboxBanner from './channels/instagram/DuplicateInboxBanner.vue';
import inboxMixin from 'shared/mixins/inboxMixin';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

export default {
  components: {
    EmptyState,
    NextButton,
    DuplicateInboxBanner,
  },
  mixins: [inboxMixin],
  data() {
    return {
      qrCodes: {
        whatsapp: '',
        messenger: '',
        telegram: '',
      },
    };
  },
  computed: {
    currentInbox() {
      return this.$store.getters['inboxes/getInbox'](
        this.$route.params.inbox_id
      );
    },
    inbox() {
      return this.currentInbox;
    },
    // Check if a facebook inbox exists with the same instagram_id
    hasDuplicateInstagramInbox() {
      const instagramId = this.currentInbox.instagram_id;
      const facebookInbox =
        this.$store.getters['inboxes/getFacebookInboxByInstagramId'](
          instagramId
        );

      return (
        this.currentInbox.channel_type === INBOX_TYPES.INSTAGRAM &&
        facebookInbox
      );
    },
    // If the inbox is a whatsapp cloud inbox and the source is not embedded signup, then show the webhook details
    shouldShowWhatsAppWebhookDetails() {
      return (
        this.isAWhatsAppCloudChannel &&
        this.currentInbox.provider_config?.source !== 'embedded_signup'
      );
    },
    isWhatsAppEmbeddedSignup() {
      return (
        this.isAWhatsAppCloudChannel &&
        this.currentInbox.provider_config?.source === 'embedded_signup'
      );
    },
    message() {
      if (this.isATwilioChannel) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.ADD.TWILIO.API_CALLBACK.SUBTITLE'
        )}`;
      }

      if (this.isASmsInbox) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.ADD.SMS.BANDWIDTH.API_CALLBACK.SUBTITLE'
        )}`;
      }

      if (this.isALineChannel) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.SUBTITLE'
        )}`;
      }

      if (
        this.isAWhatsAppCloudChannel &&
        this.shouldShowWhatsAppWebhookDetails
      ) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.SUBTITLE'
        )}`;
      }

      if (this.isAnEmailChannel && !this.currentInbox.provider) {
        return this.$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.FINISH_MESSAGE');
      }

      if (this.currentInbox.web_widget_script) {
        return this.$t('INBOX_MGMT.FINISH.WEBSITE_SUCCESS');
      }

      if (this.isWhatsAppEmbeddedSignup) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.FINISH.WHATSAPP_QR_INSTRUCTION'
        )}`;
      }

      return this.$t('INBOX_MGMT.FINISH.MESSAGE');
    },
  },
  mounted() {
    this.generateQRCodes();
  },
  methods: {
    async generateQRCode(platform, identifier) {
      if (!identifier || !identifier.trim()) {
        // eslint-disable-next-line no-console
        console.warn(`Invalid identifier for ${platform} QR code`);
        return;
      }

      try {
        const platformUrls = {
          whatsapp: id => `https://wa.me/${id}`,
          messenger: id => `https://m.me/${id}`,
          telegram: id => `https://t.me/${id}`,
        };

        const url = platformUrls[platform](identifier);
        const qrDataUrl = await QRCode.toDataURL(url);
        this.qrCodes[platform] = qrDataUrl;
      } catch (error) {
        // eslint-disable-next-line no-console
        console.error(`Error generating ${platform} QR code:`, error);
        this.qrCodes[platform] = '';
      }
    },
    async generateQRCodes() {
      if (!this.currentInbox) return;

      // WhatsApp (both Cloud and Twilio)
      if (this.currentInbox.phone_number && this.isAWhatsAppChannel) {
        await this.generateQRCode('whatsapp', this.currentInbox.phone_number);
      }

      // Facebook Messenger
      if (this.currentInbox.page_id && this.isAFacebookInbox) {
        await this.generateQRCode('messenger', this.currentInbox.page_id);
      }

      // Telegram
      if (this.isATelegramChannel && this.currentInbox.bot_name) {
        await this.generateQRCode('telegram', this.currentInbox.bot_name);
      }
    },
  },
};
</script>

<template>
  <div
    class="overflow-auto col-span-6 p-6 w-full h-full rounded-t-lg border border-b-0 border-n-weak bg-n-solid-1"
  >
    <DuplicateInboxBanner
      v-if="hasDuplicateInstagramInbox"
      :content="$t('INBOX_MGMT.ADD.INSTAGRAM.NEW_INBOX_SUGGESTION')"
    />
    <EmptyState
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
            v-if="isATwilioChannel"
            lang="html"
            :script="currentInbox.callback_webhook_url"
          />
        </div>
        <div
          v-if="shouldShowWhatsAppWebhookDetails"
          class="w-[50%] max-w-[50%] ml-[25%]"
        >
          <p class="mt-8 font-medium text-slate-700 dark:text-slate-200">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.WEBHOOK_URL') }}
          </p>
          <woot-code lang="html" :script="currentInbox.callback_webhook_url" />
          <p class="mt-8 font-medium text-n-slate-11">
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
            v-if="isALineChannel"
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
          v-if="isAnEmailChannel && !currentInbox.provider"
          class="w-[50%] max-w-[50%] ml-[25%]"
        >
          <woot-code lang="html" :script="currentInbox.forward_to_email" />
        </div>
        <div
          v-if="isAWhatsAppChannel && qrCodes.whatsapp"
          class="flex flex-col items-center mt-8"
        >
          <p class="mt-2 text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.FINISH.WHATSAPP_QR_INSTRUCTION') }}
          </p>
          <div class="p-4 bg-white rounded-lg border shadow-lg border-n-weak">
            <img
              :src="qrCodes.whatsapp"
              alt="WhatsApp QR Code"
              class="w-48 h-48"
            />
          </div>
        </div>
        <div
          v-if="isAFacebookInbox && qrCodes.messenger"
          class="flex flex-col items-center mt-8"
        >
          <p class="mt-2 text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.FINISH.MESSENGER_QR_INSTRUCTION') }}
          </p>
          <div class="p-4 bg-white rounded-lg border shadow-lg border-n-weak">
            <img
              :src="qrCodes.messenger"
              alt="Messenger QR Code"
              class="w-48 h-48"
            />
          </div>
        </div>
        <div
          v-if="isATelegramChannel && qrCodes.telegram"
          class="flex flex-col items-center mt-8"
        >
          <p class="mt-2 text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.FINISH.TELEGRAM_QR_INSTRUCTION') }}
          </p>
          <div class="p-4 bg-white rounded-lg border shadow-lg border-n-weak">
            <img
              :src="qrCodes.telegram"
              alt="Telegram QR Code"
              class="w-48 h-48"
            />
          </div>
        </div>
        <div class="flex gap-2 justify-center mt-4">
          <router-link
            :to="{
              name: 'settings_inbox_show',
              params: { inboxId: $route.params.inbox_id },
            }"
          >
            <NextButton
              outline
              slate
              :label="$t('INBOX_MGMT.FINISH.MORE_SETTINGS')"
            />
          </router-link>
          <router-link
            :to="{
              name: 'inbox_dashboard',
              params: { inboxId: $route.params.inbox_id },
            }"
          >
            <NextButton
              solid
              teal
              :label="$t('INBOX_MGMT.FINISH.BUTTON_TEXT')"
            />
          </router-link>
        </div>
      </div>
    </EmptyState>
  </div>
</template>
