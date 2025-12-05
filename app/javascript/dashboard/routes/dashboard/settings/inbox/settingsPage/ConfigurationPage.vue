<script>
import { mapGetters } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import inboxMixin from 'shared/mixins/inboxMixin';
import SettingsSection from '../../../../../components/SettingsSection.vue';
import ImapSettings from '../ImapSettings.vue';
import SmtpSettings from '../SmtpSettings.vue';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import NextButton from 'dashboard/components-next/button/Button.vue';
import TextArea from 'next/textarea/TextArea.vue';
import WhatsappReauthorize from '../channels/whatsapp/Reauthorize.vue';
import { sanitizeAllowedDomains } from 'dashboard/helper/URLHelper';
import WhatsappWebForm from '../channels/whatsapp/WhatsappWebForm.vue';

export default {
  components: {
    SettingsSection,
    ImapSettings,
    SmtpSettings,
    NextButton,
    TextArea,
    WhatsappReauthorize,
    WhatsappWebForm,
  },
  mixins: [inboxMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  setup() {
    const { accountId } = useAccount();
    return { v$: useVuelidate(), accountId };
  },
  data() {
    return {
      hmacMandatory: false,
      whatsAppInboxAPIKey: '',
      isRequestingReauthorization: false,
      isSyncingTemplates: false,
      allowedDomains: '',
      isUpdatingAllowedDomains: false,
      features: {},
    };
  },
  validations: {
    whatsAppInboxAPIKey: { required },
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
    }),
    isEmbeddedSignupWhatsApp() {
      return this.inbox.provider_config?.source === 'embedded_signup';
    },
    whatsappAppId() {
      return window.chatwootConfig?.whatsappAppId;
    },
    isForwardingEnabled() {
      return !!this.inbox.forwarding_enabled;
    },
    featureInboundEmailEnabled() {
      return !!this.features?.inbound_emails;
    },
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
      this.allowedDomains = this.inbox.allowed_domains || '';

      try {
        const { features } = this.getAccount(this.accountId);
        this.features = features;
      } catch (error) {
        // Log error for debugging purposes
        // eslint-disable-next-line no-console
        console.error('Error fetching account features:', error);
      }
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
    async updateAllowedDomains() {
      this.isUpdatingAllowedDomains = true;
      const sanitizedAllowedDomains = sanitizeAllowedDomains(
        this.allowedDomains
      );
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            allowed_domains: sanitizedAllowedDomains,
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        this.allowedDomains = sanitizedAllowedDomains;
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      } finally {
        this.isUpdatingAllowedDomains = false;
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
    async handleReconfigure() {
      if (this.$refs.whatsappReauth) {
        await this.$refs.whatsappReauth.requestAuthorization();
      }
    },
    async syncTemplates() {
      this.isSyncingTemplates = true;
      try {
        await this.$store.dispatch('inboxes/syncTemplates', this.inbox.id);
        useAlert(
          this.$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_SUCCESS')
        );
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      } finally {
        this.isSyncingTemplates = false;
      }
    },
    async updateWhatsAppWebInbox(formData) {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            phone_number: formData.phone_number,
            provider_config: formData.provider_config,
          },
        };

        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
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
    <SettingsSection
      v-if="isATwilioWhatsAppChannel"
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_TITLE')"
      :sub-title="
        $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_SUBHEADER')
      "
    >
      <div class="flex justify-start items-center mt-2">
        <NextButton :disabled="isSyncingTemplates" @click="syncTemplates">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_BUTTON') }}
        </NextButton>
      </div>
    </SettingsSection>
  </div>
  <div v-else-if="isAVoiceChannel" class="mx-8">
    <SettingsSection
      :title="$t('INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_VOICE_URL_TITLE')"
      :sub-title="
        $t('INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_VOICE_URL_SUBTITLE')
      "
    >
      <woot-code :script="inbox.voice_call_webhook_url" lang="html" />
    </SettingsSection>
    <SettingsSection
      :title="$t('INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_STATUS_URL_TITLE')"
      :sub-title="
        $t('INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_STATUS_URL_SUBTITLE')
      "
    >
      <woot-code :script="inbox.voice_status_webhook_url" lang="html" />
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
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.ALLOWED_DOMAINS.TITLE')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.ALLOWED_DOMAINS.SUBTITLE')"
      >
        <div class="flex flex-col w-full max-w-3xl gap-4">
          <TextArea
            v-model="allowedDomains"
            :placeholder="
              $t('INBOX_MGMT.SETTINGS_POPUP.ALLOWED_DOMAINS.PLACEHOLDER')
            "
            auto-height
            min-height="8rem"
            class="w-full"
          />
          <div>
            <NextButton
              :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
              :is-loading="isUpdatingAllowedDomains"
              @click="updateAllowedDomains"
            />
          </div>
        </div>
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
        <div class="flex gap-2 items-center">
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
      <div class="flex gap-2 items-center">
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
    <div v-if="featureInboundEmailEnabled" class="mx-8">
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.FORWARD_EMAIL_TITLE')"
        :sub-title="
          isForwardingEnabled
            ? $t('INBOX_MGMT.SETTINGS_POPUP.FORWARD_EMAIL_SUB_TEXT')
            : ''
        "
      >
        <woot-code
          v-if="isForwardingEnabled"
          :script="inbox.forward_to_email"
        />
        <div
          v-else
          class="p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg"
        >
          <p class="text-sm text-yellow-800 dark:text-yellow-200 mb-0">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.FORWARD_EMAIL_NOT_CONFIGURED') }}
          </p>
        </div>
      </SettingsSection>
    </div>
    <ImapSettings :inbox="inbox" />
    <SmtpSettings v-if="inbox.imap_enabled" :inbox="inbox" />
  </div>
  <div v-else-if="isAWhatsAppCloudChannel">
    <div v-if="inbox.provider_config" class="mx-8">
      <!-- Embedded Signup Section -->
      <template v-if="isEmbeddedSignupWhatsApp">
        <SettingsSection
          v-if="whatsappAppId"
          :title="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_EMBEDDED_SIGNUP_TITLE')
          "
          :sub-title="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_EMBEDDED_SIGNUP_SUBHEADER')
          "
        >
          <div class="flex gap-4 items-center">
            <p class="text-sm text-n-slate-11">
              {{
                $t(
                  'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_EMBEDDED_SIGNUP_DESCRIPTION'
                )
              }}
            </p>
            <NextButton @click="handleReconfigure">
              {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_RECONFIGURE_BUTTON') }}
            </NextButton>
          </div>
        </SettingsSection>
      </template>

      <!-- Manual Setup Section -->
      <template v-else>
        <SettingsSection
          :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEBHOOK_TITLE')"
          :sub-title="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEBHOOK_SUBHEADER')
          "
        >
          <woot-code :script="inbox.provider_config.webhook_verify_token" />
        </SettingsSection>
        <SettingsSection
          :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_TITLE')"
          :sub-title="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_SUBHEADER')
          "
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
            class="flex flex-1 justify-between items-center mt-2 whatsapp-settings--content"
          >
            <woot-input
              v-model="whatsAppInboxAPIKey"
              type="text"
              class="flex-1 mr-2 [&>input]:!mb-0"
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
              {{
                $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_BUTTON')
              }}
            </NextButton>
          </div>
        </SettingsSection>
      </template>
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_TITLE')"
        :sub-title="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_SUBHEADER')
        "
      >
        <div class="flex justify-start items-center mt-2">
          <NextButton :disabled="isSyncingTemplates" @click="syncTemplates">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_BUTTON') }}
          </NextButton>
        </div>
      </SettingsSection>
    </div>
    <WhatsappReauthorize
      v-if="isEmbeddedSignupWhatsApp"
      ref="whatsappReauth"
      :inbox="inbox"
      class="hidden"
    />
  </div>
  <div v-else-if="isAWhatsAppWebChannel" class="mx-8">
    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB_SECTION_TITLE')"
      :sub-title="
        $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEB_SECTION_SUBHEADER')
      "
    >
      <WhatsappWebForm
        mode="edit"
        :inbox="inbox"
        :is-loading="false"
        @submit="updateWhatsAppWebInbox"
      />
    </SettingsSection>
  </div>
</template>

<style lang="scss" scoped>
.whatsapp-settings--content {
  ::v-deep input {
    margin-bottom: 0;
  }
}
</style>
