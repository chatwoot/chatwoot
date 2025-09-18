<script setup>
import {
  ref,
  computed,
  watch,
  onMounted,
  onBeforeUnmount,
  nextTick,
} from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { required, minLength } from '@vuelidate/validators';
import router from '../../../../index';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { DotLottieVue } from '@lottiefiles/dotlottie-vue';

const props = defineProps({
  disabledAutoRoute: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['stepChanged']);

const store = useStore();

// State (replaces data())
const step = ref('name'); // name | qr | success
const inboxName = ref('');
const createdInbox = ref(null);
const qrImageB64 = ref('');
const qrPollTimer = ref(null);
const lottieTimer = ref(null);
const qrRetryCount = ref(0);
const qrMaxRetries = ref(20); // ~5 minutes at 15s interval
const isLoadingQr = ref(false);
const qrError = ref(null);
const showLottieAnimation = ref(true);
const isLottieComplete = ref(false);

// Store access (replaces mapGetters)
const uiFlags = useMapGetter('inboxes/getUIFlags');

// Helper functions (need to be defined before computed properties)
const clearQrTimer = () => {
  if (qrPollTimer.value) {
    clearTimeout(qrPollTimer.value);
    qrPollTimer.value = null;
  }
};

const clearLottieTimer = () => {
  if (lottieTimer.value) {
    clearTimeout(lottieTimer.value);
    lottieTimer.value = null;
  }
};

const onLottieComplete = () => {
  // Hide the animation and show the success content
  showLottieAnimation.value = false;
  isLottieComplete.value = true;
};

const startLottieTimer = () => {
  // Fallback timer in case @complete event doesn't fire
  // Most Lottie animations are 2-3 seconds, so we'll wait 2.5 seconds

  // Store the timer ID so we can clear it later
  lottieTimer.value = setTimeout(() => {
    if (showLottieAnimation.value && !isLottieComplete.value) {
      onLottieComplete();
    }
  }, 2500);
};

// Computed properties
const currentInbox = computed(() => {
  if (!createdInbox.value) return {};
  return store.getters['inboxes/getInbox'](createdInbox.value.id) || {};
});

const connectionStatus = computed(() => {
  const cfg = currentInbox.value.provider_config || {};
  return cfg.connection_status || 'pending';
});

// Validation setup
const rules = {
  inboxName: {
    required,
    minLength: minLength(2), // Minimum 2 characters for a valid name
  },
};

const v$ = useVuelidate(rules, { inboxName });

const isContinueButtonDisabled = computed(() => {
  // Button is disabled if validation fails or if creating is in progress
  return v$.value.inboxName.$invalid || uiFlags.value.isCreating;
});

const fetchQrAndStartPolling = async () => {
  // GUARD: Prevent concurrent execution (follows codebase pattern)
  if (isLoadingQr.value) return;

  isLoadingQr.value = true;
  qrError.value = null;

  try {
    const response = await store.dispatch(
      'inboxes/getWhapiQrCode',
      createdInbox.value.id
    );

    // Check if channel is already authenticated
    if (response.authenticated) {
      isLoadingQr.value = false;
      clearQrTimer();
      step.value = 'success';
      return;
    }

    const {
      image_base64: imageBase64,
      poll_in: pollIn,
      expires_in: expiresIn,
    } = response;

    if (imageBase64) {
      qrImageB64.value = `data:image/png;base64,${imageBase64}`;
      isLoadingQr.value = false;
    } else {
      qrError.value = 'QR code is being generated, please wait...';
    }

    clearQrTimer();
    const intervalMs = (pollIn || Math.max(15, expiresIn || 20)) * 1000;
    qrRetryCount.value += 1;
    if (qrRetryCount.value > qrMaxRetries.value) {
      isLoadingQr.value = false;
      qrError.value = 'QR code generation timed out. Please try again.';
      useAlert('QR code expired or retry limit reached');
      return;
    }
    qrPollTimer.value = setTimeout(fetchQrAndStartPolling, intervalMs);
  } catch (e) {
    // Enhanced error handling with specific messages
    isLoadingQr.value = false;

    qrRetryCount.value += 1;
    if (qrRetryCount.value > qrMaxRetries.value) {
      qrError.value = 'QR code generation failed. Please try again.';
      useAlert('QR code expired or retry limit reached');
      return;
    }

    // Show specific error message if available
    if (e.message && e.message.includes('already authenticated')) {
      clearQrTimer();
      step.value = 'success';
    } else if (e.message && e.message.includes('503')) {
      qrError.value = 'Service temporarily unavailable. Retrying...';
      qrPollTimer.value = setTimeout(fetchQrAndStartPolling, 30000);
    } else if (e.message && e.message.includes('unexpected response format')) {
      qrError.value = 'QR code is being prepared. Retrying...';
      qrPollTimer.value = setTimeout(fetchQrAndStartPolling, 15000);
    } else {
      // Default retry interval
      qrError.value = 'Generating QR code. Please wait...';
      qrPollTimer.value = setTimeout(fetchQrAndStartPolling, 20000);
    }
  }
};

// Methods (converted to functions)
const createChannel = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;
  try {
    const created = await store.dispatch('inboxes/createWhapiChannel', {
      name: inboxName.value,
    });
    createdInbox.value = created;
    step.value = 'qr';
    fetchQrAndStartPolling();
  } catch (error) {
    useAlert(error.message || 'An error occurred while creating the channel');
  }
};

