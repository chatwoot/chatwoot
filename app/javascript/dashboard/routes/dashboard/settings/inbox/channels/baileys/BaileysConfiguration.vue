<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SettingsFieldSection from '../../settingsPage/../../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import BaileysChannel from 'dashboard/api/channel/baileysChannel';

const POLL_INTERVAL = 5000;

const props = defineProps({
  inbox: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();

const sessionStatus = ref('unknown');
const phoneNumber = ref('');
const qrCodeData = ref('');
const isLoading = ref(false);
const pollTimer = ref(null);

const isConnected = computed(() => sessionStatus.value === 'connected');
const isQrPending = computed(
  () => sessionStatus.value === 'qr_pending' && qrCodeData.value
);

function stopPolling() {
  if (pollTimer.value) {
    clearInterval(pollTimer.value);
    pollTimer.value = null;
  }
}

async function fetchStatus() {
  try {
    const { data } = await BaileysChannel.getStatus(props.inbox.id);
    sessionStatus.value = data.session_status || 'disconnected';
    phoneNumber.value = data.phone_number || '';
    if (data.qr_code) {
      qrCodeData.value = data.qr_code;
    }
    if (sessionStatus.value === 'connected') {
      stopPolling();
    }
  } catch {
    sessionStatus.value = 'disconnected';
  }
}

function startPolling() {
  stopPolling();
  pollTimer.value = setInterval(fetchStatus, POLL_INTERVAL);
}

async function reconnect() {
  isLoading.value = true;
  try {
    const { data } = await BaileysChannel.requestQrCode(props.inbox.id);
    if (data.qr_code) {
      qrCodeData.value = data.qr_code;
      sessionStatus.value = 'qr_pending';
    }
    startPolling();
  } catch {
    useAlert(t('INBOX_MGMT.SETTINGS_POPUP.BAILEYS.RECONNECT_ERROR'));
  } finally {
    isLoading.value = false;
  }
}

async function disconnect() {
  isLoading.value = true;
  try {
    await BaileysChannel.disconnect(props.inbox.id);
    sessionStatus.value = 'disconnected';
    qrCodeData.value = '';
    phoneNumber.value = '';
    useAlert(t('INBOX_MGMT.SETTINGS_POPUP.BAILEYS.DISCONNECT_SUCCESS'));
  } catch {
    useAlert(t('INBOX_MGMT.SETTINGS_POPUP.BAILEYS.DISCONNECT_ERROR'));
  } finally {
    isLoading.value = false;
  }
}

onMounted(() => {
  fetchStatus();
});

onBeforeUnmount(() => {
  stopPolling();
});
</script>

<template>
  <div class="flex flex-col gap-6">
    <div class="flex items-center gap-3">
      <span
        class="inline-block w-3 h-3 rounded-full"
        :class="isConnected ? 'bg-g-500' : 'bg-r-500'"
      />
      <span class="text-sm font-medium text-n-slate-12">
        {{
          isConnected
            ? $t('INBOX_MGMT.SETTINGS_POPUP.BAILEYS.STATUS_CONNECTED')
            : $t('INBOX_MGMT.SETTINGS_POPUP.BAILEYS.STATUS_DISCONNECTED')
        }}
      </span>
      <span v-if="phoneNumber" class="text-sm text-n-slate-11">
        ({{ phoneNumber }})
      </span>
    </div>

    <!-- QR Code for reconnection -->
    <div
      v-if="isQrPending"
      class="flex flex-col items-center p-6 rounded-xl border border-n-weak bg-n-alpha-black2"
    >
      <p class="mb-4 text-sm text-n-slate-11 text-center">
        {{ $t('INBOX_MGMT.SETTINGS_POPUP.BAILEYS.QR_INSTRUCTIONS') }}
      </p>
      <div class="p-4 bg-white rounded-xl shadow-sm">
        <img
          :src="qrCodeData"
          alt="WhatsApp QR Code"
          width="256"
          height="256"
          class="block"
        />
      </div>
    </div>

    <div class="flex gap-2">
      <NextButton
        v-if="!isConnected"
        :is-loading="isLoading"
        @click="reconnect"
      >
        {{ $t('INBOX_MGMT.SETTINGS_POPUP.BAILEYS.RECONNECT') }}
      </NextButton>
      <NextButton
        v-if="isConnected"
        variant="smooth"
        color="ruby"
        :is-loading="isLoading"
        @click="disconnect"
      >
        {{ $t('INBOX_MGMT.SETTINGS_POPUP.BAILEYS.DISCONNECT') }}
      </NextButton>
    </div>
  </div>
</template>
