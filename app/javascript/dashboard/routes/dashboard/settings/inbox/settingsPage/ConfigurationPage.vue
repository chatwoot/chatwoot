<script>
import { useAlert } from 'dashboard/composables';
import inboxMixin from 'shared/mixins/inboxMixin';
import SettingsSection from '../../../../../components/SettingsSection.vue';
import ImapSettings from '../ImapSettings.vue';
import SmtpSettings from '../SmtpSettings.vue';
import { useVuelidate } from '@vuelidate/core';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { requiredIf } from '@vuelidate/validators';
import { isValidURL } from '../../../../../helper/URLHelper';
import WhatsappBaileysLinkDeviceModal from '../components/WhatsappBaileysLinkDeviceModal.vue';
import InboxName from '../../../../../components/widgets/InboxName.vue';

export default {
  components: {
    SettingsSection,
    ImapSettings,
    SmtpSettings,
    NextButton,
    WhatsappBaileysLinkDeviceModal,
    InboxName,
  },
  mixins: [inboxMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      hmacMandatory: false,
      whatsAppInboxAPIKey: '',
      whatsAppProviderUrl: '',
      showBaileysLinkDeviceModal: false,
    };
  },
  validations() {
    return {
      whatsAppInboxAPIKey: {
        requiredIf: requiredIf(!this.isAWhatsAppBaileysChannel),
      },
      whatsAppProviderUrl: { isValidURL: value => !value || isValidURL(value) },
    };
  },
  watch: {
    inbox() {
      this.setDefaults();
    },
  },
  mounted() {
    this.setDefaults();
  },
  methods: {
    setDefaults() {
      this.hmacMandatory = this.inbox.hmac_mandatory || false;
    },
    handleHmacFlag() {
      this.updateInbox();
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            hmac_mandatory: this.hmacMandatory,
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    async updateWhatsAppInboxAPIKey() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {},
        };

        payload.channel.provider_config = {
          ...this.inbox.provider_config,
          api_key: this.whatsAppInboxAPIKey,
        };

        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    async updateWhatsAppProviderUrl() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            provider_config: {
              ...this.inbox.provider_config,
              provider_url: this.whatsAppProviderUrl,
            },
          },
        };

        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
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
  <div v-if="isATwilioChannel" class="mx-8">
    <SettingsSection
      :title="$t('INBOX_MGMT.ADD.TWILIO.API_CALLBACK.TITLE')"
      :sub-title="$t('INBOX_MGMT.ADD.TWILIO.API_CALLBACK.SUBTITLE')"
    >
      <woot-code :script="inbox.callback_webhook_url" lang="html" />
    </SettingsSection>
  </div>
  <div v-else-if="isALineChannel" class="mx-8">
    <SettingsSection
      :title="$t('INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.TITLE')"
      :sub-title="$t('INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.SUBTITLE')"
    >
      <woot-code :script="inbox.callback_webhook_url" lang="html" />
    </SettingsSection>
  </div>
  <div v-else-if="isAWebWidgetInbox">
    <div class="mx-8">
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_HEADING')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_SUB_HEAD')"
      >
        <woot-code
          :script="inbox.web_widget_script"
          lang="html"
          :codepen-title="`${inbox.name} - Chatwoot Widget Test`"
          enable-code-pen
        />
      </SettingsSection>

      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_VERIFICATION')"
      >
        <woot-code :script="inbox.hmac_token" />
        <template #subTitle>
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.HMAC_DESCRIPTION') }}
          <a
            target="_blank"
            rel="noopener noreferrer"
            href="https://www.chatwoot.com/docs/product/channels/live-chat/sdk/identity-validation/"
          >
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.HMAC_LINK_TO_DOCS') }}
          </a>
        </template>
      </SettingsSection>
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_VERIFICATION')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_DESCRIPTION')"
      >
        <div class="flex items-center gap-2">
          <input
            id="hmacMandatory"
            v-model="hmacMandatory"
            type="checkbox"
            @change="handleHmacFlag"
          />
          <label for="hmacMandatory">
            {{ $t('INBOX_MGMT.EDIT.ENABLE_HMAC.LABEL') }}
          </label>
        </div>
      </SettingsSection>
    </div>
  </div>
  <div v-else-if="isAPIInbox" class="mx-8">
    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_IDENTIFIER')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_IDENTIFIER_SUB_TEXT')"
    >
      <woot-code :script="inbox.inbox_identifier" />
    </SettingsSection>

    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_VERIFICATION')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_DESCRIPTION')"
    >
      <woot-code :script="inbox.hmac_token" />
    </SettingsSection>
    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_VERIFICATION')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_DESCRIPTION')"
    >
      <div class="flex items-center gap-2">
        <input
          id="hmacMandatory"
          v-model="hmacMandatory"
          type="checkbox"
          @change="handleHmacFlag"
        />
        <label for="hmacMandatory">
          {{ $t('INBOX_MGMT.EDIT.ENABLE_HMAC.LABEL') }}
        </label>
      </div>
    </SettingsSection>
  </div>
  <div v-else-if="isAnEmailChannel">
    <div class="mx-8">
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.FORWARD_EMAIL_TITLE')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.FORWARD_EMAIL_SUB_TEXT')"
      >
        <woot-code :script="inbox.forward_to_email" />
      </SettingsSection>
    </div>
    <ImapSettings :inbox="inbox" />
    <SmtpSettings v-if="inbox.imap_enabled" :inbox="inbox" />
  </div>
  <div v-else-if="isAWhatsAppCloudChannel && inbox.provider_config">
    <div class="mx-8">
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEBHOOK_TITLE')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEBHOOK_SUBHEADER')"
      >
        <woot-code :script="inbox.provider_config.webhook_verify_token" />
      </SettingsSection>
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_TITLE')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_SUBHEADER')"
      >
        <woot-code :script="inbox.provider_config.api_key" />
      </SettingsSection>
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_TITLE')"
        :sub-title="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_SUBHEADER')
        "
      >
        <div
          class="flex items-center justify-between flex-1 mt-2 whatsapp-settings--content"
        >
          <woot-input
            v-model="whatsAppInboxAPIKey"
            type="text"
            class="flex-1 mr-2"
            :placeholder="
              $t(
                'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_PLACEHOLDER'
              )
            "
          />
          <NextButton
            :disabled="v$.whatsAppInboxAPIKey.$invalid"
            @click="updateWhatsAppInboxAPIKey"
          >
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_BUTTON') }}
          </NextButton>
        </div>
      </SettingsSection>
    </div>
  </div>
  <div v-else-if="isAWhatsAppBaileysChannel">
    <WhatsappBaileysLinkDeviceModal
      v-if="showBaileysLinkDeviceModal"
      :show="showBaileysLinkDeviceModal"
      :on-close="onCloseBaileysLinkDeviceModal"
      :inbox="inbox"
    />
    <div class="mx-8">
      <SettingsSection
        :title="
          $t(
            'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANAGE_PROVIDER_CONNECTION_TITLE'
          )
        "
        :sub-title="
          $t(
            'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANAGE_PROVIDER_CONNECTION_SUBHEADER'
          )
        "
      >
        <div class="flex flex-col gap-2">
          <InboxName
            :inbox="inbox"
            class="!text-lg !m-0"
            with-phone-number
            with-provider-connection-status
          />
          <NextButton class="w-fit" @click="onOpenBaileysLinkDeviceModal">
            {{
              $t(
                'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANAGE_PROVIDER_CONNECTION_BUTTON'
              )
            }}
          </NextButton>
        </div>
      </SettingsSection>
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_PROVIDER_URL_TITLE')"
        :sub-title="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_PROVIDER_URL_SUBHEADER')
        "
      >
        <div
          class="flex items-center justify-between flex-1 mt-2 whatsapp-settings--content"
        >
          <woot-input
            v-model="whatsAppProviderUrl"
            type="text"
            class="flex-1 mr-2 items-center"
            :placeholder="
              $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_PROVIDER_URL_PLACEHOLDER')
            "
            @keydown="v$.whatsAppProviderUrl.$touch"
          />
          <NextButton
            :disabled="
              v$.whatsAppProviderUrl.$invalid ||
              whatsAppProviderUrl === inbox.provider_config.provider_url
            "
            @click="updateWhatsAppProviderUrl"
          >
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_BUTTON') }}
          </NextButton>
        </div>
        <span v-if="v$.whatsAppProviderUrl.$error" class="text-red-400">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_PROVIDER_URL_ERROR') }}
        </span>
      </SettingsSection>
      <template v-if="inbox.provider_config.api_key">
        <SettingsSection
          :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_TITLE')"
          :sub-title="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_SUBHEADER')
          "
        >
          <woot-code :script="inbox.provider_config.api_key" />
        </SettingsSection>
      </template>
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_TITLE')"
        :sub-title="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_SUBHEADER')
        "
      >
        <div
          class="flex items-center justify-between flex-1 mt-2 whatsapp-settings--content"
        >
          <woot-input
            v-model="whatsAppInboxAPIKey"
            type="text"
            class="flex-1 mr-2"
            :placeholder="
              $t(
                'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_PLACEHOLDER'
              )
            "
          />
          <NextButton
            :disabled="
              v$.whatsAppInboxAPIKey.$invalid ||
              (!inbox.provider_config.api_key && !whatsAppInboxAPIKey) ||
              whatsAppInboxAPIKey === inbox.provider_config.api_key
            "
            @click="updateWhatsAppInboxAPIKey"
          >
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_BUTTON') }}
          </NextButton>
        </div>
      </SettingsSection>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.whatsapp-settings--content {
  ::v-deep input {
    margin-bottom: 0;
  }
}
</style>
