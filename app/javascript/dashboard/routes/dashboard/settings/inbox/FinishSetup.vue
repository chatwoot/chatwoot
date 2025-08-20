<script>
import { ref } from 'vue';
import QRCode from 'qrcode';
import EmptyState from '../../../../components/widgets/EmptyState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import DuplicateInboxBanner from './channels/instagram/DuplicateInboxBanner.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
export default {
  components: {
    EmptyState,
    NextButton,
    DuplicateInboxBanner,
  },
  setup() {
    const whatsappQRCode = ref('');
    const messengerQRCode = ref('');
    const telegramQRCode = ref('');

    const generateWhatsAppQR = async phoneNumber => {
      try {
        const whatsappUrl = `https://wa.me/${phoneNumber}`;
        const qrDataUrl = await QRCode.toDataURL(whatsappUrl);
        whatsappQRCode.value = qrDataUrl;
      } catch (error) {
        // console.error('Error generating QR code:', error);
      }
    };

    const generateMessengerQR = async pageId => {
      try {
        const messengerUrl = `https://m.me/${pageId}`;
        const qrDataUrl = await QRCode.toDataURL(messengerUrl);
        messengerQRCode.value = qrDataUrl;
      } catch (error) {
        // console.error('Error generating QR code:', error);
      }
    };

    const generateTelegramQR = async botName => {
      try {
        const telegramUrl = `https://t.me/${botName}`;
        const qrDataUrl = await QRCode.toDataURL(telegramUrl);
        telegramQRCode.value = qrDataUrl;
      } catch (error) {
        // console.error('Error generating QR code:', error);
      }
    };

    return {
      whatsappQRCode,
      messengerQRCode,
      telegramQRCode,
      generateWhatsAppQR,
      generateMessengerQR,
      generateTelegramQR,
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
    isWhatsAppEmbeddedSignup() {
      return (
        this.isWhatsAppCloudInbox &&
        this.currentInbox.provider_config?.source === 'embedded_signup'
      );
    },
    isAFacebookInbox() {
      return this.currentInbox.channel_type === 'Channel::FacebookPage';
    },
    isATelegramInbox() {
      return this.currentInbox.channel_type === 'Channel::Telegram';
    },
    // If the inbox is a whatsapp cloud inbox and the source is not embedded signup, then show the webhook details
    shouldShowWhatsAppWebhookDetails() {
      return (
        this.isWhatsAppCloudInbox &&
        this.currentInbox.provider_config?.source !== 'embedded_signup'
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

      if (this.isWhatsAppCloudInbox && this.shouldShowWhatsAppWebhookDetails) {
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

      if (this.isWhatsAppEmbeddedSignup) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.FINISH.WHATSAPP_QR_INSTRUCTION'
        )}`;
      }
      return this.$t('INBOX_MGMT.FINISH.MESSAGE');
    },
  },
  watch: {
    currentInbox: {
      handler(inbox) {
        if (!inbox) return;

        // WhatsApp QR Code
        if (inbox.phone_number && this.isWhatsAppEmbeddedSignup) {
          this.generateWhatsAppQR(inbox.phone_number);
        }

        // Facebook Messenger QR Code
        if (inbox.page_id && this.isAFacebookInbox) {
          this.generateMessengerQR(inbox.page_id);
        }

        // Telegram QR Code - need to access channel data
        if (this.isATelegramInbox && inbox.channel?.bot_name) {
          this.generateTelegramQR(inbox.channel.bot_name);
        }
      },
      immediate: true,
      deep: true,
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
            v-if="isATwilioInbox"
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
        <div
          v-if="isWhatsAppEmbeddedSignup && whatsappQRCode"
          class="flex flex-col items-center mt-8"
        >
          <p class="mb-4 font-medium text-n-slate-11">
            {{ $t('INBOX_MGMT.FINISH.WHATSAPP_QR_MESSAGE') }}
          </p>
          <div class="p-4 bg-white rounded-lg border shadow-lg border-n-weak">
            <img
              :src="whatsappQRCode"
              alt="WhatsApp QR Code"
              class="w-48 h-48"
            />
          </div>
          <p class="mt-2 text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.FINISH.WHATSAPP_QR_INSTRUCTION') }}
          </p>
        </div>
        <div
          v-if="isAFacebookInbox && messengerQRCode"
          class="flex flex-col items-center mt-8"
        >
          <p class="mb-4 font-medium text-n-slate-11">
            {{ $t('INBOX_MGMT.FINISH.MESSENGER_QR_MESSAGE') }}
          </p>
          <div class="p-4 bg-white rounded-lg border shadow-lg border-n-weak">
            <img
              :src="messengerQRCode"
              alt="Messenger QR Code"
              class="w-48 h-48"
            />
          </div>
          <p class="mt-2 text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.FINISH.MESSENGER_QR_INSTRUCTION') }}
          </p>
        </div>
        <div
          v-if="isATelegramInbox && telegramQRCode"
          class="flex flex-col items-center mt-8"
        >
          <p class="mb-4 font-medium text-n-slate-11">
            {{ $t('INBOX_MGMT.FINISH.TELEGRAM_QR_MESSAGE') }}
          </p>
          <div class="p-4 bg-white rounded-lg border shadow-lg border-n-weak">
            <img
              :src="telegramQRCode"
              alt="Telegram QR Code"
              class="w-48 h-48"
            />
          </div>
          <p class="mt-2 text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.FINISH.TELEGRAM_QR_INSTRUCTION') }}
          </p>
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
