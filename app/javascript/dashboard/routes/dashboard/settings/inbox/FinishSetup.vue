<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import QRCode from 'qrcode';
import { useAlert } from 'dashboard/composables';
import EmptyState from '../../../../components/widgets/EmptyState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import DuplicateInboxBanner from './channels/instagram/DuplicateInboxBanner.vue';
import EmailInboxFinish from './channels/emailChannels/EmailInboxFinish.vue';
import { useInbox } from 'dashboard/composables/useInbox';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import WhatsappWebChannel from 'dashboard/api/channel/whatsappWebChannel';
import {
  isValidWhatsappWebPhone,
  normalizeWhatsappWebPhone,
} from './channels/whatsappWebPhone';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();

const qrCodes = reactive({
  whatsapp: '',
  messenger: '',
  telegram: '',
});

const whatsappWeb = reactive({
  isLoading: false,
  isRequestingQr: false,
  isRequestingCode: false,
  isRefreshingStatus: false,
  isReconnecting: false,
  isCancelling: false,
  isLoggingOut: false,
  isRemovingDevice: false,
  errorMessage: '',
  instanceName: '',
  state: 'unknown',
  exists: false,
  isConnected: false,
  isLoggedIn: false,
  canRequestQr: true,
  canRequestPairCode: true,
  canReconnect: true,
  canCancel: false,
  canLogout: false,
  canRemoveDevice: false,
  qrLink: '',
  qrDurationSeconds: 0,
  qrSecondsLeft: 0,
  qrExpiresAtMs: 0,
  pairPhone: '',
  pairCode: '',
  hasShownConnectedAlert: false,
});

let qrCountdownTimer = null;
let statusPollingTimer = null;

const currentInbox = computed(() =>
  store.getters['inboxes/getInbox'](route.params.inbox_id)
);

// Use useInbox composable with the inbox ID
const {
  isAWhatsAppCloudChannel,
  isATwilioChannel,
  isASmsInbox,
  isALineChannel,
  isAnEmailChannel,
  isAWhatsAppChannel,
  isAFacebookInbox,
  isATelegramChannel,
  isATwilioWhatsAppChannel,
} = useInbox(route.params.inbox_id);

const isWhatsAppWebApiInbox = computed(() => {
  return (
    currentInbox.value?.channel_type === INBOX_TYPES.API &&
    currentInbox.value?.additional_attributes?.integration_type ===
      'whatsapp_web'
  );
});

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

const whatsappWebStatusLabel = computed(() => {
  if (whatsappWeb.isLoggedIn && whatsappWeb.isConnected) {
    return t('INBOX_MGMT.FINISH.WHATSAPP_WEB.STATUS_CONNECTED');
  }
  if (whatsappWeb.isLoggedIn) {
    return t('INBOX_MGMT.FINISH.WHATSAPP_WEB.STATUS_LOGGED_IN');
  }
  if (whatsappWeb.isConnected) {
    return t('INBOX_MGMT.FINISH.WHATSAPP_WEB.STATUS_CONNECTED_NO_LOGIN');
  }
  return t('INBOX_MGMT.FINISH.WHATSAPP_WEB.STATUS_WAITING');
});

const formattedQrTimeLeft = computed(() => {
  const total = Math.max(0, Number(whatsappWeb.qrSecondsLeft) || 0);
  const minutes = String(Math.floor(total / 60)).padStart(2, '0');
  const seconds = String(total % 60).padStart(2, '0');
  return `${minutes}:${seconds}`;
});

const formattedPairCode = computed(() => {
  const normalized = (whatsappWeb.pairCode || '')
    .toString()
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, '');

  if (!normalized) return '';
  if (normalized.length <= 4) return normalized;
  return `${normalized.slice(0, 4)}-${normalized.slice(4, 8)}`;
});

const normalizedPairPhone = computed(() =>
  normalizeWhatsappWebPhone(whatsappWeb.pairPhone)
);

const isPairPhoneValid = computed(() =>
  isValidWhatsappWebPhone(whatsappWeb.pairPhone)
);

const isPairPhoneLocked = computed(() => normalizedPairPhone.value.length > 0);

