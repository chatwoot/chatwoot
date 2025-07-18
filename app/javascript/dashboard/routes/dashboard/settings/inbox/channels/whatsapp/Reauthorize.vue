<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import InboxReconnectionRequired from '../../components/InboxReconnectionRequired.vue';
import whatsappChannel from 'dashboard/api/channel/whatsappChannel';
import { loadScript } from 'dashboard/helper/DOMHelpers';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const router = useRouter();
const showAlert = useAlert();

const isRequestingAuthorization = ref(false);
const isLoadingFacebook = ref(true);

const whatsappAppId = computed(() => window.chatwootConfig.whatsappAppId);
const whatsappConfigurationId = computed(
  () => window.chatwootConfig.whatsappConfigurationId
);

// Function declarations to fix ESLint errors
const initializeFacebook = () => {
  return new Promise(resolve => {
    window.fbAsyncInit = () => {
      window.FB.init({
        appId: whatsappAppId.value,
        autoLogAppEvents: true,
        xfbml: true,
        version: window.chatwootConfig?.whatsappApiVersion || 'v22.0',
      });
      window.FB.getLoginStatus(() => {
        resolve();
      });
    };
    if (window.FB) {
      window.fbAsyncInit();
    }
  });
};

const reauthorizeWhatsApp = async params => {
  isRequestingAuthorization.value = true;

  try {
    const response = await whatsappChannel.reauthorizeWhatsApp({
      inboxId: props.inbox.id,
      ...params,
    });

    if (response.data.success) {
      showAlert(t('INBOX.REAUTHORIZE.SUCCESS'));
      router.push({
        name: 'inbox_settings',
        params: { inboxId: props.inbox.id },
      });
    } else {
      showAlert(response.data.message || t('INBOX.REAUTHORIZE.ERROR'));
    }
  } catch (error) {
    showAlert(error.message || t('INBOX.REAUTHORIZE.ERROR'));
  } finally {
    isRequestingAuthorization.value = false;
  }
};

const handleEmbeddedSignupEvents = async (data, authCode) => {
  if (!data || typeof data !== 'object') {
    return;
  }

  // Handle different event types
  if (data.event === 'FINISH') {
    const businessData = data.data;

    if (
      businessData &&
      businessData.business_id &&
      businessData.waba_id &&
      businessData.phone_number_id
    ) {
      await reauthorizeWhatsApp({
        code: authCode,
        business_id: businessData.business_id,
        waba_id: businessData.waba_id,
        phone_number_id: businessData.phone_number_id,
      });
    } else {
      showAlert(
        t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.INVALID_BUSINESS_DATA')
      );
    }
  } else if (data.event === 'CANCEL') {
    isRequestingAuthorization.value = false;
    showAlert(t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CANCELLED'));
  } else if (data.event === 'error') {
    isRequestingAuthorization.value = false;
    showAlert(
      data.error_message ||
        t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SIGNUP_ERROR')
    );
  }
};

const startEmbeddedSignup = authCode => {
  const messageHandler = async event => {
    // Validate origin for security - following Facebook documentation
    if (!event.origin || !event.origin.endsWith('facebook.com')) {
      return;
    }

    try {
      let data;

      // Facebook sends the data as an object, not a string
      if (typeof event.data === 'string') {
        data = JSON.parse(event.data);
      } else if (typeof event.data === 'object' && event.data !== null) {
        data = event.data;
      } else {
        return;
      }

      // Handle the parsed data
      if (data.type === 'WA_EMBEDDED_SIGNUP') {
        handleEmbeddedSignupEvents(data, authCode);
      }
    } catch (error) {
      // Ignore message handling errors
    }
  };

  window.addEventListener('message', messageHandler);
};

const handleLoginAndReauthorize = () => {
  return new Promise((resolve, reject) => {
    try {
      // Validate required configuration
      if (!whatsappAppId.value) {
        throw new Error('WhatsApp App ID is required');
      }
      if (!whatsappConfigurationId.value) {
        throw new Error('WhatsApp Configuration ID is required');
      }

      window.FB.login(
        response => {
          if (response.authResponse) {
            const { authResponse } = response;
            const authCode = authResponse.code;

            if (authCode) {
              // Check if this is a reauthorization scenario where we already have the business data
              const existingConfig = props.inbox.provider_config;
              if (
                existingConfig &&
                existingConfig.business_account_id &&
                existingConfig.phone_number_id
              ) {
                reauthorizeWhatsApp({
                  code: authCode,
                  business_id: existingConfig.business_account_id,
                  waba_id: existingConfig.business_account_id,
                  phone_number_id: existingConfig.phone_number_id,
                });
                resolve();
              } else {
                startEmbeddedSignup(authCode);
                resolve();
              }
            } else {
              showAlert(
                t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.AUTH_NOT_COMPLETED')
              );
              reject(new Error('No auth code'));
            }
          } else {
            showAlert(t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CANCELLED'));
            reject(new Error('Login cancelled'));
          }
        },
        {
          config_id: whatsappConfigurationId.value,
          response_type: 'code',
          override_default_response_type: true,
          extras: {
            setup: {},
            featureType: '',
            sessionInfoVersion: '3',
          },
        }
      );
    } catch (error) {
      showAlert(error.message || t('INBOX.REAUTHORIZE.CONFIGURATION_ERROR'));
      reject(error);
    }
  });
};

const requestAuthorization = async () => {
  if (isLoadingFacebook.value) {
    showAlert(t('INBOX.REAUTHORIZE.LOADING_FACEBOOK'));
    return;
  }

  isRequestingAuthorization.value = true;
  try {
    await handleLoginAndReauthorize();
  } finally {
    // Reset only if not already processing through embedded signup
    if (!window.FB || !window.FB.getLoginStatus) {
      isRequestingAuthorization.value = false;
    }
  }
};

onMounted(async () => {
  try {
    // Validate required configuration
    if (!whatsappAppId.value) {
      showAlert(t('INBOX.REAUTHORIZE.WHATSAPP_APP_ID_MISSING'));
      return;
    }
    if (!whatsappConfigurationId.value) {
      showAlert(t('INBOX.REAUTHORIZE.WHATSAPP_CONFIG_ID_MISSING'));
      return;
    }

    // Load Facebook SDK and initialize
    await loadScript('https://connect.facebook.net/en_US/sdk.js', {
      async: true,
      defer: true,
      crossOrigin: 'anonymous',
    });
    await initializeFacebook();
  } catch (error) {
    showAlert(t('INBOX.REAUTHORIZE.FACEBOOK_LOAD_ERROR'));
  } finally {
    isLoadingFacebook.value = false;
  }
});

// Expose requestAuthorization function for parent components
defineExpose({
  requestAuthorization,
});
</script>

<template>
  <InboxReconnectionRequired
    class="mx-8 mt-5"
    :is-loading="isRequestingAuthorization"
    @reauthorize="requestAuthorization"
  />
</template>
