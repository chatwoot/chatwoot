<script>
import EmptyState from '../../../../components/widgets/EmptyState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import DuplicateInboxBanner from './channels/instagram/DuplicateInboxBanner.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import WhatsappBaileysLinkDeviceModal from './components/WhatsappBaileysLinkDeviceModal.vue';

export default {
  components: {
    EmptyState,
    NextButton,
    DuplicateInboxBanner,
    WhatsappBaileysLinkDeviceModal,
  },
  data() {
    return {
      showBaileysLinkDeviceModal: false,
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
    isWhatsAppBaileysInbox() {
      return (
        this.currentInbox.channel_type === 'Channel::Whatsapp' &&
        this.currentInbox.provider === 'baileys'
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

      if (this.isWhatsAppBaileysInbox) {
        return `${this.$t('INBOX_MGMT.FINISH.MESSAGE')}. ${this.$t(
          'INBOX_MGMT.ADD.WHATSAPP.BAILEYS.SUBTITLE'
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
  methods: {
    onOpenBaileysLinkDeviceModal() {
      this.showBaileysLinkDeviceModal = true;
    },
    onCloseBaileysLinkDeviceModal() {
      this.showBaileysLinkDeviceModal = false;
    },
  },
};
</script>

<template>
  <div
    class="w-full h-full col-span-6 p-6 overflow-auto border border-b-0 rounded-t-lg border-n-weak bg-n-solid-1"
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
        <div v-if="isWhatsAppCloudInbox" class="w-[50%] max-w-[50%] ml-[25%]">
          <p class="mt-8 font-medium text-slate-700 dark:text-slate-200">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.WEBHOOK_URL') }}
          </p>
          <woot-code lang="html" :script="currentInbox.callback_webhook_url" />
          <p class="mt-8 font-medium text-slate-700 dark:text-slate-200">
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
        <div v-if="isWhatsAppBaileysInbox" class="w-[50%] max-w-[50%] ml-[25%]">
          <NextButton @click="onOpenBaileysLinkDeviceModal">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.BAILEYS.LINK_BUTTON') }}
          </NextButton>
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
    <WhatsappBaileysLinkDeviceModal
      v-if="showBaileysLinkDeviceModal"
      :show="showBaileysLinkDeviceModal"
      :on-close="onCloseBaileysLinkDeviceModal"
      :inbox="currentInbox"
      is-setup
    />
  </div>
</template>
