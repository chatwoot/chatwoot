<script setup>
import { ref, computed, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import EvolutionAPI from 'dashboard/api/evolution';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'shared/components/Spinner.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const POLL_INTERVAL = 5000;

// Form state
const inboxName = ref('');

// UI state
const isCreating = ref(false);
const isLoadingQR = ref(false);
const errorMessage = ref('');
const createdInbox = ref(null);
const qrCode = ref(null);
const connectionState = ref(null);
const pollTimer = ref(null);

// Computed
const isNameLocked = computed(() => createdInbox.value !== null);

// Evolution API returns state nested under instance.state
const isConnected = computed(() => {
  const state = connectionState.value?.instance?.state;
  return state === 'open';
});

const canLoadQR = computed(() => {
  return inboxName.value.trim().length > 0 && !createdInbox.value;
});

const connectionStatus = computed(() => {
  if (!connectionState.value?.instance) return 'unknown';
  return connectionState.value.instance.state || 'disconnected';
});

// Validation rules
const rules = computed(() => ({
  inboxName: { required },
}));

const v$ = useVuelidate(rules, { inboxName });

// Methods
const resetState = () => {
  createdInbox.value = null;
  qrCode.value = null;
  connectionState.value = null;
  stopPolling();
};

const loadQRCode = async () => {
  if (!canLoadQR.value) return;

  errorMessage.value = '';
  isLoadingQR.value = true;

  try {
    // Create the Evolution inbox/instance first
    const payload = {
      inbox_name: inboxName.value.trim(),
    };

    const response = await EvolutionAPI.createInbox(payload);
    createdInbox.value = response.data;

    // Now fetch the QR code
    await fetchQRCode();
    startPolling();
  } catch (error) {
    console.error('Failed to create Evolution inbox:', error);
    const serverError =
      error.response?.data?.error || error.response?.data?.message || '';
    if (
      serverError.toLowerCase().includes('already exists') ||
      serverError.toLowerCase().includes('unique inbox name')
    ) {
      errorMessage.value = t(
        'INBOX_MGMT.ADD.EVOLUTION.API.DUPLICATE_NAME_ERROR'
      );
    } else {
      errorMessage.value =
        serverError ||
        error.message ||
        t('INBOX_MGMT.ADD.EVOLUTION.API.ERROR_MESSAGE');
    }
    useAlert(errorMessage.value);
  } finally {
    isLoadingQR.value = false;
  }
};

const fetchQRCode = async () => {
  if (!createdInbox.value) return;

  try {
    const response = await EvolutionAPI.getQRCode(createdInbox.value.id);
    qrCode.value = response.data;
  } catch (error) {
    console.error('Failed to fetch QR code:', error);
  }
};

const refreshConnection = async () => {
  if (!createdInbox.value) return;

  try {
    const response = await EvolutionAPI.getConnectionState(
      createdInbox.value.id
    );
    connectionState.value = response.data;

    if (isConnected.value) {
      qrCode.value = null;
      stopPolling();
      useAlert(t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.CONNECTED'));
    } else if (!qrCode.value?.base64) {
      await fetchQRCode();
    }
  } catch (error) {
    console.error('Failed to refresh connection state:', error);
  }
};

const refreshQRCode = async () => {
  isLoadingQR.value = true;
  try {
    const stateResponse = await EvolutionAPI.getConnectionState(
      createdInbox.value.id
    );
    connectionState.value = stateResponse.data;

    if (!isConnected.value) {
      await fetchQRCode();
    }
  } catch (error) {
    console.error('Failed to refresh QR code:', error);
    useAlert(t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.QR_ERROR'));
  } finally {
    isLoadingQR.value = false;
  }
};

const startPolling = () => {
  if (pollTimer.value) return;
  pollTimer.value = setInterval(() => {
    refreshConnection();
  }, POLL_INTERVAL);
};

const stopPolling = () => {
  if (pollTimer.value) {
    clearInterval(pollTimer.value);
    pollTimer.value = null;
  }
};

const continueToAgents = async () => {
  if (!isConnected.value) {
    useAlert(t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.NOT_CONNECTED'));
    return;
  }

  isCreating.value = true;
  try {
    // Enable Chatwoot integration in Evolution
    await EvolutionAPI.enableIntegration(createdInbox.value.id);

    useAlert(t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.INTEGRATION_ENABLED'));

    // Navigate to add agents
    router.replace({
      name: 'settings_inboxes_add_agents',
      params: {
        page: 'new',
        inbox_id: createdInbox.value.id,
      },
    });
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.ENABLE_ERROR')
    );
  } finally {
    isCreating.value = false;
  }
};

onBeforeUnmount(() => {
  stopPolling();
});
</script>

<template>
  <div class="mx-auto max-w-lg">
    <div class="flex flex-col gap-6">
      <!-- Header -->
      <div class="text-center">
        <h2 class="text-xl font-semibold text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.EVOLUTION.TITLE') }}
        </h2>
        <p class="mt-1 text-sm text-n-slate-11">
          {{ $t('INBOX_MGMT.ADD.EVOLUTION.DESCRIPTION') }}
        </p>
      </div>

      <!-- Inbox Name -->
      <div class="flex flex-col gap-2">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.EVOLUTION.INBOX_NAME.LABEL') }}
        </label>
        <input
          v-model="inboxName"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.EVOLUTION.INBOX_NAME.PLACEHOLDER')"
          :disabled="isNameLocked"
          class="w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 py-2 text-sm text-n-slate-12 placeholder-n-slate-9 focus:border-n-brand focus:outline-none focus:ring-1 focus:ring-n-brand disabled:cursor-not-allowed disabled:opacity-60"
        />
        <p v-if="v$.inboxName.$error" class="text-xs text-n-ruby-9">
          {{ $t('INBOX_MGMT.ADD.EVOLUTION.INBOX_NAME.ERROR') }}
        </p>
      </div>

      <!-- Load QR Button (before inbox creation) -->
      <div v-if="!createdInbox" class="flex justify-center">
        <NextButton
          :label="$t('INBOX_MGMT.ADD.EVOLUTION.LOAD_QR')"
          :disabled="!canLoadQR || isLoadingQR"
          :loading="isLoadingQR"
          @click="loadQRCode"
        />
      </div>

      <!-- Error Message -->
      <div v-if="errorMessage" class="rounded-lg bg-n-ruby-2 p-3 text-n-ruby-11">
        {{ errorMessage }}
      </div>

      <!-- QR Code Section (after inbox creation) -->
      <div v-if="createdInbox" class="flex flex-col items-center gap-4">
        <!-- Connection Status -->
        <div class="flex items-center gap-2">
          <div
            class="h-3 w-3 rounded-full"
            :class="{
              'bg-n-teal-9': isConnected,
              'bg-n-amber-9': connectionStatus === 'connecting',
              'bg-n-ruby-9':
                connectionStatus === 'disconnected' ||
                connectionStatus === 'unknown',
            }"
          />
          <span class="text-sm text-n-slate-11">
            {{
              $t(
                `INBOX_MGMT.ADD.EVOLUTION.CONNECT.STATUS.${connectionStatus.toUpperCase()}`
              )
            }}
          </span>
        </div>

        <!-- QR Code Display -->
        <div
          v-if="!isConnected"
          class="flex flex-col items-center gap-4 rounded-lg border border-n-weak bg-n-alpha-1 p-6"
        >
          <p class="text-center text-sm text-n-slate-11">
            {{ $t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.SCAN_INSTRUCTION') }}
          </p>

          <div v-if="isLoadingQR" class="flex h-64 w-64 items-center justify-center">
            <Spinner size="large" />
          </div>

          <div v-else-if="qrCode?.base64" class="rounded-lg bg-white p-2">
            <img
              :src="qrCode.base64"
              alt="QR Code"
              class="h-64 w-64"
            />
          </div>

          <div v-else class="flex h-64 w-64 items-center justify-center text-n-slate-9">
            {{ $t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.NO_QR') }}
          </div>

          <NextButton
            variant="secondary"
            :label="$t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.REFRESH_QR')"
            :disabled="isLoadingQR"
            @click="refreshQRCode"
          />
        </div>

        <!-- Connected State -->
        <div v-else class="flex flex-col items-center gap-4 rounded-lg border border-n-teal-6 bg-n-teal-2 p-6">
          <div class="flex h-16 w-16 items-center justify-center rounded-full bg-n-teal-9 text-white">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-8 w-8"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M5 13l4 4L19 7"
              />
            </svg>
          </div>
          <p class="text-center font-medium text-n-teal-11">
            {{ $t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.SUCCESS') }}
          </p>
        </div>

        <!-- Continue Button -->
        <NextButton
          :label="$t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.CONTINUE')"
          :disabled="!isConnected || isCreating"
          :loading="isCreating"
          @click="continueToAgents"
        />
      </div>
    </div>
  </div>
</template>

