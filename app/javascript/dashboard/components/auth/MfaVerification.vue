<script setup>
import { ref, computed, nextTick } from 'vue';
import axios from 'axios';

const props = defineProps({
  mfaToken: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['verified', 'cancel']);

// State
const verificationMethod = ref('otp');
const otpDigits = ref(['', '', '', '', '', '']);
const backupCode = ref('');
const isVerifying = ref(false);
const errorMessage = ref('');
const showHelpModal = ref(false);

// Computed
const otpCode = computed(() => otpDigits.value.join(''));
const canSubmit = computed(() => {
  if (verificationMethod.value === 'otp') {
    return otpCode.value.length === 6;
  }
  return backupCode.value.length === 6;
});

// Verification
const handleVerification = async () => {
  if (!canSubmit.value || isVerifying.value) return;

  isVerifying.value = true;
  errorMessage.value = '';

  try {
    const payload = {
      mfa_token: props.mfaToken,
    };

    if (verificationMethod.value === 'otp') {
      payload.otp_code = otpCode.value;
    } else {
      payload.backup_code = backupCode.value;
    }

    const response = await axios.post('/auth/sign_in', payload);

    // Set auth credentials and redirect
    if (response.data && response.headers) {
      // Store auth credentials in cookies
      const authData = {
        'access-token': response.headers['access-token'],
        'token-type': response.headers['token-type'],
        client: response.headers.client,
        expiry: response.headers.expiry,
        uid: response.headers.uid,
      };

      // Store in cookies for auth
      document.cookie = `cw_d_session_info=${encodeURIComponent(JSON.stringify(authData))}; path=/; SameSite=Lax`;

      // Redirect to dashboard
      window.location.href = '/app/';
    } else {
      emit('verified', response.data);
    }
  } catch (error) {
    errorMessage.value =
      error.response?.data?.error || 'Verification failed. Please try again.';

    // Clear inputs on error
    if (verificationMethod.value === 'otp') {
      otpDigits.value = ['', '', '', '', '', ''];
      const firstInput = document.querySelector('input:first-of-type');
      if (firstInput) firstInput.focus();
    } else {
      backupCode.value = '';
    }
  } finally {
    isVerifying.value = false;
  }
};

// OTP Input Handling
const handleOtpInput = async index => {
  const value = otpDigits.value[index];

  // Only allow numbers
  if (!/^\d*$/.test(value)) {
    otpDigits.value[index] = '';
    return;
  }

  // Move to next input if value entered
  if (value && index < 5) {
    await nextTick();
    const nextInput = document.querySelector(`input:nth-of-type(${index + 2})`);
    if (nextInput) nextInput.focus();
  }

  // Auto-submit if all digits entered
  if (otpCode.value.length === 6) {
    handleVerification();
  }
};

const handleOtpKeydown = async (event, index) => {
  // Handle backspace
  if (event.key === 'Backspace' && !otpDigits.value[index] && index > 0) {
    event.preventDefault();
    const prevInput = document.querySelector(`input:nth-of-type(${index})`);
    if (prevInput) {
      prevInput.focus();
      otpDigits.value[index - 1] = '';
    }
  }

  // Handle arrow keys
  if (event.key === 'ArrowLeft' && index > 0) {
    event.preventDefault();
    const prevInput = document.querySelector(`input:nth-of-type(${index})`);
    if (prevInput) prevInput.focus();
  }

  if (event.key === 'ArrowRight' && index < 5) {
    event.preventDefault();
    const nextInput = document.querySelector(`input:nth-of-type(${index + 2})`);
    if (nextInput) nextInput.focus();
  }
};

const handleOtpPaste = event => {
  event.preventDefault();
  const pastedData = event.clipboardData
    .getData('text')
    .replace(/\D/g, '')
    .slice(0, 6);

  if (pastedData.length === 6) {
    otpDigits.value = pastedData.split('');
    handleVerification();
  }
};

// Alternative Actions
const handleTryAnotherMethod = () => {
  // Toggle between methods
  verificationMethod.value =
    verificationMethod.value === 'otp' ? 'backup' : 'otp';

  // Clear inputs
  otpDigits.value = ['', '', '', '', '', ''];
  backupCode.value = '';
  errorMessage.value = '';
};

const handleCancel = () => {
  emit('cancel');
};
</script>

<template>
  <div class="w-full max-w-md mx-auto">
    <div class="bg-white dark:bg-slate-800 rounded-xl shadow-lg p-8">
      <!-- Header -->
      <div class="text-center mb-6">
        <div
          class="inline-flex items-center justify-center w-16 h-16 bg-woot-100 dark:bg-woot-900 rounded-full mb-4"
        >
          <svg
            class="w-8 h-8 text-blue-600 dark:text-blue-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
            />
          </svg>
        </div>
        <h2 class="text-2xl font-bold text-slate-900 dark:text-slate-100">
          {{ $t('MFA_VERIFICATION.TITLE') }}
        </h2>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-2">
          {{ $t('MFA_VERIFICATION.DESCRIPTION') }}
        </p>
      </div>

      <!-- Tab Selection -->
      <div class="flex rounded-lg bg-slate-100 dark:bg-slate-900 p-1 mb-6">
        <button
          class="flex-1 py-2 px-4 text-sm font-medium rounded-md transition-colors"
          :class="[
            verificationMethod === 'otp'
              ? 'bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 shadow-sm'
              : 'text-slate-600 dark:text-slate-400 hover:text-slate-900',
          ]"
          @click="verificationMethod = 'otp'"
        >
          {{ $t('MFA_VERIFICATION.AUTHENTICATOR_APP') }}
        </button>
        <button
          class="flex-1 py-2 px-4 text-sm font-medium rounded-md transition-colors"
          :class="[
            verificationMethod === 'backup'
              ? 'bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 shadow-sm'
              : 'text-slate-600 dark:text-slate-400 hover:text-slate-900',
          ]"
          @click="verificationMethod = 'backup'"
        >
          {{ $t('MFA_VERIFICATION.BACKUP_CODE') }}
        </button>
      </div>

      <!-- Verification Form -->
      <form class="space-y-4" @submit.prevent="handleVerification">
        <!-- OTP Code Input -->
        <div v-if="verificationMethod === 'otp'">
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
          >
            {{ $t('MFA_VERIFICATION.ENTER_OTP_CODE') }}
          </label>
          <div class="flex space-x-2">
            <input
              v-for="(digit, index) in otpDigits"
              :key="index"
              :ref="`otpInput${index}`"
              v-model="otpDigits[index]"
              type="text"
              maxlength="1"
              pattern="[0-9]"
              inputmode="numeric"
              class="w-12 h-12 text-center text-lg font-semibold border-2 border-slate-300 dark:border-slate-600 rounded-lg focus:border-woot-500 focus:ring-2 focus:ring-woot-500 focus:ring-opacity-50 dark:bg-slate-900 dark:text-slate-100"
              @input="handleOtpInput(index)"
              @keydown="handleOtpKeydown($event, index)"
              @paste="handleOtpPaste"
            />
          </div>
        </div>

        <!-- Backup Code Input -->
        <div v-if="verificationMethod === 'backup'">
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
          >
            {{ $t('MFA_VERIFICATION.ENTER_BACKUP_CODE') }}
          </label>
          <input
            v-model="backupCode"
            type="text"
            :placeholder="
              $t('MFA_VERIFICATION.BACKUP_CODE_PLACEHOLDER') || '000000'
            "
            class="w-full px-4 py-3 border-2 border-slate-300 dark:border-slate-600 rounded-lg focus:border-woot-500 focus:ring-2 focus:ring-woot-500 focus:ring-opacity-50 dark:bg-slate-900 dark:text-slate-100"
            @keyup.enter="handleVerification"
          />
        </div>

        <!-- Error Message -->
        <div
          v-if="errorMessage"
          class="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg"
        >
          <p class="text-sm text-red-600 dark:text-red-400">
            {{ errorMessage }}
          </p>
        </div>

        <!-- Submit Button -->
        <button
          type="submit"
          :disabled="!canSubmit || isVerifying"
          class="w-full px-4 py-3 text-white bg-blue-600 rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors"
        >
          <span v-if="isVerifying" class="inline-flex items-center">
            <svg
              class="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle
                class="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                stroke-width="4"
              />
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              />
            </svg>
            {{ $t('COMMON.VERIFYING') || 'Verifying...' }}
          </span>
          <span v-else>{{
            $t('MFA_VERIFICATION.VERIFY_BUTTON') || 'Verify'
          }}</span>
        </button>

        <!-- Alternative Actions -->
        <div class="text-center space-y-2 pt-4">
          <button
            type="button"
            class="text-sm text-slate-600 dark:text-slate-400 hover:text-woot-600 dark:hover:text-woot-400"
            @click="handleTryAnotherMethod"
          >
            {{ $t('MFA_VERIFICATION.TRY_ANOTHER_METHOD') }}
          </button>
          <div class="text-slate-400 dark:text-slate-500" aria-hidden="true">
            •
          </div>
          <button
            type="button"
            class="text-sm text-slate-600 dark:text-slate-400 hover:text-woot-600 dark:hover:text-woot-400"
            @click="handleCancel"
          >
            {{ $t('MFA_VERIFICATION.CANCEL_LOGIN') }}
          </button>
        </div>
      </form>
    </div>

    <!-- Help Text -->
    <div class="mt-6 text-center">
      <p class="text-sm text-slate-500 dark:text-slate-400">
        {{ $t('MFA_VERIFICATION.HELP_TEXT') }}
      </p>
      <a
        href="#"
        class="text-sm text-woot-600 dark:text-woot-400 hover:text-woot-700 dark:hover:text-woot-300"
        @click.prevent="showHelpModal = true"
      >
        {{ $t('MFA_VERIFICATION.LEARN_MORE') }}
      </a>
    </div>

    <!-- Help Modal -->
    <div
      v-if="showHelpModal"
      class="fixed inset-0 z-50 overflow-y-auto"
      aria-labelledby="modal-title"
      role="dialog"
      aria-modal="true"
    >
      <div
        class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
      >
        <div
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
          aria-hidden="true"
          @click="showHelpModal = false"
        />
        <!-- Modal alignment spacer -->
        <span
          class="hidden sm:inline-block sm:align-middle sm:h-screen"
          aria-hidden="true"
        />
        <div
          class="inline-block align-bottom bg-white dark:bg-slate-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
        >
          <div class="p-6">
            <h3
              class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-4"
            >
              {{ $t('MFA_VERIFICATION.HELP_MODAL.TITLE') }}
            </h3>
            <div class="space-y-4 text-sm text-slate-600 dark:text-slate-400">
              <div>
                <h4 class="font-medium text-slate-800 dark:text-slate-200 mb-2">
                  {{ $t('MFA_VERIFICATION.HELP_MODAL.AUTHENTICATOR_TITLE') }}
                </h4>
                <p>
                  {{ $t('MFA_VERIFICATION.HELP_MODAL.AUTHENTICATOR_DESC') }}
                </p>
              </div>
              <div>
                <h4 class="font-medium text-slate-800 dark:text-slate-200 mb-2">
                  {{ $t('MFA_VERIFICATION.HELP_MODAL.BACKUP_TITLE') }}
                </h4>
                <p>{{ $t('MFA_VERIFICATION.HELP_MODAL.BACKUP_DESC') }}</p>
              </div>
              <div>
                <h4 class="font-medium text-slate-800 dark:text-slate-200 mb-2">
                  {{ $t('MFA_VERIFICATION.HELP_MODAL.CONTACT_TITLE') }}
                </h4>
                <p>{{ $t('MFA_VERIFICATION.HELP_MODAL.CONTACT_DESC') }}</p>
              </div>
            </div>
            <div class="mt-6 flex justify-end">
              <button
                class="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2"
                @click="showHelpModal = false"
              >
                {{ $t('COMMON.CLOSE') || 'Close' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