const pairPhoneError = computed(() => {
  if (whatsappWeb.pairPhone.trim() && !isPairPhoneValid.value) {
    return t('INBOX_MGMT.FINISH.WHATSAPP_WEB.PAIR_PHONE_INVALID');
  }

  return '';
});

const message = computed(() => {
  if (isWhatsAppWebApiInbox.value) {
    return t('INBOX_MGMT.FINISH.WHATSAPP_WEB.MESSAGE');
  }

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

  return t('INBOX_MGMT.FINISH.MESSAGE');
});

function clearQrCountdownTimer() {
  if (qrCountdownTimer) {
    clearInterval(qrCountdownTimer);
    qrCountdownTimer = null;
  }
}

function clearStatusPollingTimer() {
  if (statusPollingTimer) {
    clearInterval(statusPollingTimer);
    statusPollingTimer = null;
  }
}

function clearWhatsappWebTimers() {
  clearQrCountdownTimer();
  clearStatusPollingTimer();
}

function parseQrDurationSeconds(rawDuration) {
  if (typeof rawDuration === 'number' && Number.isFinite(rawDuration)) {
    if (rawDuration > 1_000_000) {
      return Math.max(10, Math.round(rawDuration / 1_000_000_000));
    }
    return Math.max(10, Math.round(rawDuration));
  }

  if (typeof rawDuration === 'string') {
    const normalized = rawDuration.trim().toLowerCase();
    if (/^\d+$/.test(normalized)) {
      const numeric = Number(normalized);
      if (numeric > 1_000_000) {
        return Math.max(10, Math.round(numeric / 1_000_000_000));
      }
      return Math.max(10, numeric);
    }
    if (/^\d+s$/.test(normalized)) {
      return Math.max(10, Number(normalized.replace('s', '')));
    }
    if (/^\d+m$/.test(normalized)) {
      return Math.max(10, Number(normalized.replace('m', '')) * 60);
    }
  }

  return 30;
}

function whatsappWebError(error, fallbackMessage) {
  return (
    error?.response?.data?.error ||
    error?.response?.data?.message ||
    error?.message ||
    fallbackMessage
  );
}

function isMissingWhatsappWebInbox(error) {
  return error?.response?.status === 404;
}

function handleMissingWhatsappWebInbox(error) {
  if (!isMissingWhatsappWebInbox(error)) {
    return false;
  }

  clearWhatsappWebTimers();
  whatsappWeb.instanceName = '';
  whatsappWeb.state = 'missing';
  whatsappWeb.exists = false;
  whatsappWeb.isConnected = false;
  whatsappWeb.isLoggedIn = false;
  whatsappWeb.canRequestQr = false;
  whatsappWeb.canRequestPairCode = false;
  whatsappWeb.canReconnect = false;
  whatsappWeb.canCancel = false;
  whatsappWeb.canLogout = false;
  whatsappWeb.canRemoveDevice = false;
  whatsappWeb.qrLink = '';
  whatsappWeb.pairCode = '';
  whatsappWeb.hasShownConnectedAlert = false;
  whatsappWeb.errorMessage = 'Inbox no longer exists. Reload the page.';
  useAlert(whatsappWeb.errorMessage);
  router.replace({
    name: 'settings_inbox_list',
    params: {
      accountId: route.params.accountId || route.params.account_id,
    },
  });

  return true;
}

async function loadWhatsappWebConfig() {
  const response = await WhatsappWebChannel.showConfig(route.params.inbox_id);
  whatsappWeb.instanceName = response.data?.config?.instance_name || '';
  const configuredPhone = normalizeWhatsappWebPhone(
    response.data?.config?.phone || ''
  );
  if (configuredPhone) {
    whatsappWeb.pairPhone = configuredPhone;
  }
}

