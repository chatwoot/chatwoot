<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import InboxReconnectionRequired from '../../components/InboxReconnectionRequired.vue';
import whatsappChannel from 'dashboard/api/channel/whatsappChannel';
import { loadScript } from 'dashboard/helper/scriptLoader';

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
        status: false,
        cookie: true,
        xfbml: true,
        version: 'v21.0',
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

const handleDialogClose = () => {
  const canvas = window.top || window;
  canvas.postMessage(
    {
      type: 'resize',
      height: 'auto',
    },
    '*'
  );
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
  const { type, params } = data;

  if (type === 'FACEBOOK_DIALOG_CLOSE' || type === 'CLOSE') {
    handleDialogClose();
    return;
  }

  if (type === 'WA_EMBEDDED_SIGNUP') {
    const { event } = params;

    if (event === 'FINISH') {
      const { phone_number_id, waba_id } = params.data;
      // Use the selected phone number ID or fall back to existing one if available
      const phoneNumberId =
        phone_number_id || props.inbox.provider_config?.phone_number_id;

      if (phoneNumberId && waba_id) {
        await reauthorizeWhatsApp({
          code: authCode,
          business_id: waba_id,
          waba_id,
          phone_number_id: phoneNumberId,
        });
      } else {
        showAlert(
          t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.INVALID_BUSINESS_DATA')
        );
      }
    }
  }
};

const startEmbeddedSignup = authCode => {
  const canvas = window.top || window;

  canvas.postMessage(
    {
      type: 'resize',
      height: 700,
    },
    '*'
  );

  const messageHandler = async event => {
    try {
      const data = JSON.parse(event.data);
      handleEmbeddedSignupEvents(data, authCode);
    } catch {
      // Not all messages are JSON, ignore parse errors
    }
  };

  window.addEventListener('message', messageHandler);
};

const handleLoginAndReauthorize = () => {
  return new Promise((resolve, reject) => {
    // Build pre-filled data according to Facebook documentation
    // https://developers.facebook.com/docs/whatsapp/embedded-signup/pre-filled-data/
    const extras = {
      setup: {},
      sessionInfoVersion: '3',
    };

    // Pre-fill business information if available
    if (props.inbox.name) {
      extras.setup.business = {
        name: props.inbox.name,
      };
    }

    // Pre-fill WhatsApp Business Account ID if available
    if (props.inbox.provider_config?.business_account_id) {
      extras.setup.whatsAppBusinessAccount = {
        id: props.inbox.provider_config.business_account_id,
      };
    }

    // Pre-fill phone profile information if available
    if (props.inbox.phone_number || props.inbox.name) {
      extras.setup.phone = {};

      // Display name for the WhatsApp profile
      if (props.inbox.name) {
        extras.setup.phone.displayName = props.inbox.name;
      }

      // Business description if available
      if (props.inbox.custom_attributes?.description) {
        extras.setup.phone.description =
          props.inbox.custom_attributes.description;
      }
    }

    // Pre-fill pre-verified phone if we have phone_number_id
    if (props.inbox.provider_config?.phone_number_id) {
      extras.setup.preVerifiedPhone = {
        ids: [props.inbox.provider_config.phone_number_id],
      };
    }

    window.FB.login(
      response => {
        if (response.authResponse) {
          const { authResponse } = response;
          const authCode = authResponse.code;

          if (authCode) {
            startEmbeddedSignup(authCode);
            resolve();
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
        extras,
      }
    );
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
  if (!whatsappAppId.value) {
    showAlert(t('INBOX.REAUTHORIZE.WHATSAPP_APP_ID_MISSING'));
    isLoadingFacebook.value = false;
    return;
  }

  try {
    await loadScript('//connect.facebook.net/en_US/sdk.js');
    await initializeFacebook();
  } catch (error) {
    showAlert(t('INBOX.REAUTHORIZE.FACEBOOK_LOAD_ERROR'));
  } finally {
    isLoadingFacebook.value = false;
  }
});
</script>

<template>
  <InboxReconnectionRequired
    class="mx-8 mt-5"
    :is-loading="isRequestingAuthorization"
    @reauthorize="requestAuthorization"
  />
</template>