const proceedOnSuccess = () => {
  if (props.disabledAutoRoute) return;
  router.replace({
    name: 'settings_inboxes_invite_team',
    params: { page: 'new', inbox_id: createdInbox.value.id },
  });
};

// Watchers
watch(connectionStatus, newVal => {
  if (step.value === 'qr' && newVal === 'connected') {
    clearQrTimer();
    step.value = 'success';
  }
});

watch(step, newVal => {
  emit('stepChanged', newVal);
  // Reset animation state when entering success step
  if (newVal === 'success') {
    showLottieAnimation.value = true;
    isLottieComplete.value = false;
    // Start the fallback timer
    nextTick(() => {
      startLottieTimer();
    });
  }
});

// Lifecycle hooks
onMounted(() => {
  emit('stepChanged', step.value);
});

onBeforeUnmount(() => {
  clearQrTimer();
  clearLottieTimer();
});
</script>

<template>
  <div class="flex flex-col mx-0">
    <form
      v-if="step === 'name'"
      class="flex flex-wrap flex-col mx-0"
      @submit.prevent="createChannel()"
    >
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.inboxName.$error }">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
          <input
            v-model="inboxName"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.PLACEHOLDER')"
            @blur="v$.inboxName.$touch"
          />
          <span v-if="v$.inboxName.$error" class="message">
            {{
              v$.inboxName.$errors[0].$validator === 'required'
                ? $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR')
                : $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.MIN_LENGTH_ERROR')
            }}
          </span>
          <p
            v-if="!v$.inboxName.$error && inboxName.length > 0"
            class="help-text text-green-600"
          >
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.VALID') }}
          </p>
        </label>
      </div>

      <div class="w-full mt-4">
        <NextButton
          :is-loading="uiFlags.isCreating"
          type="submit"
          solid
          blue
          label="Continue"
          :disabled="isContinueButtonDisabled"
          :class="{ 'opacity-50 cursor-not-allowed': isContinueButtonDisabled }"
        />
      </div>
    </form>

    <div
      v-else-if="step === 'qr'"
      class="flex flex-col items-center justify-center"
    >
      <!-- Loading spinner when QR is being generated -->
      <div v-if="isLoadingQr && !qrImageB64" class="flex flex-col items-center">
        <div class="flex items-center justify-center h-48 w-48">
          <Spinner :size="64" class="text-n-brand" />
        </div>
        <p class="mt-4 text-slate-600">
          {{ $t('INBOX_MGMT.ADD.WHAPI.GENERATING_QR') }}
        </p>
      </div>

      <!-- QR Code image when available -->
      <img
        v-else-if="qrImageB64"
        :src="qrImageB64"
        alt="WhatsApp QR Code"
        class="h-48 w-48 border border-gray-300 rounded"
      />

      <!-- Error state when QR failed to load -->
      <div v-else-if="qrError" class="flex flex-col items-center">
        <div
          class="h-48 w-48 border-2 border-dashed border-gray-300 rounded flex items-center justify-center"
        >
          <p class="text-gray-500 text-center px-4">{{ qrError }}</p>
        </div>
      </div>

      <!-- Default loading state -->
      <div v-else class="flex flex-col items-center">
        <div
          class="h-48 w-48 border-2 border-dashed border-gray-300 rounded flex items-center justify-center"
        >
          <p class="text-gray-500">
            {{ $t('INBOX_MGMT.ADD.WHAPI.LOADING_QR') }}
          </p>
        </div>
      </div>

      <p v-if="qrImageB64" class="mt-3 text-slate-600">
        {{ $t('INBOX_MGMT.ADD.WHAPI.QR_HELP_TEXT') }}
      </p>
    </div>

    <div
      v-else-if="step === 'success'"
      class="flex flex-col items-center justify-center"
    >
      <DotLottieVue
        v-if="showLottieAnimation"
        class="h-48 w-48"
        autoplay
        :loop="false"
        src="https://lottie.host/bc4d2cc8-bf76-47a0-a9f9-63abebc62420/gj5OjtX7ZL.lottie"
        @complete="onLottieComplete"
        @finished="onLottieComplete"
        @end="onLottieComplete"
      />

      <p
        v-if="isLottieComplete"
        class="mt-3 text-slate-600 text-center font-medium"
      >
        {{ $t('INBOX_MGMT.ADD.WHAPI.SUCCESS_MESSAGE') }}
      </p>
      <div v-if="isLottieComplete" class="w-full mt-4">
        <NextButton
          solid
          green
          :label="$t('INBOX_MGMT.ADD.WHAPI.CONTINUE_BUTTON')"
          @click="proceedOnSuccess"
        />
      </div>
    </div>
  </div>
</template>
