<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import WhatsappUnofficialAPI from 'dashboard/api/channel/whatsappUnofficialClient';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const QR_POLL_INTERVAL_MS = 3000;
const QR_TIMEOUT_MS = 60000;
const STATUS_POLL_INTERVAL_MS = 15000;

const connectionStatus = ref('unknown');
const qrCode = ref('');
const isConnecting = ref(false);
let qrPollingTimer = null;
let qrTimeoutTimer = null;
let statusPollingTimer = null;

const isConnected = computed(() => connectionStatus.value === 'connected');

const connectionStatusLabel = computed(() => {
  if (isConnected.value) {
    return t('INBOX_MGMT.UNOFFICIAL_WHATSAPP.STATUS.CONNECTED');
  }
  if (connectionStatus.value === 'disconnected') {
    return t('INBOX_MGMT.UNOFFICIAL_WHATSAPP.STATUS.DISCONNECTED');
  }
  if (connectionStatus.value === 'scanning') {
    return t('INBOX_MGMT.UNOFFICIAL_WHATSAPP.STATUS.SCANNING');
  }
  return t('INBOX_MGMT.UNOFFICIAL_WHATSAPP.STATUS.UNKNOWN');
});

const fetchConnectionStatus = async () => {
  try {
    const { data } = await WhatsappUnofficialAPI.getStatus(
      props.inbox.channel_id
    );
    connectionStatus.value = data.status || 'unknown';
  } catch (error) {
    connectionStatus.value = 'unknown';
  }
};

const stopStatusWatch = () => {
  if (statusPollingTimer) {
    clearInterval(statusPollingTimer);
    statusPollingTimer = null;
  }
};

// Keep the status badge honest over time. A session can drop after the initial
// mount-time fetch, and without this the UI stays stuck on a stale "Connected".
const startStatusWatch = () => {
  stopStatusWatch();
  statusPollingTimer = setInterval(
    fetchConnectionStatus,
    STATUS_POLL_INTERVAL_MS
  );
};

const stopQrPolling = () => {
  if (qrPollingTimer) {
    clearInterval(qrPollingTimer);
    qrPollingTimer = null;
  }
  if (qrTimeoutTimer) {
    clearTimeout(qrTimeoutTimer);
    qrTimeoutTimer = null;
  }
};

const resetScanningState = () => {
  stopQrPolling();
  connectionStatus.value = 'disconnected';
  qrCode.value = '';
  startStatusWatch();
};

const markConnected = () => {
  stopQrPolling();
  connectionStatus.value = 'connected';
  qrCode.value = '';
  startStatusWatch();
  useAlert(t('INBOX_MGMT.UNOFFICIAL_WHATSAPP.CONNECT_SUCCESS'));
};

const pollQr = async () => {
  try {
    const { data } = await WhatsappUnofficialAPI.getQr(props.inbox.channel_id);
    // The companion answers 204 once connected (or before a QR is emitted),
    // so confirm the state through the status endpoint.
    if (!data?.qr) {
      const { data: statusData } = await WhatsappUnofficialAPI.getStatus(
        props.inbox.channel_id
      );
      if (statusData?.status === 'connected') {
        markConnected();
      }
      return;
    }
    qrCode.value = data.qr;
    connectionStatus.value = data.status || 'scanning';
  } catch (error) {
    // Transient companion errors are non-fatal; keep waiting for the QR.
    connectionStatus.value = 'scanning';
  }
};

const startQrLogin = async () => {
  if (isConnecting.value) return;
  isConnecting.value = true;
  stopQrPolling();
  stopStatusWatch();
  try {
    // Force a fresh session before connecting. The companion treats /connect as
    // a no-op when it already holds a (possibly stale) connected socket, so log
    // out first to guarantee a brand-new QR is produced — otherwise a lost
    // session can never be re-scanned on this page.
    await WhatsappUnofficialAPI.logout(props.inbox.channel_id);
    await WhatsappUnofficialAPI.connect({
      phone_number: props.inbox.phone_number,
    });
  } catch (error) {
    isConnecting.value = false;
    startStatusWatch();
    useAlert(
      error.message || t('INBOX_MGMT.UNOFFICIAL_WHATSAPP.CONNECT_ERROR')
    );
    return;
  }

  connectionStatus.value = 'scanning';
  qrCode.value = '';
  isConnecting.value = false;
  pollQr();
  qrPollingTimer = setInterval(pollQr, QR_POLL_INTERVAL_MS);
  qrTimeoutTimer = setTimeout(() => {
    resetScanningState();
    useAlert(t('INBOX_MGMT.UNOFFICIAL_WHATSAPP.QR_TIMEOUT'));
  }, QR_TIMEOUT_MS);
};

onMounted(() => {
  fetchConnectionStatus();
  startStatusWatch();
});

onBeforeUnmount(() => {
  stopQrPolling();
  stopStatusWatch();
});
</script>

<template>
  <div
    class="flex flex-col gap-6 p-6 rounded-2xl border border-n-weak bg-n-surface-1 mb-6"
  >
    <div class="flex items-center justify-between gap-4">
      <div class="flex flex-col gap-1">
        <h3 class="text-heading-3 text-n-slate-12">
          {{ $t('INBOX_MGMT.UNOFFICIAL_WHATSAPP.TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11">
          {{ $t('INBOX_MGMT.UNOFFICIAL_WHATSAPP.DESCRIPTION') }}
        </p>
      </div>
      <div class="flex items-center gap-3">
        <span class="text-sm text-n-slate-11">
          {{ $t('INBOX_MGMT.UNOFFICIAL_WHATSAPP.STATUS.LABEL') }}
        </span>
        <span
          class="text-sm font-medium"
          :class="{
            'text-n-green-10': isConnected,
            'text-n-ruby-10': connectionStatus === 'disconnected',
            'text-n-slate-12':
              !isConnected && connectionStatus !== 'disconnected',
          }"
        >
          {{ connectionStatusLabel }}
        </span>
        <NextButton
          v-if="!isConnecting"
          :is-loading="isConnecting"
          sm
          blue
          :label="$t('INBOX_MGMT.UNOFFICIAL_WHATSAPP.RECONNECT_BUTTON')"
          @click="startQrLogin"
        />
        <NextButton
          v-if="connectionStatus === 'scanning' && !isConnecting"
          sm
          gray
          :label="$t('INBOX_MGMT.UNOFFICIAL_WHATSAPP.CANCEL_BUTTON')"
          @click="resetScanningState"
        />
      </div>
    </div>

    <!-- The QR is a login step, not a setting: only render it while the
         session is being established. -->
    <div
      v-if="!isConnected && (connectionStatus === 'scanning' || qrCode)"
      class="flex flex-col items-center gap-4 p-6 rounded-2xl border border-n-weak"
    >
      <p class="text-sm font-medium text-n-slate-12">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.UNOFFICIAL.QR_TITLE') }}
      </p>
      <img v-if="qrCode" :src="qrCode" alt="WhatsApp QR" class="size-56" />
      <p v-else class="text-sm text-n-slate-11">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.UNOFFICIAL.QR_WAITING') }}
      </p>
      <p class="text-xs text-n-slate-10">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.UNOFFICIAL.QR_SCANNING') }}
      </p>
    </div>
  </div>
</template>
