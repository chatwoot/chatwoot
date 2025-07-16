<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Icon from 'next/icon/Icon.vue';
import NextButton from 'next/button/Button.vue';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';
import { loadScript } from 'dashboard/helper/DOMHelpers';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';

const store = useStore();
const router = useRouter();
const { t } = useI18n();

// State
const fbSdkLoaded = ref(false);
const isProcessing = ref(false);
const processingMessage = ref('');
const authCodeReceived = ref(false);
const authCode = ref(null);
const businessData = ref(null);
const isAuthenticating = ref(false);

// Computed
const whatsappIconPath = '/assets/images/dashboard/channels/whatsapp.png';

const benefits = computed(() => [
  {
    key: 'EASY_SETUP',
    text: t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.BENEFITS.EASY_SETUP'),
  },
  {
    key: 'SECURE_AUTH',
    text: t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.BENEFITS.SECURE_AUTH'),
  },
  {
    key: 'AUTO_CONFIG',
    text: t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.BENEFITS.AUTO_CONFIG'),
  },
]);

const showLoader = computed(() => isAuthenticating.value || isProcessing.value);

// Error handling
const handleSignupError = data => {
  isProcessing.value = false;
  authCodeReceived.value = false;
  isAuthenticating.value = false;

  const errorMessage =
    data.error ||
    data.message ||
    t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE');
  useAlert(errorMessage);
};

const handleSignupCancellation = () => {
  isProcessing.value = false;
  authCodeReceived.value = false;
  isAuthenticating.value = false;
};