function applyWhatsappWebStatus(status = {}) {
  const state = status.state || 'unknown';
  whatsappWeb.state = state;
  whatsappWeb.exists =
    typeof status.exists === 'boolean' ? status.exists : state !== 'missing';
  whatsappWeb.isConnected = !!status.is_connected;
  whatsappWeb.isLoggedIn = !!status.is_logged_in;
  whatsappWeb.canRequestQr =
    typeof status.can_request_qr === 'boolean'
      ? status.can_request_qr
      : !whatsappWeb.isLoggedIn;
  whatsappWeb.canRequestPairCode =
    typeof status.can_request_pair_code === 'boolean'
      ? status.can_request_pair_code
      : !whatsappWeb.isLoggedIn;
  whatsappWeb.canReconnect =
    typeof status.can_reconnect === 'boolean'
      ? status.can_reconnect
      : state !== 'connecting';
  whatsappWeb.canCancel =
    typeof status.can_cancel === 'boolean'
      ? status.can_cancel
      : state === 'connecting';
  whatsappWeb.canLogout =
    typeof status.can_logout === 'boolean'
      ? status.can_logout
      : whatsappWeb.isLoggedIn;
  whatsappWeb.canRemoveDevice =
    typeof status.can_remove_device === 'boolean'
      ? status.can_remove_device
      : whatsappWeb.exists;

  if (whatsappWeb.isLoggedIn || state === 'missing' || state === 'close') {
    clearQrCountdownTimer();
    whatsappWeb.qrLink = '';
    whatsappWeb.pairCode = '';
  }
}

async function refreshWhatsappWebStatus({ silent = false } = {}) {
  if (!whatsappWeb.instanceName) {
    return;
  }

  if (!silent) {
    whatsappWeb.isRefreshingStatus = true;
  }

  try {
    const response = await WhatsappWebChannel.status(route.params.inbox_id, {
      instance_name: whatsappWeb.instanceName,
    });
    const status = response.data?.status || {};
    applyWhatsappWebStatus(status);

    if (whatsappWeb.isLoggedIn) {
      clearQrCountdownTimer();
      if (!whatsappWeb.hasShownConnectedAlert) {
        useAlert(t('INBOX_MGMT.FINISH.WHATSAPP_WEB.CONNECTED_SUCCESS'));
        whatsappWeb.hasShownConnectedAlert = true;
      }
    } else {
      whatsappWeb.hasShownConnectedAlert = false;
    }
  } catch (error) {
    if (handleMissingWhatsappWebInbox(error)) {
      return;
    }

    whatsappWeb.errorMessage = whatsappWebError(
      error,
      t('INBOX_MGMT.FINISH.WHATSAPP_WEB.STATUS_ERROR')
    );
    if (!silent) {
      useAlert(whatsappWeb.errorMessage);
    }
  } finally {
    whatsappWeb.isRefreshingStatus = false;
  }
}

function startQrCountdown(durationSeconds, onExpired) {
  const seconds = Math.max(10, durationSeconds);
  whatsappWeb.qrDurationSeconds = seconds;
  whatsappWeb.qrSecondsLeft = seconds;
  whatsappWeb.qrExpiresAtMs = Date.now() + seconds * 1000;

  clearQrCountdownTimer();
  qrCountdownTimer = setInterval(async () => {
    const secondsLeft = Math.max(
      0,
      Math.ceil((whatsappWeb.qrExpiresAtMs - Date.now()) / 1000)
    );
    whatsappWeb.qrSecondsLeft = secondsLeft;

    if (secondsLeft > 0) {
      return;
    }

    clearQrCountdownTimer();
    if (!whatsappWeb.isLoggedIn && onExpired) {
      await onExpired();
    }
  }, 1000);
}

async function requestWhatsappWebQr({ silent = false } = {}) {
  if (!whatsappWeb.instanceName || whatsappWeb.isRequestingQr) {
    return;
  }

  whatsappWeb.isRequestingQr = true;
  try {
    const payload = {
      instance_name: whatsappWeb.instanceName,
    };

    const response = await WhatsappWebChannel.loginQr(
      route.params.inbox_id,
      payload
    );
    const login = response.data?.login || {};
    applyWhatsappWebStatus(response.data?.status || { state: login.state });
    whatsappWeb.qrLink = login.qr_link || '';
    whatsappWeb.pairCode = '';
    const durationSeconds = parseQrDurationSeconds(login.qr_duration);
    if (whatsappWeb.qrLink) {
      startQrCountdown(durationSeconds, async () => {
        await requestWhatsappWebQr({ silent: true });
      });
    } else {
      clearQrCountdownTimer();
    }

    if (!silent) {
      useAlert(t('INBOX_MGMT.FINISH.WHATSAPP_WEB.QR_UPDATED'));
    }
    whatsappWeb.errorMessage = '';
  } catch (error) {
    if (handleMissingWhatsappWebInbox(error)) {
      return;
    }

    whatsappWeb.errorMessage = whatsappWebError(
      error,
      t('INBOX_MGMT.FINISH.WHATSAPP_WEB.QR_ERROR')
    );
    if (!silent) {
      useAlert(whatsappWeb.errorMessage);
    }
  } finally {
    whatsappWeb.isRequestingQr = false;
  }
}

