<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import router from '../../../../index';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Auth from 'dashboard/api/auth';

export default {
  components: {
    NextButton,
  },
  data() {
    return {
      fbSdkLoaded: false,
      isProcessing: false,
      processingMessage: '',
      authCodeReceived: false,
      currentStep: 'initial', // 'initial', 'auth_received', 'processing', 'completed'
      authCode: null,
      businessData: null, // Store business data when received
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
    isLoading() {
      return this.isProcessing || this.uiFlags.isCreating;
    },
    authHeaders() {
      if (Auth.hasAuthCookie()) {
        const {
          'access-token': accessToken,
          'token-type': tokenType,
          client,
          expiry,
          uid,
        } = Auth.getAuthData();
        return {
          'access-token': accessToken,
          'token-type': tokenType,
          client,
          expiry,
          uid,
        };
      }
      return {};
    },
  },
  mounted() {
    this.loadFacebookSdk();
    window.addEventListener('message', this.handleSignupMessage);
  },
  beforeUnmount() {
    window.removeEventListener('message', this.handleSignupMessage);
  },
  methods: {
    loadFacebookSdk() {
      if (window.FB) {
        this.fbSdkLoaded = true;
        return;
      }
      const script = document.createElement('script');
      script.src = 'https://connect.facebook.net/en_US/sdk.js';
      script.async = true;
      script.defer = true;
      script.onload = () => {
        window.FB.init({
          appId: window.chatwootConfig?.whatsappAppId,
          status: true,
          xfbml: true,
          version: window.chatwootConfig?.fbApiVersion || 'v21.0',
        });
        this.fbSdkLoaded = true;
      };
      document.body.appendChild(script);
    },

    launchEmbeddedSignup() {
      if (!window.FB) {
        this.loadFacebookSdk();
        setTimeout(() => this.launchEmbeddedSignup(), 1000);
        return;
      }

      this.currentStep = 'auth_processing';
      this.processingMessage = this.$t(
        'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.AUTH_PROCESSING'
      );

      // Following Facebook's embedded signup documentation
      window.FB.login(this.fbLoginCallback, {
        config_id: window.chatwootConfig?.whatsappConfigurationId,
        response_type: 'code',
        override_default_response_type: true,
        extras: {
          setup: {},
          featureType: '', // Leave empty for default flow
          sessionInfoVersion: '3',
        },
      });
    },

    fbLoginCallback(response) {
      if (response.authResponse && response.authResponse.code) {
        // Authorization code received from Facebook
        this.authCode = response.authResponse.code;
        this.authCodeReceived = true;
        this.currentStep = 'auth_received';
        this.processingMessage = this.$t(
          'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.WAITING_FOR_BUSINESS_INFO'
        );

        // Check if we already have business data and process immediately
        if (this.businessData) {
          this.completeSignupFlow(this.businessData);
        }
      } else if (response.error) {
        this.handleSignupError({ error: response.error });
      } else {
        this.currentStep = 'initial';
        this.isProcessing = false;
        useAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CANCELLED'));
      }
    },

    handleSignupMessage(event) {
      // Handle Facebook embedded signup message events
      try {
        const originUrl = new URL(event.origin);
        const allowedHosts = ['facebook.com', 'www.facebook.com'];
        if (!allowedHosts.includes(originUrl.hostname)) return;
      } catch (error) {
        // Invalid origin URL, reject the event
        return;
      }

      try {
        const data = JSON.parse(event.data);

        if (data.type === 'WA_EMBEDDED_SIGNUP') {
          this.handleEmbeddedSignupData(data);
        }
      } catch (error) {
        // Handle non-JSON messages silently
      }
    },

    async handleEmbeddedSignupData(data) {
      // Handle different embedded signup events per Facebook documentation
      if (data.event === 'FINISH') {
        // Facebook might send business data in different structures
        let businessData = data.data;

        // If data.data doesn't exist, try other possible structures
        if (!businessData) {
          businessData = data.business_data || data.details || data;
        }

        // Validate we have the required business information
        if (
          businessData &&
          (businessData.business_id || businessData.businessId) &&
          (businessData.waba_id || businessData.wabaId)
        ) {
          // Normalize the data structure to match our backend expectations
          const normalizedData = {
            business_id: businessData.business_id || businessData.businessId,
            waba_id: businessData.waba_id || businessData.wabaId,
            phone_number_id:
              businessData.phone_number_id ||
              businessData.phoneNumberId ||
              businessData.phone_id,
          };

          // Store business data
          this.businessData = normalizedData;
          // Check if we already have auth code and process immediately
          if (this.authCodeReceived && this.authCode) {
            await this.completeSignupFlow(normalizedData);
          } else {
            this.currentStep = 'waiting_for_auth';
            this.processingMessage = 'Waiting for authentication...';
          }
        } else {
          this.handleSignupError({
            error:
              'Invalid business data received from Facebook. Please try again.',
          });
        }
      } else if (data.event === 'CANCEL') {
        this.handleSignupCancellation(data);
      } else if (data.event === 'error') {
        this.handleSignupError({
          error: data.error_message || 'Signup error occurred',
          error_id: data.error_id,
          session_id: data.session_id,
        });
      }
    },

    async completeSignupFlow(businessData) {
      if (!this.authCodeReceived || !this.authCode) {
        this.handleSignupError({
          error: 'Authentication not completed. Please restart the process.',
        });
        return;
      }

      this.currentStep = 'processing';
      this.isProcessing = true;
      this.processingMessage = this.$t(
        'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.PROCESSING'
      );

      try {
        // Send both auth code and business info together (synchronous flow)
        const accountId = this.$store.getters.getCurrentAccountId;
        const response = await fetch('/whatsapp/embedded_signup', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document
              .querySelector('meta[name="csrf-token"]')
              ?.getAttribute('content'),
            ...this.authHeaders,
          },
          body: JSON.stringify({
            account_id: accountId,
            code: this.authCode,
            business_id: businessData.business_id,
            waba_id: businessData.waba_id,
            phone_number_id: businessData.phone_number_id,
          }),
        });

        const responseData = await response.json();

        if (response.ok) {
          // Clear the stored auth code for security
          this.authCode = null;

          // Handle synchronous success response
          this.handleSignupSuccess(responseData);
        } else {
          throw new Error(responseData.message || responseData.error);
        }
      } catch (error) {
        this.handleSignupError({ error: error.message });
      }
    },

    handleSignupCancellation(data) {
      this.currentStep = 'initial';
      this.isProcessing = false;
      this.authCodeReceived = false;

      let message = this.$t(
        'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CANCELLED'
      );
      if (data.data?.current_step) {
        message += ` (Step: ${data.data.current_step})`;
      }

      useAlert(message);
    },

    handleSignupSuccess(inboxData) {
      this.currentStep = 'completed';
      this.isProcessing = false;

      // Update the store with the new inbox data
      if (inboxData && inboxData.id) {
        // Add the new inbox to the store
        this.$store.commit('inboxes/ADD_INBOXES', inboxData);

        useAlert(this.$t('INBOX_MGMT.FINISH.MESSAGE'));

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: inboxData.id,
          },
        });
      } else {
        // Fallback if inbox data is not properly formatted
        useAlert('WhatsApp Business Account has been successfully configured');
        router.replace({
          name: 'settings_inbox_list',
        });
      }
    },

    handleSignupError(data) {
      this.currentStep = 'initial';
      this.isProcessing = false;
      this.authCodeReceived = false;

      const errorMessage =
        data.error ||
        data.message ||
        this.$t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE');
      useAlert(errorMessage);
    },

    resetSignupFlow() {
      this.currentStep = 'initial';
      this.isProcessing = false;
      this.authCodeReceived = false;
      this.processingMessage = '';
      this.authCode = null;
      this.businessData = null;
    },
  },
};
</script>