const handleSignupSuccess = inboxData => {
  isProcessing.value = false;
  isAuthenticating.value = false;

  if (inboxData && inboxData.id) {
    useAlert(t('INBOX_MGMT.FINISH.MESSAGE'));
    router.replace({
      name: 'settings_inboxes_add_agents',
      params: {
        page: 'new',
        inbox_id: inboxData.id,
      },
    });
  } else {
    useAlert(t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SUCCESS_FALLBACK'));
    router.replace({
      name: 'settings_inbox_list',
    });
  }
};

// Signup flow
const completeSignupFlow = async businessDataParam => {
  if (!authCodeReceived.value || !authCode.value) {
    handleSignupError({
      error: t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.AUTH_NOT_COMPLETED'),
    });
    return;
  }

  isProcessing.value = true;
  processingMessage.value = t(
    'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.PROCESSING'
  );

  try {
    const params = {
      code: authCode.value,
      business_id: businessDataParam.business_id,
      waba_id: businessDataParam.waba_id,
      phone_number_id: businessDataParam.phone_number_id,
    };

    const responseData = await store.dispatch(
      'inboxes/createWhatsAppEmbeddedSignup',
      params
    );

    authCode.value = null;
    handleSignupSuccess(responseData);
  } catch (error) {
    const errorMessage =
      parseAPIErrorResponse(error) ||
      t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE');
    handleSignupError({ error: errorMessage });
  }
};

const isValidBusinessData = businessDataLocal => {
  return (
    businessDataLocal &&
    businessDataLocal.business_id &&
    businessDataLocal.waba_id
  );
};

// Message handling
const handleEmbeddedSignupData = async data => {
  if (data.event === 'FINISH') {
    const businessDataLocal = data.data;

    if (isValidBusinessData(businessDataLocal)) {
      businessData.value = businessDataLocal;
      if (authCodeReceived.value && authCode.value) {
        await completeSignupFlow(businessDataLocal);
      } else {
        processingMessage.value = t(
          'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.WAITING_FOR_AUTH'
        );
      }
    } else {
      handleSignupError({
        error: t(
          'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.INVALID_BUSINESS_DATA'
        ),
      });
    }
  } else if (data.event === 'CANCEL') {
    handleSignupCancellation();
  } else if (data.event === 'error') {
    handleSignupError({
      error:
        data.error_message ||
        t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SIGNUP_ERROR'),
      error_id: data.error_id,
      session_id: data.session_id,
    });
  }
};

const fbLoginCallback = response => {
  if (response.authResponse && response.authResponse.code) {
    authCode.value = response.authResponse.code;
    authCodeReceived.value = true;
    processingMessage.value = t(
      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.WAITING_FOR_BUSINESS_INFO'
    );

    if (businessData.value) {
      completeSignupFlow(businessData.value);
    }
  } else if (response.error) {
    handleSignupError({ error: response.error });
  } else {
    isProcessing.value = false;
    isAuthenticating.value = false;
    useAlert(t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.CANCELLED'));
  }
};

const handleSignupMessage = event => {
  // Validate origin for security - following Facebook documentation
  // https://developers.facebook.com/docs/whatsapp/embedded-signup/implementation#step-3--add-embedded-signup-to-your-website
  if (!event.origin.endsWith('facebook.com')) return;

  // Parse and handle WhatsApp embedded signup events
  try {
    const data = JSON.parse(event.data);
    if (data.type === 'WA_EMBEDDED_SIGNUP') {
      handleEmbeddedSignupData(data);
    }
  } catch {
    // Ignore non-JSON or irrelevant messages
  }
};

const runFBInit = () => {
  window.FB.init({
    appId: window.chatwootConfig?.whatsappAppId,
    autoLogAppEvents: true,
    xfbml: true,
    version: window.chatwootConfig?.whatsappApiVersion || 'v22.0',
  });
  fbSdkLoaded.value = true;
};

const loadFacebookSdk = async () => {
  return loadScript('https://connect.facebook.net/en_US/sdk.js', {
    async: true,
    defer: true,
    crossOrigin: 'anonymous',
  });
};

const tryWhatsAppLogin = () => {
  isAuthenticating.value = true;
  processingMessage.value = t(
    'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.AUTH_PROCESSING'
  );

  window.FB.login(fbLoginCallback, {
    config_id: window.chatwootConfig?.whatsappConfigurationId,
    response_type: 'code',
    override_default_response_type: true,
    extras: {
      setup: {},
      featureType: '',
      sessionInfoVersion: '3',
    },
  });
};

const launchEmbeddedSignup = async () => {
  try {
    // Load SDK first if not loaded, following Facebook.vue pattern exactly
    await loadFacebookSdk();
    runFBInit(); // Initialize FB after loading

    // Now proceed with login
    tryWhatsAppLogin();
  } catch (error) {
    handleSignupError({
      error: t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SDK_LOAD_ERROR'),
    });
  }
};

// Lifecycle
const setupMessageListener = () => {
  window.addEventListener('message', handleSignupMessage);
};

const cleanupMessageListener = () => {
  window.removeEventListener('message', handleSignupMessage);
};

const initialize = () => {
  window.fbAsyncInit = runFBInit;
  setupMessageListener();
};

onMounted(() => {
  initialize();
});

onBeforeUnmount(() => {
  cleanupMessageListener();
});
</script>

<template>
  <div class="h-full">
    <LoadingState v-if="showLoader" :message="processingMessage" />

    <div v-else>
      <div class="flex flex-col items-start mb-6 text-start">
        <div class="flex justify-start mb-6">
          <div
            class="flex justify-center items-center w-12 h-12 rounded-full bg-n-alpha-2"
          >
            <img
              :src="whatsappIconPath"
              :alt="$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD')"
              class="object-contain w-8 h-8"
              draggable="false"
            />
          </div>
        </div>

        <h3 class="mb-2 text-base font-medium text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.TITLE') }}
        </h3>
        <p class="text-sm leading-[24px] text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.DESC') }}
        </p>
      </div>

      <div class="flex flex-col gap-2 mb-6">
        <div
          v-for="benefit in benefits"
          :key="benefit.key"
          class="flex gap-2 items-center text-sm text-n-slate-11"
        >
          <Icon icon="i-lucide-check" class="text-n-slate-11 size-4" />
          {{ benefit.text }}
        </div>
      </div>

      <div class="flex mt-4">
        <NextButton
          :disabled="isAuthenticating"
          :is-loading="isAuthenticating"
          faded
          slate
          class="w-full"
          @click="launchEmbeddedSignup"
        >
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.SUBMIT_BUTTON') }}
        </NextButton>
      </div>
    </div>
  </div>
</template>
