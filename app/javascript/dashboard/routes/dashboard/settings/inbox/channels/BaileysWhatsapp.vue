<script setup>
import { ref, computed, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import NextButton from 'dashboard/components-next/button/Button.vue';
import BaileysChannel from 'dashboard/api/channel/baileysChannel';

const POLL_INTERVAL = 3000;
const SESSION_STATES = {
  IDLE: 'idle',
  CREATING: 'creating',
  QR_PENDING: 'qr_pending',
  CONNECTING: 'connecting',
  CONNECTED: 'connected',
  ERROR: 'error',
};

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const { accountId } = useAccount();

const inboxName = ref('');
const sessionState = ref(SESSION_STATES.IDLE);
const qrCodeData = ref('');
const createdInboxId = ref(null);
const phoneNumber = ref('');
const isCreating = ref(false);
const pollTimer = ref(null);
const errorMessage = ref('');

const uiFlags = computed(() => store.getters['inboxes/getUIFlags']);
const isFormValid = computed(() => inboxName.value.trim().length > 0);

const isQrVisible = computed(
  () =>
    sessionState.value === SESSION_STATES.QR_PENDING && qrCodeData.value !== ''
);
const isConnected = computed(
  () => sessionState.value === SESSION_STATES.CONNECTED
);
const isLoading = computed(
  () =>
    isCreating.value || sessionState.value === SESSION_STATES.CONNECTING
);
const showQrSection = computed(
  () =>
    sessionState.value !== SESSION_STATES.IDLE &&
    sessionState.value !== SESSION_STATES.CREATING
);

function stopPolling() {
  if (pollTimer.value) {
    clearInterval(pollTimer.value);
    pollTimer.value = null;
  }
}

async function pollStatus() {
  if (!createdInboxId.value) return;
  try {
    const { data } = await BaileysChannel.getStatus(createdInboxId.value);
    if (data.session_status === 'connected') {
      sessionState.value = SESSION_STATES.CONNECTED;
      phoneNumber.value = data.phone_number || '';
      stopPolling();
    } else if (data.session_status === 'qr_pending' && data.qr_code) {
      sessionState.value = SESSION_STATES.QR_PENDING;
      qrCodeData.value = data.qr_code;
    }
  } catch {
    // Keep polling silently
  }
}

function startPolling() {
  stopPolling();
  pollTimer.value = setInterval(pollStatus, POLL_INTERVAL);
}

async function createChannelAndRequestQr() {
  if (!isFormValid.value) return;

  isCreating.value = true;
  sessionState.value = SESSION_STATES.CREATING;
  errorMessage.value = '';

  try {
    const response = await store.dispatch('inboxes/createChannel', {
      channel: { type: 'baileys_whatsapp' },
      name: inboxName.value.trim(),
    });
    createdInboxId.value = response.id;
    sessionState.value = SESSION_STATES.CONNECTING;

    const { data } = await BaileysChannel.requestQrCode(response.id);
    if (data.qr_code) {
      qrCodeData.value = data.qr_code;
      sessionState.value = SESSION_STATES.QR_PENDING;
    }
    startPolling();
  } catch (error) {
    sessionState.value = SESSION_STATES.ERROR;
    errorMessage.value =
      error.message || t('INBOX_MGMT.ADD.BAILEYS.API.ERROR_MESSAGE');
    useAlert(errorMessage.value);
  } finally {
    isCreating.value = false;
  }
}

function goToAgents() {
  router.replace({
    name: 'settings_inboxes_add_agents',
    params: { page: 'new', inbox_id: createdInboxId.value },
  });
}

onBeforeUnmount(() => {
  stopPolling();
});
</script>

<template>
  <div>
    <!-- Step 1: Name + Create -->
    <form
      v-if="!showQrSection"
      class="flex flex-wrap flex-col mx-0 max-w-lg"
      @submit.prevent="createChannelAndRequestQr"
    >
      <div class="flex-shrink-0 flex-grow-0">
        <label>
          {{ $t('INBOX_MGMT.ADD.BAILEYS.INBOX_NAME.LABEL') }}
          <input
            v-model="inboxName"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.BAILEYS.INBOX_NAME.PLACEHOLDER')"
            class="mb-2"
          />
        </label>
      </div>
      <div class="flex items-start gap-2 mt-4">
        <NextButton
          type="submit"
          :disabled="!isFormValid || isLoading"
          :is-loading="isLoading"
        >
          {{ $t('INBOX_MGMT.ADD.BAILEYS.SUBMIT_BUTTON') }}
        </NextButton>
      </div>
    </form>

    <!-- Step 2: QR Code -->
    <div v-if="showQrSection && !isConnected" class="max-w-lg">
      <div
        class="flex flex-col items-center p-8 rounded-2xl border border-n-weak bg-n-alpha-black2"
      >
        <h2 class="mb-2 text-base font-medium text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.BAILEYS.QR.TITLE') }}
        </h2>
        <p class="mb-6 text-sm text-n-slate-11 text-center">
          {{ $t('INBOX_MGMT.ADD.BAILEYS.QR.INSTRUCTIONS') }}
        </p>

        <div
          v-if="isQrVisible"
          class="p-4 bg-white rounded-xl shadow-sm"
        >
          <img
            :src="qrCodeData"
            alt="WhatsApp QR Code"
            width="256"
            height="256"
            class="block"
          />
        </div>

        <div
          v-else
          class="flex items-center justify-center w-64 h-64 rounded-xl bg-n-alpha-black2"
        >
          <span class="i-lucide-loader-2 animate-spin text-2xl text-n-slate-11" />
        </div>

        <p class="mt-4 text-xs text-n-slate-10">
          {{ $t('INBOX_MGMT.ADD.BAILEYS.QR.WAITING') }}
        </p>
      </div>

      <div v-if="errorMessage" class="mt-4 p-3 rounded-lg bg-r-50 text-r-700 text-sm">
        {{ errorMessage }}
      </div>
    </div>

    <!-- Step 3: Connected - proceed to agents -->
    <div v-if="isConnected" class="max-w-lg">
      <div
        class="flex flex-col items-center p-8 rounded-2xl border border-n-weak bg-n-alpha-black2"
      >
        <span class="i-lucide-check-circle-2 text-4xl text-g-500 mb-3" />
        <h2 class="mb-2 text-base font-medium text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.BAILEYS.CONNECTED.TITLE') }}
        </h2>
        <p v-if="phoneNumber" class="mb-4 text-sm text-n-slate-11">
          {{ $t('INBOX_MGMT.ADD.BAILEYS.CONNECTED.PHONE', { phone: phoneNumber }) }}
        </p>
        <NextButton @click="goToAgents">
          {{ $t('INBOX_MGMT.ADD.BAILEYS.CONNECTED.NEXT') }}
        </NextButton>
      </div>
    </div>
  </div>
</template>