async function requestWhatsappWebPairCode() {
  if (!whatsappWeb.instanceName) {
    return;
  }

  if (!isPairPhoneValid.value) {
    if (!whatsappWeb.pairPhone.trim()) {
      useAlert(t('INBOX_MGMT.FINISH.WHATSAPP_WEB.PAIR_PHONE_REQUIRED'));
      return;
    }

    useAlert(t('INBOX_MGMT.FINISH.WHATSAPP_WEB.PAIR_PHONE_INVALID'));
    return;
  }

  whatsappWeb.isRequestingCode = true;
  try {
    const response = await WhatsappWebChannel.loginCode(route.params.inbox_id, {
      instance_name: whatsappWeb.instanceName,
      phone: normalizedPairPhone.value,
    });
    applyWhatsappWebStatus(response.data?.status || {});
    whatsappWeb.pairCode = response.data?.login?.pair_code || '';
    useAlert(t('INBOX_MGMT.FINISH.WHATSAPP_WEB.PAIR_CODE_SUCCESS'));
  } catch (error) {
    if (handleMissingWhatsappWebInbox(error)) {
      return;
    }

    useAlert(
      whatsappWebError(
        error,
        t('INBOX_MGMT.FINISH.WHATSAPP_WEB.PAIR_CODE_ERROR')
      )
    );
  } finally {
    whatsappWeb.isRequestingCode = false;
  }
}

function onPairPhoneInput(event) {
  whatsappWeb.pairPhone = normalizeWhatsappWebPhone(event.target.value);
}

async function reconnectWhatsappWeb() {
  if (!whatsappWeb.instanceName) {
    return;
  }

  whatsappWeb.isReconnecting = true;
  try {
    const response = await WhatsappWebChannel.reconnect(route.params.inbox_id, {
      instance_name: whatsappWeb.instanceName,
    });
    applyWhatsappWebStatus(response.data?.status || {});
    useAlert(t('INBOX_MGMT.FINISH.WHATSAPP_WEB.RECONNECT_SUCCESS'));
    if (!response.data?.status) {
      await refreshWhatsappWebStatus({ silent: true });
    }
    if (
      !whatsappWeb.isLoggedIn &&
      whatsappWeb.canRequestQr &&
      whatsappWeb.state !== 'connecting'
    ) {
      await requestWhatsappWebQr({ silent: true });
    }
  } catch (error) {
    if (handleMissingWhatsappWebInbox(error)) {
      return;
    }

    useAlert(
      whatsappWebError(
        error,
        t('INBOX_MGMT.FINISH.WHATSAPP_WEB.RECONNECT_ERROR')
      )
    );
  } finally {
    whatsappWeb.isReconnecting = false;
  }
}

async function logoutWhatsappWeb() {
  if (!whatsappWeb.instanceName) {
    return;
  }

  whatsappWeb.isLoggingOut = true;
  try {
    const response = await WhatsappWebChannel.logout(route.params.inbox_id, {
      instance_name: whatsappWeb.instanceName,
    });
    applyWhatsappWebStatus(response.data?.status || {});
    useAlert(t('INBOX_MGMT.FINISH.WHATSAPP_WEB.LOGOUT_SUCCESS'));
    whatsappWeb.hasShownConnectedAlert = false;
    clearQrCountdownTimer();
    whatsappWeb.qrLink = '';
    whatsappWeb.pairCode = '';
  } catch (error) {
    if (handleMissingWhatsappWebInbox(error)) {
      return;
    }

    useAlert(
      whatsappWebError(error, t('INBOX_MGMT.FINISH.WHATSAPP_WEB.LOGOUT_ERROR'))
    );
  } finally {
    whatsappWeb.isLoggingOut = false;
  }
}

