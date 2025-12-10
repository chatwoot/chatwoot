<script setup>
/* global axios */
import { computed, onMounted, onUnmounted, reactive, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import QRCode from 'qrcode';
import EmptyState from '../../../../components/widgets/EmptyState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import DuplicateInboxBanner from './channels/instagram/DuplicateInboxBanner.vue';
import EmailInboxFinish from './channels/emailChannels/EmailInboxFinish.vue';
import { useInbox } from 'dashboard/composables/useInbox';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

const { t } = useI18n();
const route = useRoute();
const store = useStore();

const qrCodes = reactive({
  whatsapp: '',
  messenger: '',
  telegram: '',
});

// WhatsApp Light QR state
const whapiLightQR = ref(null);
const whapiLightQRExpire = ref(null);
const whapiLightQRExpireTime = ref(null);
const whapiLightQRSecondsLeft = ref(null);
const isWaitingForQR = ref(false);
const isWhapiAuthenticated = ref(false);
const whapiQRError = ref(null);
const hasAttemptedQRFetch = ref(false); // Track if we've tried to fetch QR at least once
const qrPollInterval = ref(null);
const authPollInterval = ref(null);
const qrExpireInterval = ref(null);

const currentInbox = computed(() =>
  store.getters['inboxes/getInbox'](route.params.inbox_id)
);

// Use useInbox composable with the inbox ID
const {
  inbox,
  isAWhatsAppCloudChannel,
  isATwilioChannel,
  isASmsInbox,
  isALineChannel,
  isAnEmailChannel,
  isAWhatsAppChannel,
  isAFacebookInbox,
  isATelegramChannel,
  isATwilioWhatsAppChannel,
  isAWhatsAppLightChannel,
} = useInbox(route.params.inbox_id);

const hasDuplicateInstagramInbox = computed(() => {
  const instagramId = currentInbox.value.instagram_id;
  const facebookInbox =
    store.getters['inboxes/getFacebookInboxByInstagramId'](instagramId);

  return (
    currentInbox.value.channel_type === INBOX_TYPES.INSTAGRAM && facebookInbox
  );
});

const shouldShowWhatsAppWebhookDetails = computed(() => {
  return (
    isAWhatsAppCloudChannel.value &&
    currentInbox.value.provider_config?.source !== 'embedded_signup'
  );
});

const isWhatsAppEmbeddedSignup = computed(() => {
  return (
    isAWhatsAppCloudChannel.value &&
    currentInbox.value.provider_config?.source === 'embedded_signup'
  );
});

const message = computed(() => {
  if (isATwilioChannel.value) {
    return `${t('INBOX_MGMT.FINISH.MESSAGE')}. ${t(
      'INBOX_MGMT.ADD.TWILIO.API_CALLBACK.SUBTITLE'
    )}`;
  }

  if (isASmsInbox.value) {
    return `${t('INBOX_MGMT.FINISH.MESSAGE')}. ${t(
      'INBOX_MGMT.ADD.SMS.BANDWIDTH.API_CALLBACK.SUBTITLE'
    )}`;
  }

  if (isALineChannel.value) {
    return `${t('INBOX_MGMT.FINISH.MESSAGE')}. ${t(
      'INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.SUBTITLE'
    )}`;
  }

  if (isAWhatsAppCloudChannel.value && shouldShowWhatsAppWebhookDetails.value) {
    return `${t('INBOX_MGMT.FINISH.MESSAGE')}. ${t(
      'INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.SUBTITLE'
    )}`;
  }

  if (currentInbox.value.web_widget_script) {
    return t('INBOX_MGMT.FINISH.WEBSITE_SUCCESS');
  }

  if (isWhatsAppEmbeddedSignup.value) {
    return `${t('INBOX_MGMT.FINISH.MESSAGE')}. ${t(
      'INBOX_MGMT.FINISH.WHATSAPP_QR_INSTRUCTION'
    )}`;
  }

  if (isAWhatsAppLightChannel.value) {
    if (isWhapiAuthenticated.value) {
      return t('INBOX_MGMT.FINISH.MESSAGE');
    }
    return t('INBOX_MGMT.ADD.WHATSAPP_LIGHT.QR_DESC');
  }

  return t('INBOX_MGMT.FINISH.MESSAGE');
});

async function generateQRCode(platform, identifier) {
  if (!identifier || !identifier.trim()) {
    // eslint-disable-next-line no-console
    console.warn(`Invalid identifier for ${platform} QR code`);
    return;
  }

  try {
    const platformUrls = {
      whatsapp: id => `https://wa.me/${id}`,
      messenger: id => `https://m.me/${id}`,
      telegram: id => `https://t.me/${id}`,
    };

    const url = platformUrls[platform](identifier);
    const qrDataUrl = await QRCode.toDataURL(url);
    qrCodes[platform] = qrDataUrl;
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error(`Error generating ${platform} QR code:`, error);
    qrCodes[platform] = '';
  }
}

async function generateQRCodes() {
  if (!currentInbox.value) return;

  // WhatsApp (both Cloud and Twilio)
  if (currentInbox.value.phone_number && isAWhatsAppChannel.value) {
    // For Twilio WhatsApp, phone_number format is "whatsapp:+1234567890"
    // Extract just the phone number part for QR code generation
    const phoneNumber = currentInbox.value.phone_number.replace(
      'whatsapp:',
      ''
    );
    await generateQRCode('whatsapp', phoneNumber);
  }

  // Facebook Messenger
  if (currentInbox.value.page_id && isAFacebookInbox.value) {
    await generateQRCode('messenger', currentInbox.value.page_id);
  }

  // Telegram
  if (isATelegramChannel.value && currentInbox.value.bot_name) {
    await generateQRCode('telegram', currentInbox.value.bot_name);
  }
}

// WhatsApp Light QR functions
async function fetchWhapiLightQR() {
  if (!currentInbox.value || !isAWhatsAppLightChannel.value) return;

  hasAttemptedQRFetch.value = true;

  try {
    const response = await axios.get(
      `/api/v1/accounts/${route.params.accountId}/channels/whapi_channels/${route.params.inbox_id}/get_qr`
    );

    // Check if we received a waiting status response
    if (response.data.status === 'waiting') {
      isWaitingForQR.value = true;
      whapiQRError.value = null;
      return;
    }

    // Check if we have QR data
    if (response.data.qr) {
      const qrData = response.data.qr;

      // If QR status is waiting, show waiting state
      if (qrData.status === 'waiting') {
        isWaitingForQR.value = true;
        whapiQRError.value = null;
      } else {
        // QR code received with OK status
        whapiLightQR.value = qrData.base64;
        whapiLightQRExpire.value = qrData.expire;
        whapiLightQRSecondsLeft.value = qrData.expire;
        whapiLightQRExpireTime.value = Date.now() + qrData.expire * 1000;
        isWaitingForQR.value = false;
        whapiQRError.value = null;

        // Start countdown timer
        startQRExpireCountdown();
      }
    }
  } catch (error) {
    // If it's a 503 or waiting status, keep polling
    if (
      error.response?.status === 503 ||
      error.response?.data?.status === 'waiting'
    ) {
      isWaitingForQR.value = true;
    } else {
      whapiQRError.value =
        error.response?.data?.error || 'Failed to fetch QR code';
      isWaitingForQR.value = false;
      stopQRPolling();
    }
  }
}

async function checkWhapiAuthStatus() {
  if (
    !currentInbox.value ||
    !isAWhatsAppLightChannel.value ||
    isWhapiAuthenticated.value
  )
    return;

  try {
    const response = await axios.get(
      `/api/v1/accounts/${route.params.accountId}/channels/whapi_channels/${route.params.inbox_id}/qr_status`
    );

    // If status is 'QR' and we haven't fetched the QR yet, fetch it once
    if (response.data.status_text === 'QR' && !hasAttemptedQRFetch.value) {
      await fetchWhapiLightQR();
    }

    if (response.data.authenticated) {
      isWhapiAuthenticated.value = true;
      stopAuthPolling();
      stopQRExpireCountdown();
      await completeWhapiSetup();
    }
  } catch (error) {
    whapiQRError.value =
      error.response?.data?.error || 'Failed to check authentication status';
  }
}

async function completeWhapiSetup() {
  try {
    await axios.post(
      `/api/v1/accounts/${route.params.accountId}/channels/whapi_channels/${route.params.inbox_id}/complete_setup`
    );
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error completing Whapi setup:', error);
  }
}

function startQRPolling() {
  if (qrPollInterval.value) return;

  // Poll every 5 seconds for QR code
  qrPollInterval.value = setInterval(() => {
    fetchWhapiLightQR();
  }, 5000);

  // Fetch immediately
  fetchWhapiLightQR();
}

function stopQRPolling() {
  if (qrPollInterval.value) {
    clearInterval(qrPollInterval.value);
    qrPollInterval.value = null;
  }
}

function startAuthPolling() {
  if (authPollInterval.value) return;

  // Poll every 5 seconds for authentication status
  authPollInterval.value = setInterval(() => {
    checkWhapiAuthStatus();
  }, 5000);

  // Check immediately
  checkWhapiAuthStatus();
}

function stopAuthPolling() {
  if (authPollInterval.value) {
    clearInterval(authPollInterval.value);
    authPollInterval.value = null;
  }
}

function startQRExpireCountdown() {
  stopQRExpireCountdown();

  qrExpireInterval.value = setInterval(() => {
    if (!whapiLightQRExpireTime.value) {
      stopQRExpireCountdown();
      return;
    }

    const secondsLeft = Math.max(
      0,
      Math.floor((whapiLightQRExpireTime.value - Date.now()) / 1000)
    );
    whapiLightQRSecondsLeft.value = secondsLeft;

    if (secondsLeft === 0) {
      stopQRExpireCountdown();
      handleQRExpired();
    }
  }, 1000);
}

function stopQRExpireCountdown() {
  if (qrExpireInterval.value) {
    clearInterval(qrExpireInterval.value);
    qrExpireInterval.value = null;
  }
}

function handleQRExpired() {
  whapiLightQR.value = null;
  whapiLightQRExpireTime.value = null;
  whapiLightQRSecondsLeft.value = null;
}

async function regenerateQR() {
  whapiQRError.value = null;
  isWaitingForQR.value = true;
  hasAttemptedQRFetch.value = false; // Reset the flag to allow fetching again
  await fetchWhapiLightQR();
}

function cleanupWhapiPolling() {
  stopQRPolling();
  stopAuthPolling();
  stopQRExpireCountdown();
}

// Watch for currentInbox changes and regenerate QR codes when available
watch(
  currentInbox,
  newInbox => {
    if (newInbox) {
      generateQRCodes();

      // Start WhatsApp Light auth polling if it's a WhatsApp Light channel and not yet authenticated
      if (isAWhatsAppLightChannel.value && !isWhapiAuthenticated.value) {
        stopQRPolling();
        startAuthPolling();
      } else if (isAWhatsAppLightChannel.value && isWhapiAuthenticated.value) {
        // Ensure polling is stopped if already authenticated
        stopAuthPolling();
        stopQRExpireCountdown();
      }
    }
  },
  { immediate: true }
);

onMounted(() => {
  generateQRCodes();

  // Start WhatsApp Light auth polling if needed
  if (isAWhatsAppLightChannel.value && !isWhapiAuthenticated.value) {
    stopQRPolling();
    startAuthPolling();
  }
});

onUnmounted(() => {
  cleanupWhapiPolling();
});
</script>

<template>
  <div class="overflow-auto col-span-6 p-6 w-full h-full">
    <DuplicateInboxBanner
      v-if="hasDuplicateInstagramInbox"
      :content="$t('INBOX_MGMT.ADD.INSTAGRAM.NEW_INBOX_SUGGESTION')"
    />
    <EmptyState
      :title="$t('INBOX_MGMT.FINISH.TITLE')"
      :message="isAnEmailChannel && !currentInbox.provider ? '' : message"
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
            v-if="isATwilioWhatsAppChannel"
            lang="html"
            :script="currentInbox.callback_webhook_url"
          />
        </div>
        <div
          v-if="shouldShowWhatsAppWebhookDetails"
          class="w-[50%] max-w-[50%] ml-[25%]"
        >
          <p class="mt-8 font-medium text-n-slate-11">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.WEBHOOK_URL') }}
          </p>
          <woot-code lang="html" :script="currentInbox.callback_webhook_url" />
          <p class="mt-8 font-medium text-n-slate-11">
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
        <div class="w-[50%] max-w-[50%] ml-[25%]">
          <woot-code
            v-if="isALineChannel"
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
        <EmailInboxFinish
          v-if="isAnEmailChannel && !currentInbox.provider"
          :inbox="currentInbox"
          :inbox-id="$route.params.inbox_id"
        />
        <div
          v-if="
            isAWhatsAppChannel && !isAWhatsAppLightChannel && qrCodes.whatsapp
          "
          class="flex flex-col gap-3 items-center mt-8"
        >
          <p class="mt-2 text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.FINISH.WHATSAPP_QR_INSTRUCTION') }}
          </p>
          <div class="rounded-lg shadow outline-1 outline-n-strong outline">
            <img
              :src="qrCodes.whatsapp"
              alt="WhatsApp QR Code"
              class="rounded-lg size-48 dark:invert"
            />
          </div>
        </div>
        <div
          v-if="isAFacebookInbox && qrCodes.messenger"
          class="flex flex-col gap-3 items-center mt-8"
        >
          <p class="mt-2 text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.FINISH.MESSENGER_QR_INSTRUCTION') }}
          </p>
          <div class="rounded-lg shadow outline-1 outline-n-strong outline">
            <img
              :src="qrCodes.messenger"
              alt="Messenger QR Code"
              class="rounded-lg size-48 dark:invert"
            />
          </div>
        </div>
        <div
          v-if="isATelegramChannel && qrCodes.telegram"
          class="flex flex-col gap-4 items-center mt-8"
        >
          <p class="mt-2 text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.FINISH.TELEGRAM_QR_INSTRUCTION') }}
          </p>

          <div class="rounded-lg shadow outline-1 outline-n-strong outline">
            <img
              :src="qrCodes.telegram"
              alt="Telegram QR Code"
              class="rounded-lg size-48 dark:invert"
            />
          </div>
        </div>
        <!-- WhatsApp Light - Loading state -->
        <div
          v-if="isAWhatsAppLightChannel && isWaitingForQR"
          class="flex flex-col gap-3 items-center mt-8"
        >
          <div
            class="animate-spin rounded-full h-12 w-12 border-b-2 border-woot-500"
          />
          <p class="text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_LIGHT.WAITING') }}
          </p>
        </div>
        <!-- WhatsApp Light - QR Code -->
        <div
          v-if="
            isAWhatsAppLightChannel && whapiLightQR && !isWhapiAuthenticated
          "
          class="flex flex-col gap-3 items-center mt-8"
        >
          <p class="mt-2 text-sm text-n-slate-9">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_LIGHT.QR_TITLE') }}
          </p>
          <div
            class="rounded-lg shadow outline-1 outline-n-strong outline bg-white p-4"
          >
            <img
              :src="whapiLightQR"
              alt="WhatsApp Light QR Code"
              class="size-48"
            />
          </div>
          <div class="flex items-center gap-2 text-sm text-slate-11">
            <span class="animate-pulse">●</span>
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_LIGHT.WAITING_AUTH') }}
          </div>
          <p v-if="whapiLightQRSecondsLeft" class="text-xs text-n-slate-9 mt-2">
            {{
              $t('INBOX_MGMT.ADD.WHATSAPP_LIGHT.EXPIRES_IN', {
                seconds: whapiLightQRSecondsLeft,
              })
            }}
          </p>
        </div>
        <!-- WhatsApp Light - QR Expired -->
        <div
          v-if="
            isAWhatsAppLightChannel &&
            !whapiLightQR &&
            !isWaitingForQR &&
            !isWhapiAuthenticated &&
            !whapiQRError &&
            hasAttemptedQRFetch
          "
          class="flex flex-col gap-3 items-center mt-8"
        >
          <div
            class="w-16 h-16 bg-orange-100 rounded-full flex items-center justify-center mb-2"
          >
            <svg
              class="w-8 h-8 text-orange-600"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
          </div>
          <p class="text-sm text-n-slate-9 mb-2">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_LIGHT.QR_EXPIRED') }}
          </p>
          <NextButton
            solid
            blue
            :label="$t('INBOX_MGMT.ADD.WHATSAPP_LIGHT.GENERATE_NEW_QR')"
            @click="regenerateQR"
          />
        </div>
        <!-- WhatsApp Light - Success state -->
        <div
          v-if="isAWhatsAppLightChannel && isWhapiAuthenticated"
          class="flex flex-col gap-3 items-center mt-8"
        >
          <div
            class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center"
          >
            <svg
              class="w-8 h-8 text-green-600"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M5 13l4 4L19 7"
              />
            </svg>
          </div>
          <p class="text-lg font-medium text-green-900">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_LIGHT.SUCCESS') }}
          </p>
        </div>
        <!-- WhatsApp Light - Error state -->
        <div
          v-if="isAWhatsAppLightChannel && whapiQRError"
          class="flex flex-col gap-3 items-center mt-8"
        >
          <div
            class="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center"
          >
            <svg
              class="w-8 h-8 text-red-600"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </div>
          <p class="text-sm text-red-600">
            {{ whapiQRError }}
          </p>
        </div>
        <div
          v-if="!isAWhatsAppLightChannel || isWhapiAuthenticated"
          class="flex gap-2 justify-center mt-4"
        >
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
  </div>
</template>