<template>
  <div class="flex flex-col">
    <!-- Processing State -->
    <div v-if="isProcessing" class="text-center py-8">
      <div class="mb-4">
        <div
          class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"
        />
      </div>
      <h3 class="text-lg font-medium text-gray-900 mb-2">
        {{ processingMessage }}
      </h3>
      <p class="text-gray-600">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.PROCESSING_DESC') }}
      </p>

      <!-- Show current step for better UX -->
      <div class="mt-4 text-sm text-gray-500">
        <span v-if="currentStep === 'auth_processing'">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.STEP_AUTH') }}
        </span>
        <span v-else-if="currentStep === 'auth_received'">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.STEP_BUSINESS') }}
        </span>
        <span v-else-if="currentStep === 'processing'">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.STEP_CREATING') }}
        </span>
      </div>
    </div>

    <!-- Initial Setup State -->
    <div v-else class="space-y-6">
      <div class="bg-blue-50 border border-blue-200 rounded-lg p-6">
        <h3 class="text-lg font-medium text-blue-900 mb-3">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.TITLE') }}
        </h3>
        <p class="text-blue-800 mb-4">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.DESC') }}
        </p>

        <div class="space-y-2 mb-6">
          <h4 class="font-medium text-blue-900">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.BENEFITS.TITLE') }}
          </h4>
          <ul class="space-y-1 text-blue-800">
            <li class="flex items-center">
              <span class="w-2 h-2 bg-blue-600 rounded-full mr-3" />
              {{
                $t(
                  'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.BENEFITS.EASY_SETUP'
                )
              }}
            </li>
            <li class="flex items-center">
              <span class="w-2 h-2 bg-blue-600 rounded-full mr-3" />
              {{
                $t(
                  'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.BENEFITS.SECURE_AUTH'
                )
              }}
            </li>
            <li class="flex items-center">
              <span class="w-2 h-2 bg-blue-600 rounded-full mr-3" />
              {{
                $t(
                  'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.BENEFITS.AUTO_CONFIG'
                )
              }}
            </li>
          </ul>
        </div>

        <NextButton
          :disabled="!fbSdkLoaded"
          solid
          blue
          :label="$t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SUBMIT_BUTTON')"
          @click="launchEmbeddedSignup"
        />

        <p v-if="!fbSdkLoaded" class="text-sm text-gray-500 mt-2">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.LOADING_SDK') }}
        </p>
      </div>
    </div>
  </div>
</template>