async function cancelWhatsappWeb() {
  if (!whatsappWeb.instanceName) {
    return;
  }

  whatsappWeb.isCancelling = true;
  try {
    const response = await WhatsappWebChannel.cancel(route.params.inbox_id, {
      instance_name: whatsappWeb.instanceName,
    });
    applyWhatsappWebStatus(response.data?.status || {});
    useAlert(
      response.data?.cancel?.response?.message ||
        t('FILTER.FILTER.CANCEL_BUTTON_LABEL')
    );
    whatsappWeb.hasShownConnectedAlert = false;
    clearQrCountdownTimer();
    whatsappWeb.qrLink = '';
    whatsappWeb.pairCode = '';
  } catch (error) {
    if (handleMissingWhatsappWebInbox(error)) {
      return;
    }

    useAlert(
      whatsappWebError(error, t('INBOX_MGMT.FINISH.WHATSAPP_WEB.LOGOUT_ERROR'))
    );
  } finally {
    whatsappWeb.isCancelling = false;
  }
}

async function removeWhatsappWebDevice() {
  if (!whatsappWeb.instanceName) {
    return;
  }

  whatsappWeb.isRemovingDevice = true;
  try {
    const response = await WhatsappWebChannel.removeDevice(
      route.params.inbox_id,
      {
        instance_name: whatsappWeb.instanceName,
      }
    );
    applyWhatsappWebStatus(response.data?.status || {});
    useAlert(t('INBOX_MGMT.FINISH.WHATSAPP_WEB.REMOVE_DEVICE_SUCCESS'));
    whatsappWeb.hasShownConnectedAlert = false;
    whatsappWeb.qrLink = '';
    whatsappWeb.pairCode = '';
    clearQrCountdownTimer();
  } catch (error) {
    if (handleMissingWhatsappWebInbox(error)) {
      return;
    }

    useAlert(
      whatsappWebError(
        error,
        t('INBOX_MGMT.FINISH.WHATSAPP_WEB.REMOVE_DEVICE_ERROR')
      )
    );
  } finally {
    whatsappWeb.isRemovingDevice = false;
  }
}

function startStatusPolling() {
  clearStatusPollingTimer();
  statusPollingTimer = setInterval(() => {
    refreshWhatsappWebStatus({ silent: true });
  }, 5000);
}

async function bootstrapWhatsappWebConnection() {
  whatsappWeb.isLoading = true;
  whatsappWeb.errorMessage = '';
  whatsappWeb.qrLink = '';
  whatsappWeb.pairCode = '';
  whatsappWeb.isConnected = false;
  whatsappWeb.isLoggedIn = false;
  clearWhatsappWebTimers();

  try {
    await loadWhatsappWebConfig();
    await refreshWhatsappWebStatus({ silent: true });
    if (
      !whatsappWeb.isLoggedIn &&
      whatsappWeb.canRequestQr &&
      whatsappWeb.state !== 'connecting'
    ) {
      await requestWhatsappWebQr({ silent: true });
    }
    startStatusPolling();
  } catch (error) {
    if (handleMissingWhatsappWebInbox(error)) {
      return;
    }

    whatsappWeb.errorMessage = whatsappWebError(
      error,
      t('INBOX_MGMT.FINISH.WHATSAPP_WEB.BOOTSTRAP_ERROR')
    );
  } finally {
    whatsappWeb.isLoading = false;
  }
}

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

watch(
  currentInbox,
  newInbox => {
    if (newInbox) {
      generateQRCodes();
    }
  },
  { immediate: true }
);

watch(
  isWhatsAppWebApiInbox,
  enabled => {
    if (enabled) {
      bootstrapWhatsappWebConnection();
      return;
    }
    clearWhatsappWebTimers();
  },
  { immediate: true }
);

onMounted(() => {
  generateQRCodes();
});

