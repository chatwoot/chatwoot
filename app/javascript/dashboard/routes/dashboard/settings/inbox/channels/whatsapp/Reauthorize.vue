<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import InboxReconnectionRequired from '../../components/InboxReconnectionRequired.vue';
import whatsappChannel from 'dashboard/api/channel/whatsappChannel';
import {
  setupFacebookSdk,
  initWhatsAppEmbeddedSignup,
  createMessageHandler,
  isValidBusinessData,
} from './utils';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
  whatsappRegistrationIncomplete: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();

const isRequestingAuthorization = ref(false);
const isLoadingFacebook = ref(true);

const whatsappAppId = computed(() => window.chatwootConfig.whatsappAppId);
const whatsappConfigurationId = computed(
  () => window.chatwootConfig.whatsappConfigurationId
);

const actionLabel = computed(() => {
  if (props.whatsappRegistrationIncomplete) {
    return t('INBOX_MGMT.COMPLETE_REGISTRATION');
  }
  return '';
});

const description = computed(() => {
  if (props.whatsappRegistrationIncomplete) {
    return t('INBOX_MGMT.WHATSAPP_REGISTRATION_INCOMPLETE');
  }
  return '';
});

const reauthorizeWhatsApp = async params => {
  isRequestingAuthorization.value = true;

  try {
    const response = await whatsappChannel.reauthorizeWhatsApp({
      inboxId: props.inbox.id,
      ...params,
    });

    if (response.data.success) {
      useAlert(t('INBOX.REAUTHORIZE.SUCCESS'));
    } else {
      useAlert(response.data.message || t('INBOX.REAUTHORIZE.ERROR'));
    }
  } catch (error) {
    useAlert(error.message || t('INBOX.REAUTHORIZE.ERROR'));
  } finally {
    isRequestingAuthorization.value = false;
  }
};

