<script setup>
import { ref, computed, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import router from '../../../../index';
import EvolutionAPI from 'dashboard/api/evolution';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'shared/components/Spinner.vue';
import PageHeader from '../../SettingsSubPageHeader.vue';

const { t } = useI18n();
const route = useRoute();

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

const canProceed = computed(() => {
  return isConnected.value;
});

const connectionStatus = computed(() => {
  if (!connectionState.value?.instance) return 'unknown';
  return connectionState.value.instance.state || 'disconnected';
});

// Validation rules
const rules = computed(() => {
  return {
    inboxName: { required },
  };
});

const v$ = useVuelidate(rules, {
  inboxName,
});

// Helper functions - defined first to avoid hoisting issues
const stopPolling = () => {
  if (pollTimer.value) {
    clearInterval(pollTimer.value);
    pollTimer.value = null;
  }
};

const fetchQRCode = async () => {
  if (!createdInbox.value) return;

  try {
    const response = await EvolutionAPI.getQRCode(createdInbox.value.id);
    qrCode.value = response.data;
  } catch (error) {
    // Silently handle QR code fetch errors
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
    // Silently handle connection state errors
  }
};

const startPolling = () => {
  if (pollTimer.value) return;
  pollTimer.value = setInterval(() => {
    refreshConnection();
  }, POLL_INTERVAL);
};

// Main methods
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
    const serverError =
      error.response?.data?.error || error.response?.data?.message || '';
    // Check for duplicate inbox name error
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

const refreshQRCode = async () => {
  isLoadingQR.value = true;
  try {
    // First check connection state
    const stateResponse = await EvolutionAPI.getConnectionState(
      createdInbox.value.id
    );
    connectionState.value = stateResponse.data;

    // Only fetch QR if not connected
    if (!isConnected.value) {
      await fetchQRCode();
    }
  } catch (error) {
    useAlert(t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.QR_ERROR'));
  } finally {
    isLoadingQR.value = false;
  }
};

const enableChatwootIntegration = async () => {
  if (!createdInbox.value) return;

  try {
    await EvolutionAPI.enableIntegration(createdInbox.value.id);
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.INTEGRATION_ERROR')
    );
    throw error;
  }
};

const proceedToAgents = async () => {
  if (!canProceed.value || !createdInbox.value) return;

  isCreating.value = true;

  try {
    // Enable Chatwoot integration before proceeding
    await enableChatwootIntegration();

    router.replace({
      name: 'settings_inboxes_add_agents',
      params: {
        page: 'new',
        inbox_id: createdInbox.value.id,
        accountId: route.params.accountId,
      },
    });
  } catch (error) {
    // Error already handled in enableChatwootIntegration
  } finally {
    isCreating.value = false;
  }
};

// Cleanup on unmount
onBeforeUnmount(() => {
  stopPolling();
});
</script>

<template>
  <div class="col-span-6 h-full w-full p-6">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.EVOLUTION.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.EVOLUTION.DESCRIPTION')"
    />
    <form
      class="mx-0 flex flex-col flex-wrap"
      @submit.prevent="proceedToAgents"
    >
      <!-- Error Banner -->
      <div
        v-if="errorMessage"
        class="mb-4 rounded-lg border border-red-200 bg-red-50 p-4 dark:border-red-800 dark:bg-red-900/20"
      >
        <div class="flex items-start">
          <div class="flex-shrink-0">
            <svg
              class="h-5 w-5 text-red-600 dark:text-red-400"
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path
                fill-rule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                clip-rule="evenodd"
              />
            </svg>
          </div>
          <div class="ml-3 flex-1">
            <h3 class="text-sm font-medium text-red-800 dark:text-red-200">
              {{ $t('INBOX_MGMT.ADD.EVOLUTION.ERROR_TITLE') }}
            </h3>
            <div class="mt-2 text-sm text-red-700 dark:text-red-300">
              <p>{{ errorMessage }}</p>
            </div>
          </div>
          <div class="ml-auto pl-3">
            <button
              type="button"
              class="inline-flex rounded-md p-1.5 text-red-500 hover:bg-red-100 dark:hover:bg-red-900/40"
              @click="errorMessage = ''"
            >
              <span class="sr-only">{{
                $t('INBOX_MGMT.ADD.EVOLUTION.DISMISS')
              }}</span>
              <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
                <path
                  fill-rule="evenodd"
                  d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
          </div>
        </div>
      </div>

      <!-- Inbox Name -->
      <div class="w-full">
        <label :class="{ error: v$.inboxName.$error }">
          {{ $t('INBOX_MGMT.ADD.EVOLUTION.INBOX_NAME.LABEL') }}
          <input
            v-model="inboxName"
            type="text"
            :disabled="isNameLocked"
            :placeholder="$t('INBOX_MGMT.ADD.EVOLUTION.INBOX_NAME.PLACEHOLDER')"
            @blur="v$.inboxName.$touch"
          />
          <span v-if="v$.inboxName.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.EVOLUTION.INBOX_NAME.ERROR') }}
          </span>
        </label>
      </div>

      <!-- QR Code Section -->
      <div v-if="!createdInbox" class="mt-4 w-full">
        <NextButton
          :is-loading="isLoadingQR"
          :disabled="!canLoadQR"
          solid
          blue
          :label="$t('INBOX_MGMT.ADD.EVOLUTION.BAILEYS.LOAD_QR_BUTTON')"
          @click="loadQRCode"
        />
        <p class="mt-2 text-sm text-n-slate-11">
          {{ $t('INBOX_MGMT.ADD.EVOLUTION.BAILEYS.LOAD_QR_HELP') }}
        </p>
      </div>

      <!-- QR Code Display -->
      <div v-else class="mt-4 w-full">
        <!-- Connection Status -->
        <div class="mb-4 flex items-center gap-3">
          <span
            class="inline-block h-3 w-3 rounded-full"
            :class="{
              'bg-green-500': isConnected,
              'bg-yellow-500': connectionStatus === 'connecting',
              'bg-red-500':
                connectionStatus === 'close' || connectionStatus === 'unknown',
            }"
          />
          <span class="text-sm font-medium text-n-slate-12">
            {{
              isConnected
                ? $t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.STATUS.OPEN')
                : connectionStatus === 'connecting'
                  ? $t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.STATUS.CONNECTING')
                  : $t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.STATUS.DISCONNECTED')
            }}
          </span>
        </div>

        <!-- QR Code Image -->
        <div
          v-if="!isConnected"
          class="rounded-lg bg-white p-4 dark:bg-n-slate-2"
        >
          <div v-if="qrCode?.base64" class="flex flex-col items-center">
            <img :src="qrCode.base64" alt="QR Code" class="h-64 w-64" />
            <p class="mt-3 text-center text-sm text-n-slate-11">
              {{ $t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.QR_INSTRUCTION') }}
            </p>
            <NextButton
              class="mt-4"
              ghost
              :is-loading="isLoadingQR"
              :label="$t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.REFRESH_QR')"
              @click="refreshQRCode"
            />
          </div>
          <div v-else class="flex flex-col items-center py-8">
            <Spinner />
            <p class="mt-3 text-sm text-n-slate-11">
              {{ $t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.QR_LOADING') }}
            </p>
            <NextButton
              class="mt-4"
              ghost
              :is-loading="isLoadingQR"
              :label="$t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.REFRESH_QR')"
              @click="refreshQRCode"
            />
          </div>
        </div>

        <!-- Connected State -->
        <div
          v-else
          class="rounded-lg border border-green-200 bg-green-50 p-4 dark:border-green-800 dark:bg-green-900/20"
        >
          <div class="flex items-center gap-3">
            <svg
              class="h-6 w-6 text-green-600 dark:text-green-400"
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
            <p class="text-sm font-medium text-green-800 dark:text-green-200">
              {{ $t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.CONNECTED') }}
            </p>
          </div>
        </div>

        <!-- Continue Button (only enabled when connected) -->
        <div class="mt-4 w-full">
          <NextButton
            :is-loading="isCreating"
            :disabled="!isConnected"
            solid
            blue
            :label="$t('INBOX_MGMT.ADD.EVOLUTION.CONNECT.CONTINUE')"
            @click="proceedToAgents"
          />
        </div>
      </div>
    </form>
  </div>
</template>