onBeforeUnmount(() => {
  clearWhatsappWebTimers();
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
      :message="
        isAnEmailChannel && !currentInbox.provider
          ? ''
          : isWhatsAppWebApiInbox
            ? ''
            : message
      "
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
          v-if="isAWhatsAppChannel && qrCodes.whatsapp"
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

        <div
          v-if="isWhatsAppWebApiInbox"
          class="mt-8 max-w-2xl mx-auto rounded-xl border border-n-weak p-5 text-left"
        >
          <h3 class="text-base font-medium text-n-slate-12 mb-2">
            {{ $t('INBOX_MGMT.FINISH.WHATSAPP_WEB.TITLE') }}
          </h3>

          <div class="text-sm text-n-slate-11 mb-3">
            {{ $t('INBOX_MGMT.FINISH.WHATSAPP_WEB.STATUS_LABEL') }}
            <span class="font-medium text-n-slate-12">{{
              whatsappWebStatusLabel
            }}</span>
          </div>

          <p
            v-if="whatsappWeb.errorMessage"
            class="mb-3 p-3 rounded-lg bg-n-ruby-3 text-n-ruby-11 text-sm"
          >
            {{ whatsappWeb.errorMessage }}
          </p>

          <div
            v-if="whatsappWeb.isLoading"
            class="text-sm text-n-slate-11 mb-3"
          >
            {{ $t('INBOX_MGMT.FINISH.WHATSAPP_WEB.LOADING') }}
          </div>

          <div
            v-if="
              (whatsappWeb.qrLink || formattedPairCode) &&
              !whatsappWeb.isLoggedIn
            "
            class="mb-4 flex flex-col items-center"
          >
            <div v-if="whatsappWeb.qrLink" class="inline-block">
              <div class="rounded-lg border border-n-weak p-2 inline-block">
                <img
                  :src="whatsappWeb.qrLink"
                  alt="WhatsApp Web login QR"
                  class="size-64 rounded-md"
                />
              </div>
            </div>
            <p
              v-if="whatsappWeb.qrLink"
              class="text-sm text-n-slate-11 mt-1 text-center"
            >
              {{ $t('INBOX_MGMT.FINISH.WHATSAPP_WEB.QR_TIME_LEFT') }}
              <span class="font-medium">{{ formattedQrTimeLeft }}</span>
            </p>
          </div>

          <div
            v-if="whatsappWeb.isLoggedIn"
            class="mb-4 text-sm text-n-teal-11"
          >
            {{ $t('INBOX_MGMT.FINISH.WHATSAPP_WEB.CONNECTED_SUCCESS') }}
          </div>

          <div
            class="mb-4 flex items-center justify-center gap-2 overflow-x-auto pb-1"
          >
            <div
              v-if="formattedPairCode"
              class="inline-flex shrink-0 items-center gap-2 rounded-lg border border-n-weak bg-n-alpha-2 px-3 py-2"
            >
              <span class="text-xs text-n-slate-11">
                {{ $t('INBOX_MGMT.FINISH.WHATSAPP_WEB.PAIR_CODE_LABEL') }}
              </span>
              <span
                class="font-mono text-base text-n-slate-12 tracking-[0.2em]"
              >
                {{ formattedPairCode }}
              </span>
            </div>
            <div
              class="inline-flex shrink-0 items-center gap-1 rounded-lg border border-n-weak bg-n-alpha-2 p-1"
            >
              <NextButton
                ghost
                slate
                sm
                icon="i-lucide-qr-code"
                :disabled="!whatsappWeb.canRequestQr"
                :is-loading="whatsappWeb.isRequestingQr"
                :title="$t('INBOX_MGMT.FINISH.WHATSAPP_WEB.REFRESH_QR_BUTTON')"
                :aria-label="
                  $t('INBOX_MGMT.FINISH.WHATSAPP_WEB.REFRESH_QR_BUTTON')
                "
                @click="requestWhatsappWebQr"
              />
              <NextButton
                ghost
                slate
                sm
                icon="i-lucide-key-round"
                :disabled="!whatsappWeb.canRequestPairCode"
                :is-loading="whatsappWeb.isRequestingCode"
                :title="$t('INBOX_MGMT.FINISH.WHATSAPP_WEB.PAIR_CODE_BUTTON')"
                :aria-label="
                  $t('INBOX_MGMT.FINISH.WHATSAPP_WEB.PAIR_CODE_BUTTON')
                "
                @click="requestWhatsappWebPairCode"
              />
              <NextButton
                ghost
                slate
                sm
                icon="i-lucide-refresh-ccw"
                :disabled="!whatsappWeb.canReconnect"
                :is-loading="whatsappWeb.isReconnecting"
                :title="$t('INBOX_MGMT.FINISH.WHATSAPP_WEB.RECONNECT_BUTTON')"
                :aria-label="
                  $t('INBOX_MGMT.FINISH.WHATSAPP_WEB.RECONNECT_BUTTON')
                "
                @click="reconnectWhatsappWeb"
              />
              <NextButton
                v-if="whatsappWeb.canCancel"
                ghost
                slate
                sm
                icon="i-lucide-x"
                :disabled="!whatsappWeb.canCancel"
                :is-loading="whatsappWeb.isCancelling"
                :title="$t('FILTER.FILTER.CANCEL_BUTTON_LABEL')"
                :aria-label="$t('FILTER.FILTER.CANCEL_BUTTON_LABEL')"
                @click="cancelWhatsappWeb"
              />
              <NextButton
                ghost
                slate
                sm
                icon="i-lucide-log-out"
                :disabled="!whatsappWeb.canLogout"
                :is-loading="whatsappWeb.isLoggingOut"
                :title="$t('INBOX_MGMT.FINISH.WHATSAPP_WEB.LOGOUT_BUTTON')"
                :aria-label="$t('INBOX_MGMT.FINISH.WHATSAPP_WEB.LOGOUT_BUTTON')"
                @click="logoutWhatsappWeb"
              />
              <NextButton
                ghost
                ruby
                sm
                icon="i-lucide-trash-2"
                :disabled="!whatsappWeb.canRemoveDevice"
                :is-loading="whatsappWeb.isRemovingDevice"
                :title="
                  $t('INBOX_MGMT.FINISH.WHATSAPP_WEB.REMOVE_DEVICE_BUTTON')
                "
                :aria-label="
                  $t('INBOX_MGMT.FINISH.WHATSAPP_WEB.REMOVE_DEVICE_BUTTON')
                "
                @click="removeWhatsappWebDevice"
              />
            </div>
          </div>

          <div class="mb-4 w-full max-w-md mx-auto">
            <label class="mb-0.5 text-heading-3 text-n-slate-12">
              {{ $t('INBOX_MGMT.FINISH.WHATSAPP_WEB.PAIR_PHONE_LABEL') }}
            </label>
            <div class="mt-1 flex w-full items-center gap-2">
              <span
                class="shrink-0 select-none text-base font-medium text-n-brand before:block before:content-['+']"
              />
              <div
                class="flex h-10 w-full items-center rounded-lg bg-n-alpha-black2 outline outline-1 outline-offset-[-1px]"
                :class="
                  pairPhoneError
                    ? 'outline-n-ruby-8'
                    : 'outline-n-weak hover:outline-n-slate-6 focus-within:outline-n-brand'
                "
              >
                <input
                  :value="whatsappWeb.pairPhone"
                  :disabled="isPairPhoneLocked"
                  type="text"
                  inputmode="numeric"
                  pattern="[0-9]*"
                  maxlength="11"
                  :placeholder="
                    $t('INBOX_MGMT.FINISH.WHATSAPP_WEB.PAIR_PHONE_PLACEHOLDER')
                  "
                  class="reset-base no-margin h-full min-w-0 flex-1 border-0 bg-transparent px-3 py-2.5 text-sm text-n-slate-12 shadow-none placeholder:text-n-slate-10 focus:outline-none"
                  :class="{
                    'cursor-not-allowed opacity-60': isPairPhoneLocked,
                  }"
                  @input="onPairPhoneInput"
                />
              </div>
            </div>
            <p
              v-if="pairPhoneError"
              class="mt-1 text-label-small text-n-ruby-9"
            >
              {{ pairPhoneError }}
            </p>
          </div>
        </div>

        <div class="flex gap-2 justify-center mt-4">
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
            <NextButton solid :label="$t('INBOX_MGMT.FINISH.BUTTON_TEXT')" />
          </router-link>
        </div>
      </div>
    </EmptyState>
  </div>
</template>
