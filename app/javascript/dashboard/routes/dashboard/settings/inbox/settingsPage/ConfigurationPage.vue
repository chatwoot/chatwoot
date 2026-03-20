<script>
import { useAlert } from 'dashboard/composables';
import inboxMixin from 'shared/mixins/inboxMixin';
import SettingsSection from '../../../../../components/SettingsSection.vue';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import SettingsAccordion from 'dashboard/components-next/Settings/SettingsAccordion.vue';
import ImapSettings from '../ImapSettings.vue';
import SmtpSettings from '../SmtpSettings.vue';
import { useVuelidate } from '@vuelidate/core';
import NextButton from 'dashboard/components-next/button/Button.vue';
import TextArea from 'next/textarea/TextArea.vue';
import WhatsappReauthorize from '../channels/whatsapp/Reauthorize.vue';
import { sanitizeAllowedDomains, isValidURL } from 'dashboard/helper/URLHelper';
import { requiredIf } from '@vuelidate/validators';
import WhatsappLinkDeviceModal from '../components/WhatsappLinkDeviceModal.vue';
import InboxName from 'dashboard/components/widgets/InboxName.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

export default {
  components: {
    SettingsSection,
    SettingsFieldSection,
    SettingsToggleSection,
    SettingsAccordion,
    ImapSettings,
    SmtpSettings,
    NextButton,
    TextArea,
    WhatsappReauthorize,
    WhatsappLinkDeviceModal,
    InboxName,
    // eslint-disable-next-line vue/no-reserved-component-names
    Switch,
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
      allowMobileWebview: false,
      whatsAppInboxAPIKey: '',
      isRequestingReauthorization: false,
      isSyncingTemplates: false,
      allowedDomains: '',
      isUpdatingAllowedDomains: false,
      isSettingDefaults: false,
      baileysProviderUrl: '',
      showLinkDeviceModal: false,
      markAsRead: true,
      zapiInstanceId: '',
      zapiToken: '',
      zapiClientToken: '',
      zapiInstanceIdUpdate: '',
      zapiTokenUpdate: '',
      zapiClientTokenUpdate: '',
    };
  },
  validations() {
    return {
      whatsAppInboxAPIKey: {
        requiredIf: requiredIf(
          !this.isAWhatsAppBaileysChannel && !this.isAWhatsAppZapiChannel
        ),
      },
      baileysProviderUrl: { isValidURL: value => !value || isValidURL(value) },
      zapiInstanceIdUpdate: {},
      zapiTokenUpdate: {},
      zapiClientTokenUpdate: {},
    };
  },
  computed: {
    isEmbeddedSignupWhatsApp() {
      return this.inbox.provider_config?.source === 'embedded_signup';
    },
    whatsappAppId() {
      return window.chatwootConfig?.whatsappAppId;
    },
    isForwardingEnabled() {
      return !!this.inbox.forwarding_enabled;
    },
  },
  watch: {
    inbox() {
      this.setDefaults();
    },
    allowMobileWebview() {
      if (!this.isSettingDefaults) this.handleMobileWebviewFlag();
    },
    hmacMandatory() {
      if (!this.isSettingDefaults && this.isAWebWidgetInbox)
        this.handleHmacFlag();
    },
  },
  mounted() {
    this.setDefaults();
  },
  methods: {
    setDefaults() {
      this.isSettingDefaults = true;
      this.hmacMandatory = this.inbox.hmac_mandatory || false;
      this.allowMobileWebview = (
        this.inbox.selected_feature_flags || []
      ).includes('allow_mobile_webview');
      this.allowedDomains = this.inbox.allowed_domains || '';
      this.$nextTick(() => {
        this.isSettingDefaults = false;
      });
      this.baileysProviderUrl = this.inbox.provider_config?.provider_url ?? '';
      this.markAsRead = this.inbox.provider_config?.mark_as_read ?? true;
      this.zapiInstanceId = this.inbox.provider_config?.instance_id ?? '';
      this.zapiToken = this.inbox.provider_config?.token ?? '';
      this.zapiClientToken = this.inbox.provider_config?.client_token ?? '';
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
    async handleMobileWebviewFlag() {
      try {
        const currentFlags = this.inbox.selected_feature_flags || [];
        const selectedFlags = this.allowMobileWebview
          ? [...currentFlags, 'allow_mobile_webview']
          : currentFlags.filter(f => f !== 'allow_mobile_webview');

        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            selected_feature_flags: selectedFlags,
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
    async updateBaileysProviderUrl() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            provider_config: {
              ...this.inbox.provider_config,
              provider_url: this.baileysProviderUrl,
            },
          },
        };

        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    async updateWhatsAppMarkAsRead() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            provider_config: {
              ...this.inbox.provider_config,
              mark_as_read: this.markAsRead,
            },
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    onOpenLinkDeviceModal() {
      this.showLinkDeviceModal = true;
    },
    onCloseLinkDeviceModal() {
      this.showLinkDeviceModal = false;
    },
    async updateZapiInstanceId() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            provider_config: {
              ...this.inbox.provider_config,
              instance_id: this.zapiInstanceIdUpdate,
            },
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    async updateZapiToken() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            provider_config: {
              ...this.inbox.provider_config,
              token: this.zapiTokenUpdate,
            },
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    async updateZapiClientToken() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            provider_config: {
              ...this.inbox.provider_config,
              client_token: this.zapiClientTokenUpdate,
            },
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
  <div v-if="isATwilioChannel">
    <SettingsFieldSection
      :label="$t('INBOX_MGMT.ADD.TWILIO.API_CALLBACK.TITLE')"
      :help-text="$t('INBOX_MGMT.ADD.TWILIO.API_CALLBACK.SUBTITLE')"
    >
      <woot-code :script="inbox.callback_webhook_url" lang="html" />
    </SettingsFieldSection>
    <SettingsFieldSection
      v-if="isATwilioWhatsAppChannel"
      :label="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_TITLE')"
      :help-text="
        $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_SUBHEADER')
      "
    >
      <NextButton :disabled="isSyncingTemplates" @click="syncTemplates">
        {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_BUTTON') }}
      </NextButton>
    </SettingsFieldSection>
  </div>
  <div v-else-if="isAVoiceChannel">
    <SettingsFieldSection
      :label="$t('INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_VOICE_URL_TITLE')"
      :help-text="
        $t('INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_VOICE_URL_SUBTITLE')
      "
    >
      <woot-code :script="inbox.voice_call_webhook_url" lang="html" />
    </SettingsFieldSection>
    <SettingsFieldSection
      :label="$t('INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_STATUS_URL_TITLE')"
      :help-text="
        $t('INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_STATUS_URL_SUBTITLE')
      "
    >
      <woot-code :script="inbox.voice_status_webhook_url" lang="html" />
    </SettingsFieldSection>
  </div>

  <div v-else-if="isALineChannel">
    <SettingsFieldSection
      :label="$t('INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.TITLE')"
      :help-text="$t('INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.SUBTITLE')"
    >
      <woot-code :script="inbox.callback_webhook_url" lang="html" />
    </SettingsFieldSection>
  </div>
  <div v-else-if="isAWebWidgetInbox">
    <div class="space-y-4">
      <SettingsToggleSection
        :header="$t('INBOX_MGMT.SETTINGS_POPUP.ALLOWED_DOMAINS.TITLE')"
        :description="
          $t('INBOX_MGMT.SETTINGS_POPUP.ALLOWED_DOMAINS.DESCRIPTION')
        "
        hide-toggle
      >
        <template #editor>
          <TextArea
            v-model="allowedDomains"
            :placeholder="
              $t('INBOX_MGMT.SETTINGS_POPUP.ALLOWED_DOMAINS.PLACEHOLDER')
            "
            auto-height
            resize
            class="w-full [&>div]:!bg-transparent [&>div]:!border-none [&>div]:!border-0 [&>div]:px-0 [&>div]:pb-0 [&>div]:pt-0"
          />
          <div class="mt-3 flex justify-end">
            <NextButton
              :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
              :is-loading="isUpdatingAllowedDomains"
              @click="updateAllowedDomains"
            />
          </div>
        </template>
      </SettingsToggleSection>
      <SettingsToggleSection
        v-model="allowMobileWebview"
        :header="$t('INBOX_MGMT.SETTINGS_POPUP.ALLOW_MOBILE_WEBVIEW.LABEL')"
        :description="
          $t('INBOX_MGMT.SETTINGS_POPUP.ALLOW_MOBILE_WEBVIEW.SUBTITLE')
        "
      />
    </div>

    <SettingsAccordion
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.TITLE')"
      class="mt-6"
    >
      <SettingsToggleSection
        :header="$t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.TITLE')"
        :description="
          $t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.DESCRIPTION')
        "
        hide-toggle
      >
        <template #editor>
          <p class="mb-1 text-sm font-medium text-n-slate-12">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.SECRET_KEY') }}
          </p>
          <woot-code :script="inbox.hmac_token" />
          <p class="mt-1.5 text-label-small text-n-slate-11">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.HMAC_DESCRIPTION') }}
            <a
              target="_blank"
              rel="noopener noreferrer"
              href="https://www.chatwoot.com/docs/product/channels/live-chat/sdk/identity-validation/"
              class="text-n-blue-11 hover:underline text-label-small"
            >
              {{
                $t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.VIEW_DOCS')
              }}
            </a>
          </p>
        </template>
      </SettingsToggleSection>

      <SettingsToggleSection
        v-model="hmacMandatory"
        :header="
          $t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.REQUIRE_LABEL')
        "
        :description="
          $t(
            'INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.REQUIRE_DESCRIPTION'
          )
        "
      />
    </SettingsAccordion>
  </div>
  <div v-else-if="isAPIInbox">
    <SettingsFieldSection
      :label="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_IDENTIFIER')"
      :help-text="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_IDENTIFIER_SUB_TEXT')"
    >
      <woot-code :script="inbox.inbox_identifier" />
    </SettingsFieldSection>

    <SettingsFieldSection
      :label="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_VERIFICATION')"
      :help-text="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_DESCRIPTION')"
    >
      <woot-code :script="inbox.hmac_token" />
    </SettingsFieldSection>
    <SettingsFieldSection
      :label="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_VERIFICATION')"
      :help-text="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_DESCRIPTION')"
    >
      <div class="flex gap-2 items-center">
        <input
          id="hmacMandatory"
          v-model="hmacMandatory"
          type="checkbox"
          @change="handleHmacFlag"
        />
        <label for="hmacMandatory" class="text-body-main text-n-slate-12">
          {{ $t('INBOX_MGMT.EDIT.ENABLE_HMAC.LABEL') }}
        </label>
      </div>
    </SettingsFieldSection>
  </div>
  <div v-else-if="isAnEmailChannel">
    <div>
      <SettingsFieldSection
        :label="$t('INBOX_MGMT.SETTINGS_POPUP.FORWARD_EMAIL_TITLE')"
        :help-text="
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
          class="py-2 px-3 bg-n-amber-3 outline-n-amber-4 text-n-amber-11 outline outline-1 -outline-offset-1 rounded-xl"
        >
          <p class="text-body-para mb-0">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.FORWARD_EMAIL_NOT_CONFIGURED') }}
          </p>
        </div>
      </SettingsFieldSection>
    </div>
    <ImapSettings :inbox="inbox" />
    <SmtpSettings v-if="inbox.imap_enabled" :inbox="inbox" />
  </div>
  <div v-else-if="isAWhatsAppCloudChannel">
    <div v-if="inbox.provider_config">
      <!-- Embedded Signup Section -->
      <template v-if="isEmbeddedSignupWhatsApp">
        <SettingsFieldSection
          v-if="whatsappAppId"
          :label="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_EMBEDDED_SIGNUP_TITLE')
          "
          :help-text="`${$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_EMBEDDED_SIGNUP_SUBHEADER')} ${$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_EMBEDDED_SIGNUP_DESCRIPTION')}`"
        >
          <div class="flex flex-col gap-1 items-start">
            <NextButton @click="handleReconfigure">
              {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_RECONFIGURE_BUTTON') }}
            </NextButton>
          </div>
        </SettingsFieldSection>
      </template>

      <!-- Manual Setup Section -->
      <template v-else>
        <SettingsFieldSection
          :label="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEBHOOK_TITLE')"
          :help-text="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEBHOOK_SUBHEADER')
          "
        >
          <woot-code :script="inbox.provider_config.webhook_verify_token" />
        </SettingsFieldSection>
        <SettingsFieldSection
          :label="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_TITLE')"
          :help-text="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_SUBHEADER')
          "
        >
          <woot-code :script="inbox.provider_config.api_key" />
        </SettingsFieldSection>
        <SettingsFieldSection
          :label="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_TITLE')"
          :help-text="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_SUBHEADER')
          "
        >
          <div
            class="flex flex-1 justify-between items-center whatsapp-settings--content"
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
        </SettingsFieldSection>
      </template>
      <SettingsFieldSection
        :label="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_TITLE')"
        :help-text="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_SUBHEADER')
        "
      >
        <NextButton :disabled="isSyncingTemplates" @click="syncTemplates">
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TEMPLATES_SYNC_BUTTON') }}
        </NextButton>
      </SettingsFieldSection>
    </div>
    <WhatsappReauthorize
      v-if="isEmbeddedSignupWhatsApp"
      ref="whatsappReauth"
      :inbox="inbox"
      class="hidden"
    />
  </div>
  <div v-else-if="isAWhatsAppBaileysChannel">
    <WhatsappLinkDeviceModal
      v-if="showLinkDeviceModal"
      :show="showLinkDeviceModal"
      :on-close="onCloseLinkDeviceModal"
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
          <NextButton class="w-fit" @click="onOpenLinkDeviceModal">
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
            v-model="baileysProviderUrl"
            type="text"
            class="flex-1 mr-2 items-center"
            :placeholder="
              $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_PROVIDER_URL_PLACEHOLDER')
            "
            @keydown="v$.baileysProviderUrl.$touch"
          />
          <NextButton
            :disabled="
              v$.baileysProviderUrl.$invalid ||
              baileysProviderUrl === inbox.provider_config.provider_url
            "
            @click="updateBaileysProviderUrl"
          >
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_BUTTON') }}
          </NextButton>
        </div>
        <span v-if="v$.baileysProviderUrl.$error" class="text-red-400">
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
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MARK_AS_READ_TITLE')"
        :sub-title="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MARK_AS_READ_SUBHEADER')
        "
      >
        <div class="flex items-center gap-2">
          <Switch
            id="markAsRead"
            v-model="markAsRead"
            @change="updateWhatsAppMarkAsRead"
          />
          <label for="markAsRead">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MARK_AS_READ_LABEL') }}
          </label>
        </div>
      </SettingsSection>
    </div>
  </div>
  <div v-else-if="isAWhatsAppZapiChannel">
    <WhatsappLinkDeviceModal
      v-if="showLinkDeviceModal"
      :show="showLinkDeviceModal"
      :on-close="onCloseLinkDeviceModal"
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
          <NextButton class="w-fit" @click="onOpenLinkDeviceModal">
            {{
              $t(
                'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_MANAGE_PROVIDER_CONNECTION_BUTTON'
              )
            }}
          </NextButton>
        </div>
      </SettingsSection>

      <template v-if="inbox.provider_config.instance_id">
        <SettingsSection
          :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_INSTANCE_ID_TITLE')"
          :sub-title="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_INSTANCE_ID_SUBHEADER')
          "
        >
          <woot-code :script="inbox.provider_config.instance_id" />
        </SettingsSection>
      </template>
      <SettingsSection
        :title="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_INSTANCE_ID_UPDATE_TITLE')
        "
        :sub-title="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_INSTANCE_ID_UPDATE_SUBHEADER')
        "
      >
        <div
          class="flex items-center justify-between flex-1 mt-2 whatsapp-settings--content"
        >
          <woot-input
            v-model="zapiInstanceIdUpdate"
            type="text"
            class="flex-1 mr-2"
          />
          <NextButton
            :disabled="
              v$.zapiInstanceIdUpdate.$invalid ||
              (!inbox.provider_config.instance_id && !zapiInstanceIdUpdate) ||
              zapiInstanceIdUpdate === inbox.provider_config.instance_id
            "
            @click="updateZapiInstanceId"
          >
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_BUTTON') }}
          </NextButton>
        </div>
      </SettingsSection>

      <template v-if="inbox.provider_config.token">
        <SettingsSection
          :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TOKEN_TITLE')"
          :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TOKEN_SUBHEADER')"
        >
          <woot-code :script="inbox.provider_config.token" secure />
        </SettingsSection>
      </template>
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TOKEN_UPDATE_TITLE')"
        :sub-title="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_TOKEN_UPDATE_SUBHEADER')
        "
      >
        <div
          class="flex items-center justify-between flex-1 mt-2 whatsapp-settings--content"
        >
          <woot-input
            v-model="zapiTokenUpdate"
            type="password"
            class="flex-1 mr-2"
          />
          <NextButton
            :disabled="
              v$.zapiTokenUpdate.$invalid ||
              (!inbox.provider_config.token && !zapiTokenUpdate) ||
              zapiTokenUpdate === inbox.provider_config.token
            "
            @click="updateZapiToken"
          >
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_BUTTON') }}
          </NextButton>
        </div>
      </SettingsSection>

      <template v-if="inbox.provider_config.client_token">
        <SettingsSection
          :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_CLIENT_TOKEN_TITLE')"
          :sub-title="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_CLIENT_TOKEN_SUBHEADER')
          "
        >
          <woot-code :script="inbox.provider_config.client_token" secure />
        </SettingsSection>
      </template>
      <SettingsSection
        :title="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_CLIENT_TOKEN_UPDATE_TITLE')
        "
        :sub-title="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_CLIENT_TOKEN_UPDATE_SUBHEADER')
        "
      >
        <div
          class="flex items-center justify-between flex-1 mt-2 whatsapp-settings--content"
        >
          <woot-input
            v-model="zapiClientTokenUpdate"
            type="password"
            class="flex-1 mr-2"
          />
          <NextButton
            :disabled="
              v$.zapiClientTokenUpdate.$invalid ||
              (!inbox.provider_config.client_token && !zapiClientTokenUpdate) ||
              zapiClientTokenUpdate === inbox.provider_config.client_token
            "
            @click="updateZapiClientToken"
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
