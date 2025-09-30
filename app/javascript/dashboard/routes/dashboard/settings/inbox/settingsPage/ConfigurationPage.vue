<script>
import { useAlert } from 'dashboard/composables';
import inboxMixin from 'shared/mixins/inboxMixin';
import SettingsSection from '../../../../../components/SettingsSection.vue';
import ImapSettings from '../ImapSettings.vue';
import SmtpSettings from '../SmtpSettings.vue';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import NextButton from 'dashboard/components-next/button/Button.vue';
import WhatsappReauthorize from '../channels/whatsapp/Reauthorize.vue';

export default {
  components: {
    SettingsSection,
    ImapSettings,
    SmtpSettings,
    NextButton,
    WhatsappReauthorize,
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
      isRequestingReauthorization: false,
      isSyncingTemplates: false,
      // Apple Messages for Business OAuth2 and Apple Pay settings
      oauth2Providers: {
        google: { enabled: false, clientId: '', clientSecret: '' },
        linkedin: { enabled: false, clientId: '', clientSecret: '' },
        facebook: { enabled: false, clientId: '', clientSecret: '' },
      },
      paymentSettings: {
        applePayEnabled: false,
        merchantIdentifier: '',
        merchantDomain: '',
        supportedNetworks: ['visa', 'masterCard', 'amex'],
        countryCode: 'US',
        currencyCode: 'USD',
      },
      paymentProcessors: {
        stripe: { enabled: false, publishableKey: '', secretKey: '' },
        square: { enabled: false, applicationId: '', accessToken: '' },
        braintree: {
          enabled: false,
          merchantId: '',
          publicKey: '',
          privateKey: '',
        },
      },
      // iMessage Apps configuration
      imessageApps: [
        {
          id: 'app_1',
          name: 'Custom Business App',
          app_id: 'com.example.businessapp',
          bid: 'com.apple.messages.MSMessageExtensionBalloonPlugin:com.example.businessapp:extension',
          version: '1.0',
          url: '',
          description: 'Default business integration app',
          enabled: false,
          use_live_layout: true,
          app_data: {},
          images: []
        }
      ],
      updateTimeout: null,
      hasUnsavedChanges: false,
    };
  },
  validations: {
    whatsAppInboxAPIKey: { required },
  },
  computed: {
    isEmbeddedSignupWhatsApp() {
      return this.inbox.provider_config?.source === 'embedded_signup';
    },
    whatsappAppId() {
      return window.chatwootConfig?.whatsappAppId;
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
  beforeUnmount() {
    // Auto-save on component unmount (when navigating away)
    if (this.isAnAppleMessagesForBusinessChannel) {
      this.updateAppleMessagesSettings();
    }
  },
  methods: {
    setDefaults() {
      this.hmacMandatory = this.inbox.hmac_mandatory || false;

      // Load Apple Messages for Business settings
      if (this.isAnAppleMessagesForBusinessChannel) {
        // Initialize OAuth2 providers with proper structure and safe defaults
        const oauth2Data = this.inbox.oauth2_providers || {};
        this.oauth2Providers = {
          google: {
            enabled: oauth2Data.google?.enabled || false,
            clientId: oauth2Data.google?.clientId || '',
            clientSecret: oauth2Data.google?.clientSecret || '',
          },
          linkedin: {
            enabled: oauth2Data.linkedin?.enabled || false,
            clientId: oauth2Data.linkedin?.clientId || '',
            clientSecret: oauth2Data.linkedin?.clientSecret || '',
          },
          facebook: {
            enabled: oauth2Data.facebook?.enabled || false,
            clientId: oauth2Data.facebook?.clientId || '',
            clientSecret: oauth2Data.facebook?.clientSecret || '',
          },
        };

        // Initialize payment settings with safe defaults
        const paymentData = this.inbox.payment_settings || {};
        this.paymentSettings = {
          applePayEnabled: paymentData.applePayEnabled || false,
          merchantIdentifier: paymentData.merchantIdentifier || '',
          merchantDomain: paymentData.merchantDomain || '',
          supportedNetworks: paymentData.supportedNetworks || [
            'visa',
            'masterCard',
            'amex',
          ],
          countryCode: paymentData.countryCode || 'US',
          currencyCode: paymentData.currencyCode || 'USD',
        };

        // Initialize payment processors with safe defaults
        const processorsData = this.inbox.payment_processors || {};
        this.paymentProcessors = {
          stripe: {
            enabled: processorsData.stripe?.enabled || false,
            publishableKey: processorsData.stripe?.publishableKey || '',
            secretKey: processorsData.stripe?.secretKey || '',
          },
          square: {
            enabled: processorsData.square?.enabled || false,
            applicationId: processorsData.square?.applicationId || '',
            accessToken: processorsData.square?.accessToken || '',
          },
          braintree: {
            enabled: processorsData.braintree?.enabled || false,
            merchantId: processorsData.braintree?.merchantId || '',
            publicKey: processorsData.braintree?.publicKey || '',
            privateKey: processorsData.braintree?.privateKey || '',
          },
        };

        // Initialize iMessage apps with safe defaults
        const imessageAppsData = this.inbox.imessage_apps || [];
        // Only initialize if we don't have any data yet (first load)
        if (this.imessageApps.length === 0) {
          this.imessageApps = imessageAppsData.length > 0 ? imessageAppsData : [
            {
              id: 'app_1',
              name: 'Custom Business App',
              app_id: 'com.example.businessapp',
              bid: 'com.apple.messages.MSMessageExtensionBalloonPlugin:com.example.businessapp:extension',
              version: '1.0',
              url: '',
              description: 'Default business integration app',
              enabled: false,
              use_live_layout: true,
              app_data: {},
              images: []
            }
          ];
        } else if (imessageAppsData.length > 0) {
          // If we have saved data and current data, use the saved data from server
          this.imessageApps = imessageAppsData;
        }
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
    async updateAppleMessagesSettings() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            oauth2_providers: this.oauth2Providers,
            payment_settings: this.paymentSettings,
            payment_processors: this.paymentProcessors,
            imessage_apps: this.imessageApps,
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        this.hasUnsavedChanges = false;
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },

    // Track changes without auto-saving
    debouncedUpdate() {
      this.hasUnsavedChanges = true;
    },

    // iMessage Apps Management
    addImessageApp() {
      const newApp = {
        id: `app_${Date.now()}`,
        name: '',
        app_id: '',
        bid: '',
        version: '1.0',
        url: '',
        description: '',
        enabled: false,
        use_live_layout: true,
        app_data: {},
        images: []
      };
      this.imessageApps.push(newApp);
    },

    removeImessageApp(index) {
      if (this.imessageApps.length > 1) {
        this.imessageApps.splice(index, 1);
        this.updateAppleMessagesSettings();
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
  <div v-else-if="isAWhatsAppChannel && !isATwilioChannel">
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
            <p class="text-sm text-slate-600">
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
  <div v-else-if="isAnAppleMessagesForBusinessChannel" class="mx-8">
    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.APPLE_MESSAGES_MSP_TITLE')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.APPLE_MESSAGES_MSP_SUBTITLE')"
    >
      <woot-code :script="inbox.msp_id" />
    </SettingsSection>

    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.APPLE_MESSAGES_BUSINESS_ID_TITLE')"
      :sub-title="
        $t('INBOX_MGMT.SETTINGS_POPUP.APPLE_MESSAGES_BUSINESS_ID_SUBTITLE')
      "
    >
      <woot-code :script="inbox.business_id" />
    </SettingsSection>

    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.APPLE_MESSAGES_WEBHOOK_TITLE')"
      :sub-title="
        $t('INBOX_MGMT.SETTINGS_POPUP.APPLE_MESSAGES_WEBHOOK_SUBTITLE')
      "
    >
      <woot-code :script="inbox.webhook_url" />
    </SettingsSection>

    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.APPLE_MESSAGES_SECRET_TITLE')"
      :sub-title="
        $t('INBOX_MGMT.SETTINGS_POPUP.APPLE_MESSAGES_SECRET_SUBTITLE')
      "
    >
      <woot-code :script="inbox.secret" />
    </SettingsSection>

    <!-- OAuth2 Authentication Settings -->
    <SettingsSection
      :title="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.TITLE')"
      :sub-title="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.DESC')"
    >
      <div class="space-y-6">
        <!-- Google OAuth2 -->
        <div class="bg-slate-50 p-4 rounded-lg">
          <div class="flex items-center space-x-3 mb-4">
            <input
              id="google-oauth-enabled"
              v-model="oauth2Providers.google.enabled"
              type="checkbox"
              class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
              @change="updateAppleMessagesSettings"
            />
            <label
              for="google-oauth-enabled"
              class="text-sm font-medium text-gray-900"
            >
              {{
                $t(
                  'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.GOOGLE_ENABLED'
                )
              }}
            </label>
          </div>
          <div
            v-if="oauth2Providers.google?.enabled"
            class="grid grid-cols-1 md:grid-cols-2 gap-4"
          >
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                {{
                  $t(
                    'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.CLIENT_ID'
                  )
                }}
              </label>
              <input
                v-model="oauth2Providers.google.clientId"
                type="text"
                placeholder="Google OAuth2 Client ID"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                @blur="updateAppleMessagesSettings"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                {{
                  $t(
                    'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.CLIENT_SECRET'
                  )
                }}
              </label>
              <input
                v-model="oauth2Providers.google.clientSecret"
                type="password"
                placeholder="Google OAuth2 Client Secret"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                @blur="updateAppleMessagesSettings"
              />
            </div>
          </div>
        </div>

        <!-- LinkedIn OAuth2 -->
        <div class="bg-slate-50 p-4 rounded-lg">
          <div class="flex items-center space-x-3 mb-4">
            <input
              id="linkedin-oauth-enabled"
              v-model="oauth2Providers.linkedin.enabled"
              type="checkbox"
              class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
              @change="updateAppleMessagesSettings"
            />
            <label
              for="linkedin-oauth-enabled"
              class="text-sm font-medium text-gray-900"
            >
              {{
                $t(
                  'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.LINKEDIN_ENABLED'
                )
              }}
            </label>
          </div>
          <div
            v-if="oauth2Providers.linkedin?.enabled"
            class="grid grid-cols-1 md:grid-cols-2 gap-4"
          >
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                {{
                  $t(
                    'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.CLIENT_ID'
                  )
                }}
              </label>
              <input
                v-model="oauth2Providers.linkedin.clientId"
                type="text"
                placeholder="LinkedIn OAuth2 Client ID"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                @blur="updateAppleMessagesSettings"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                {{
                  $t(
                    'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.CLIENT_SECRET'
                  )
                }}
              </label>
              <input
                v-model="oauth2Providers.linkedin.clientSecret"
                type="password"
                placeholder="LinkedIn OAuth2 Client Secret"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                @blur="updateAppleMessagesSettings"
              />
            </div>
          </div>
        </div>

        <!-- Facebook OAuth2 -->
        <div class="bg-slate-50 p-4 rounded-lg">
          <div class="flex items-center space-x-3 mb-4">
            <input
              id="facebook-oauth-enabled"
              v-model="oauth2Providers.facebook.enabled"
              type="checkbox"
              class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
              @change="updateAppleMessagesSettings"
            />
            <label
              for="facebook-oauth-enabled"
              class="text-sm font-medium text-gray-900"
            >
              {{
                $t(
                  'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.FACEBOOK_ENABLED'
                )
              }}
            </label>
          </div>
          <div
            v-if="oauth2Providers.facebook?.enabled"
            class="grid grid-cols-1 md:grid-cols-2 gap-4"
          >
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                {{
                  $t(
                    'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.CLIENT_ID'
                  )
                }}
              </label>
              <input
                v-model="oauth2Providers.facebook.clientId"
                type="text"
                placeholder="Facebook App ID"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                @blur="updateAppleMessagesSettings"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                {{
                  $t(
                    'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.OAUTH2.CLIENT_SECRET'
                  )
                }}
              </label>
              <input
                v-model="oauth2Providers.facebook.clientSecret"
                type="password"
                placeholder="Facebook App Secret"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                @blur="updateAppleMessagesSettings"
              />
            </div>
          </div>
        </div>
      </div>
    </SettingsSection>

    <!-- Apple Pay Settings -->
    <SettingsSection
      :title="$t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY.TITLE')"
      :sub-title="
        $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY.DESC')
      "
    >
      <div class="space-y-6">
        <div class="bg-green-50 p-4 rounded-lg">
          <div class="flex items-center space-x-3 mb-4">
            <input
              id="apple-pay-enabled"
              v-model="paymentSettings.applePayEnabled"
              type="checkbox"
              class="h-4 w-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
              @change="updateAppleMessagesSettings"
            />
            <label
              for="apple-pay-enabled"
              class="text-sm font-medium text-gray-900"
            >
              {{
                $t(
                  'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY.ENABLED'
                )
              }}
            </label>
          </div>

          <div v-if="paymentSettings.applePayEnabled" class="space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  {{
                    $t(
                      'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY.MERCHANT_IDENTIFIER'
                    )
                  }}
                </label>
                <input
                  v-model="paymentSettings.merchantIdentifier"
                  type="text"
                  placeholder="merchant.com.yourcompany"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                  @blur="updateAppleMessagesSettings"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  {{
                    $t(
                      'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY.MERCHANT_DOMAIN'
                    )
                  }}
                </label>
                <input
                  v-model="paymentSettings.merchantDomain"
                  type="text"
                  placeholder="yourcompany.com"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                  @blur="updateAppleMessagesSettings"
                />
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  {{
                    $t(
                      'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY.COUNTRY_CODE'
                    )
                  }}
                </label>
                <select
                  v-model="paymentSettings.countryCode"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                  @change="updateAppleMessagesSettings"
                >
                  <option value="US">United States (US)</option>
                  <option value="CA">Canada (CA)</option>
                  <option value="GB">United Kingdom (GB)</option>
                  <option value="AU">Australia (AU)</option>
                  <option value="JP">Japan (JP)</option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  {{
                    $t(
                      'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY.CURRENCY_CODE'
                    )
                  }}
                </label>
                <select
                  v-model="paymentSettings.currencyCode"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                  @change="updateAppleMessagesSettings"
                >
                  <option value="USD">US Dollar (USD)</option>
                  <option value="CAD">Canadian Dollar (CAD)</option>
                  <option value="GBP">British Pound (GBP)</option>
                  <option value="AUD">Australian Dollar (AUD)</option>
                  <option value="JPY">Japanese Yen (JPY)</option>
                </select>
              </div>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                {{
                  $t(
                    'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.APPLE_PAY.SUPPORTED_NETWORKS'
                  )
                }}
              </label>
              <div class="flex flex-wrap gap-3">
                <label class="flex items-center">
                  <input
                    v-model="paymentSettings.supportedNetworks"
                    type="checkbox"
                    value="visa"
                    class="mr-2 h-4 w-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
                    @change="updateAppleMessagesSettings"
                  />
                  Visa
                </label>
                <label class="flex items-center">
                  <input
                    v-model="paymentSettings.supportedNetworks"
                    type="checkbox"
                    value="masterCard"
                    class="mr-2 h-4 w-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
                    @change="updateAppleMessagesSettings"
                  />
                  Mastercard
                </label>
                <label class="flex items-center">
                  <input
                    v-model="paymentSettings.supportedNetworks"
                    type="checkbox"
                    value="amex"
                    class="mr-2 h-4 w-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
                    @change="updateAppleMessagesSettings"
                  />
                  American Express
                </label>
                <label class="flex items-center">
                  <input
                    v-model="paymentSettings.supportedNetworks"
                    type="checkbox"
                    value="discover"
                    class="mr-2 h-4 w-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
                    @change="updateAppleMessagesSettings"
                  />
                  Discover
                </label>
              </div>
            </div>
          </div>
        </div>
      </div>
    </SettingsSection>

    <!-- Payment Processors -->
    <SettingsSection
      v-if="paymentSettings.applePayEnabled"
      :title="
        $t(
          'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.TITLE'
        )
      "
      :sub-title="
        $t('INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.DESC')
      "
    >
      <div class="space-y-6">
        <!-- Stripe -->
        <div class="bg-purple-50 p-4 rounded-lg">
          <div class="flex items-center space-x-3 mb-4">
            <input
              id="stripe-enabled"
              v-model="paymentProcessors.stripe.enabled"
              type="checkbox"
              class="h-4 w-4 text-purple-600 border-gray-300 rounded focus:ring-purple-500"
              @change="updateAppleMessagesSettings"
            />
            <label
              for="stripe-enabled"
              class="text-sm font-medium text-gray-900"
            >
              {{
                $t(
                  'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.STRIPE_ENABLED'
                )
              }}
            </label>
          </div>
          <div
            v-if="paymentProcessors.stripe?.enabled"
            class="grid grid-cols-1 md:grid-cols-2 gap-4"
          >
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                {{
                  $t(
                    'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.PUBLISHABLE_KEY'
                  )
                }}
              </label>
              <input
                v-model="paymentProcessors.stripe.publishableKey"
                type="text"
                placeholder="pk_..."
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                @blur="updateAppleMessagesSettings"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                {{
                  $t(
                    'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.SECRET_KEY'
                  )
                }}
              </label>
              <input
                v-model="paymentProcessors.stripe.secretKey"
                type="password"
                placeholder="sk_..."
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                @blur="updateAppleMessagesSettings"
              />
            </div>
          </div>
        </div>

        <!-- Square -->
        <div class="bg-blue-50 p-4 rounded-lg">
          <div class="flex items-center space-x-3 mb-4">
            <input
              id="square-enabled"
              v-model="paymentProcessors.square.enabled"
              type="checkbox"
              class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
              @change="updateAppleMessagesSettings"
            />
            <label
              for="square-enabled"
              class="text-sm font-medium text-gray-900"
            >
              {{
                $t(
                  'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.SQUARE_ENABLED'
                )
              }}
            </label>
          </div>
          <div
            v-if="paymentProcessors.square?.enabled"
            class="grid grid-cols-1 md:grid-cols-2 gap-4"
          >
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                {{
                  $t(
                    'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.APPLICATION_ID'
                  )
                }}
              </label>
              <input
                v-model="paymentProcessors.square.applicationId"
                type="text"
                placeholder="Square Application ID"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                @blur="updateAppleMessagesSettings"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                {{
                  $t(
                    'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.ACCESS_TOKEN'
                  )
                }}
              </label>
              <input
                v-model="paymentProcessors.square.accessToken"
                type="password"
                placeholder="Square Access Token"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                @blur="updateAppleMessagesSettings"
              />
            </div>
          </div>
        </div>

        <!-- Braintree -->
        <div class="bg-yellow-50 p-4 rounded-lg">
          <div class="flex items-center space-x-3 mb-4">
            <input
              id="braintree-enabled"
              v-model="paymentProcessors.braintree.enabled"
              type="checkbox"
              class="h-4 w-4 text-yellow-600 border-gray-300 rounded focus:ring-yellow-500"
              @change="updateAppleMessagesSettings"
            />
            <label
              for="braintree-enabled"
              class="text-sm font-medium text-gray-900"
            >
              {{
                $t(
                  'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.BRAINTREE_ENABLED'
                )
              }}
            </label>
          </div>
          <div
            v-if="paymentProcessors.braintree?.enabled"
            class="grid grid-cols-1 md:grid-cols-3 gap-4"
          >
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                {{
                  $t(
                    'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.MERCHANT_ID'
                  )
                }}
              </label>
              <input
                v-model="paymentProcessors.braintree.merchantId"
                type="text"
                placeholder="Braintree Merchant ID"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-yellow-500"
                @blur="updateAppleMessagesSettings"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                {{
                  $t(
                    'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.PUBLIC_KEY'
                  )
                }}
              </label>
              <input
                v-model="paymentProcessors.braintree.publicKey"
                type="text"
                placeholder="Braintree Public Key"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-yellow-500"
                @blur="updateAppleMessagesSettings"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                {{
                  $t(
                    'INBOX_MGMT.ADD.APPLE_MESSAGES_FOR_BUSINESS.PAYMENT_PROCESSORS.PRIVATE_KEY'
                  )
                }}
              </label>
              <input
                v-model="paymentProcessors.braintree.privateKey"
                type="password"
                placeholder="Braintree Private Key"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-yellow-500"
                @blur="updateAppleMessagesSettings"
              />
            </div>
          </div>
        </div>
      </div>
    </SettingsSection>

    <!-- iMessage Apps Configuration -->
    <SettingsSection
      :title="'📱 iMessage Apps Configuration'"
      :sub-title="'Configure custom iMessage apps that agents can invoke in conversations. These apps must be installed on customer devices.'"
    >
      <div class="space-y-6">
        <!-- Apps List -->
        <div class="space-y-4">
          <div
            v-for="(app, index) in imessageApps"
            :key="app.id"
            class="bg-slate-50 p-4 rounded-lg border"
          >
            <div class="flex items-center justify-between mb-4">
              <div class="flex items-center space-x-3">
                <input
                  v-model="app.enabled"
                  type="checkbox"
                  class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                  @input="debouncedUpdate"
                />
                <h4 class="font-medium text-gray-900">
                  {{ app.name || `iMessage App ${index + 1}` }}
                </h4>
              </div>
              <button
                v-if="imessageApps.length > 1"
                @click="removeImessageApp(index)"
                class="text-red-500 hover:text-red-700 transition-colors"
              >
                <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z" />
                </svg>
              </button>
            </div>

            <div v-if="app.enabled" class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  App Name *
                </label>
                <input
                  v-model="app.name"
                  type="text"
                  placeholder="My Custom App"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  @input="debouncedUpdate"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  App ID *
                </label>
                <input
                  v-model="app.app_id"
                  type="text"
                  placeholder="com.example.myapp"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  @input="debouncedUpdate"
                />
              </div>

              <div class="md:col-span-2">
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Bundle Identifier (BID) *
                </label>
                <input
                  v-model="app.bid"
                  type="text"
                  placeholder="com.apple.messages.MSMessageExtensionBalloonPlugin:bundleId:extension"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  @input="debouncedUpdate"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Version
                </label>
                <input
                  v-model="app.version"
                  type="text"
                  placeholder="1.0"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  @input="debouncedUpdate"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  App URL (Optional)
                </label>
                <input
                  v-model="app.url"
                  type="url"
                  placeholder="https://example.com/app"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  @input="debouncedUpdate"
                />
              </div>

              <div class="md:col-span-2">
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Description
                </label>
                <textarea
                  v-model="app.description"
                  rows="2"
                  placeholder="Brief description of what this app does"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  @input="debouncedUpdate"
                />
              </div>

              <div class="md:col-span-2">
                <div class="flex items-center space-x-3">
                  <input
                    v-model="app.use_live_layout"
                    type="checkbox"
                    class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                    @input="debouncedUpdate"
                  />
                  <label class="text-sm text-gray-700">
                    Use Live Layout (recommended)
                  </label>
                </div>
                <p class="text-xs text-gray-500 mt-1">
                  Enables dynamic layout updates and better user experience
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Add New App Button -->
        <button
          @click="addImessageApp"
          type="button"
          class="w-full py-3 border-2 border-dashed border-gray-300 rounded-lg text-gray-500 hover:border-gray-400 hover:text-gray-600 transition-colors"
        >
          + Add iMessage App Configuration
        </button>

        <!-- Save Configuration Button -->
        <div class="flex justify-end mt-4">
          <button
            @click="updateAppleMessagesSettings"
            type="button"
            class="px-6 py-2 rounded-md transition-colors"
            :class="hasUnsavedChanges
              ? 'bg-orange-600 text-white hover:bg-orange-700'
              : 'bg-blue-600 text-white hover:bg-blue-700'"
          >
            {{ hasUnsavedChanges ? 'Save Pending Changes...' : 'Save iMessage Apps Configuration' }}
          </button>
        </div>
      </div>
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