const handleEmbeddedSignupEvents = async (data, authCode) => {
  if (!data || typeof data !== 'object') {
    return;
  }

  // Handle different event types
  if (
    data.event === 'FINISH' ||
    data.event === 'FINISH_WHATSAPP_BUSINESS_APP_ONBOARDING'
  ) {
    const businessData = data.data;

    // phone_number_id isn't required here: the backend resolves it from the WABA
    // (PhoneInfoService) when omitted, which coexistence completions sometimes do.
    if (isValidBusinessData(businessData)) {
      await reauthorizeWhatsApp({
        code: authCode,
        business_id: businessData.business_id,
        waba_id: businessData.waba_id,
        phone_number_id: businessData.phone_number_id || '',
        is_coexistence:
          data.event === 'FINISH_WHATSAPP_BUSINESS_APP_ONBOARDING',
      });
    } else {
      useAlert(
        t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.INVALID_BUSINESS_DATA')
      );
    }
  } else if (data.event === 'CANCEL') {
    isRequestingAuthorization.value = false;
    useAlert(t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CANCELLED'));
  } else if (data.event === 'error') {
    isRequestingAuthorization.value = false;
    useAlert(
      data.error_message ||
        t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SIGNUP_ERROR')
    );
  }
};

// FB.login's authCode and Meta's FINISH postMessage arrive independently and in no
// guaranteed order (see useWhatsappEmbeddedSignup.js), so the listener is registered
// before the auth code is known and buffers a FINISH event until setAuthCode() runs —
// otherwise a FINISH that arrives before FB.login resolves would be missed entirely.
const startEmbeddedSignup = () => {
  let authCode = null;
  let pendingEvent = null;
  let messageHandler;

  const process = () => {
    if (!authCode || !pendingEvent) return;
    handleEmbeddedSignupEvents(pendingEvent, authCode);
  };

  messageHandler = createMessageHandler(data => {
    if (
      data.event === 'FINISH' ||
      data.event === 'FINISH_WHATSAPP_BUSINESS_APP_ONBOARDING'
    ) {
      pendingEvent = data;
      process();
    } else {
      handleEmbeddedSignupEvents(data, authCode);
    }
  });
  window.addEventListener('message', messageHandler);

  return {
    setAuthCode: code => {
      authCode = code;
      process();
    },
    cleanup: () => window.removeEventListener('message', messageHandler),
  };
};

// The "existing config" reauth shortcut already trusts the stored business/phone IDs,
// so it only needs to know which FINISH variant occurred — same ordering guarantee as
// startEmbeddedSignup above, just without needing to buffer the event's business data.
const createFinishEventWaiter = () => {
  let listener;
  const promise = new Promise(resolve => {
    listener = createMessageHandler(data => {
      if (
        data?.event === 'FINISH' ||
        data?.event === 'FINISH_WHATSAPP_BUSINESS_APP_ONBOARDING'
      ) {
        window.removeEventListener('message', listener);
        resolve(data.event === 'FINISH_WHATSAPP_BUSINESS_APP_ONBOARDING');
      }
    });
    window.addEventListener('message', listener);
  });
  return {
    promise,
    cleanup: () => window.removeEventListener('message', listener),
  };
};

const handleLoginAndReauthorize = async () => {
  // Validate required configuration
  if (!whatsappAppId.value) {
    throw new Error('WhatsApp App ID is required');
  }
  if (!whatsappConfigurationId.value) {
    throw new Error('WhatsApp Configuration ID is required');
  }

  // Check if this is a reauthorization scenario where we already have the business data
  const existingConfig = props.inbox.provider_config;
  const hasExistingConfig = Boolean(
    existingConfig &&
      existingConfig.business_account_id &&
      existingConfig.phone_number_id
  );
  const finishWaiter = hasExistingConfig ? createFinishEventWaiter() : null;
  const embeddedSignup = hasExistingConfig ? null : startEmbeddedSignup();

  try {
    const authCode = await initWhatsAppEmbeddedSignup(
      whatsappConfigurationId.value
    );

    if (hasExistingConfig) {
      const isCoexistence = await finishWaiter.promise;
      await reauthorizeWhatsApp({
        code: authCode,
        business_id: existingConfig.business_account_id,
        waba_id: existingConfig.business_account_id,
        phone_number_id: existingConfig.phone_number_id,
        is_coexistence: isCoexistence,
      });
    } else {
      embeddedSignup.setAuthCode(authCode);
    }
  } catch (error) {
    finishWaiter?.cleanup();
    embeddedSignup?.cleanup();
    if (error.message === 'Login cancelled') {
      useAlert(t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CANCELLED'));
    } else {
      useAlert(
        error.message ||
          t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.AUTH_NOT_COMPLETED')
      );
    }
    throw error;
  }
};

const requestAuthorization = async () => {
  if (isLoadingFacebook.value) {
    useAlert(t('INBOX.REAUTHORIZE.LOADING_FACEBOOK'));
    return;
  }

  isRequestingAuthorization.value = true;
  try {
    await handleLoginAndReauthorize();
  } catch (error) {
    useAlert(error.message || t('INBOX.REAUTHORIZE.CONFIGURATION_ERROR'));
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
      useAlert(t('INBOX.REAUTHORIZE.WHATSAPP_APP_ID_MISSING'));
      return;
    }
    if (!whatsappConfigurationId.value) {
      useAlert(t('INBOX.REAUTHORIZE.WHATSAPP_CONFIG_ID_MISSING'));
      return;
    }

    // Load Facebook SDK and initialize
    await setupFacebookSdk(
      whatsappAppId.value,
      window.chatwootConfig?.whatsappApiVersion
    );
  } catch (error) {
    useAlert(t('INBOX.REAUTHORIZE.FACEBOOK_LOAD_ERROR'));
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
    class="mx-6"
    :is-loading="isRequestingAuthorization"
    :action-label="actionLabel"
    :description="description"
    @reauthorize="requestAuthorization"
  />
</template>
