<script setup>
import { ref, onMounted } from 'vue';
import QRCode from 'qrcode';
import mfaAPI from 'dashboard/api/mfa';

// State
const mfaEnabled = ref(false);
const backupCodesGenerated = ref(false);
const showSetup = ref(false);
const setupStep = ref('qr'); // 'qr' or 'backup'
const qrCodeUrl = ref('');
const secretKey = ref('');
const backupCodes = ref([]);
const verificationCode = ref('');
const verificationError = ref('');
const backupCodesConfirmed = ref(false);
const provisioningUri = ref('');

// Dialogs
const showDisableDialog = ref(false);
const showRegenerateDialog = ref(false);
const showBackupCodesModal = ref(false);
const disablePassword = ref('');
const disableOtpCode = ref('');
const regenerateOtpCode = ref('');

// Load MFA status on mount
onMounted(async () => {
  try {
    const response = await mfaAPI.get();
    mfaEnabled.value = response.data.enabled;
    backupCodesGenerated.value = response.data.backup_codes_generated;
  } catch (error) {
    // Handle error silently
  }
});

// Generate QR code from provisioning URI
const generateQRCode = async provisioningUrl => {
  try {
    const qrCodeDataUrl = await QRCode.toDataURL(provisioningUrl, {
      width: 256,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF',
      },
    });
    return qrCodeDataUrl;
  } catch (error) {
    return null;
  }
};

// Start MFA setup
const startMfaSetup = async () => {
  try {
    const response = await mfaAPI.enable();

    // Store the provisioning URI
    provisioningUri.value =
      response.data.provisioning_uri || response.data.provisioning_url;

    // Generate QR code from provisioning URI if available
    if (provisioningUri.value) {
      qrCodeUrl.value = await generateQRCode(provisioningUri.value);
    } else if (response.data.qr_code_url) {
      // Fallback to backend-generated QR code if available
      qrCodeUrl.value = response.data.qr_code_url;
    }

    secretKey.value = response.data.secret;
    backupCodes.value = response.data.backup_codes;
    showSetup.value = true;
    setupStep.value = 'qr';
  } catch (error) {
    verificationError.value = 'Failed to start MFA setup. Please try again.';
  }
};

// Verify OTP code
const verifyCode = async () => {
  verificationError.value = '';

  try {
    await mfaAPI.verify(verificationCode.value);
    setupStep.value = 'backup';
    verificationCode.value = '';
  } catch (error) {
    verificationError.value =
      error.response?.data?.error || 'Invalid verification code';
  }
};

// Complete MFA setup
const completeMfaSetup = () => {
  mfaEnabled.value = true;
  backupCodesGenerated.value = true;
  showSetup.value = false;
  setupStep.value = 'qr';
  backupCodesConfirmed.value = false;
  // Two-factor authentication has been enabled successfully
};

// Disable MFA
const disableMfa = async () => {
  try {
    await mfaAPI.disable(disablePassword.value, disableOtpCode.value);
    mfaEnabled.value = false;
    backupCodesGenerated.value = false;
    showDisableDialog.value = false;
    disablePassword.value = '';
    disableOtpCode.value = '';
    // Two-factor authentication has been disabled
  } catch (error) {
    // Failed to disable MFA
  }
};

// Regenerate backup codes
const regenerateBackupCodes = async () => {
  try {
    const response = await mfaAPI.regenerateBackupCodes(
      regenerateOtpCode.value
    );
    backupCodes.value = response.data.backup_codes;
    showRegenerateDialog.value = false;
    regenerateOtpCode.value = '';
    showBackupCodesModal.value = true;
    // New backup codes have been generated
  } catch (error) {
    // Failed to regenerate backup codes
  }
};

// Utility functions
const copySecret = () => {
  navigator.clipboard.writeText(secretKey.value);
};

const copyBackupCodes = () => {
  const codesText = backupCodes.value.join('\n');
  navigator.clipboard.writeText(codesText);
};

const downloadBackupCodes = () => {
  const codesText = `Chatwoot Two-Factor Authentication Backup Codes\n\n${backupCodes.value.join('\n')}\n\nKeep these codes in a safe place.`;
  const blob = new Blob([codesText], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'chatwoot-backup-codes.txt';
  a.click();
  URL.revokeObjectURL(url);
};
</script>

<template>
  <div class="max-w-4xl mx-auto p-6 space-y-6">
    <!-- MFA Status Card -->
    <div
      class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700"
    >
      <!-- Header -->
      <div class="p-6 border-b border-slate-200 dark:border-slate-700">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <div class="flex-shrink-0">
              <div
                class="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center"
              >
                <svg
                  class="w-6 h-6 text-blue-600 dark:text-blue-400"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                  />
                </svg>
              </div>
            </div>
            <div>
              <h2
                class="text-xl font-semibold text-slate-900 dark:text-slate-100"
              >
                {{ $t('MFA_SETTINGS.TITLE') }}
              </h2>
              <p class="mt-1 text-sm text-slate-600 dark:text-slate-400">
                {{ $t('MFA_SETTINGS.SUBTITLE') }}
              </p>
            </div>
          </div>
          <div class="flex items-center">
            <span
              class="px-3 py-1 rounded-full text-xs font-medium"
              :class="[
                mfaEnabled
                  ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
                  : 'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-400',
              ]"
            >
              {{
                mfaEnabled
                  ? $t('MFA_SETTINGS.ENABLED')
                  : $t('MFA_SETTINGS.DISABLED')
              }}
            </span>
          </div>
        </div>
      </div>

      <!-- Content -->
      <div class="p-6">
        <!-- MFA Disabled State -->
        <div v-if="!mfaEnabled && !showSetup" class="text-center py-8">
          <svg
            class="w-16 h-16 text-slate-400 mx-auto mb-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
            />
          </svg>
          <h3
            class="text-lg font-medium text-slate-900 dark:text-slate-100 mb-2"
          >
            {{ $t('MFA_SETTINGS.ENHANCE_SECURITY') }}
          </h3>
          <p
            class="text-sm text-slate-600 dark:text-slate-400 mb-6 max-w-md mx-auto"
          >
            {{ $t('MFA_SETTINGS.ENHANCE_SECURITY_DESC') }}
          </p>
          <button
            class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
            @click="startMfaSetup"
          >
            <svg
              class="w-5 h-5 mr-2"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 6v6m0 0v6m0-6h6m-6 0H6"
              />
            </svg>
            {{ $t('MFA_SETTINGS.ENABLE_BUTTON') }}
          </button>
        </div>

        <!-- MFA Setup Flow -->
        <div v-if="showSetup && !mfaEnabled">
          <!-- Step 1: QR Code -->
          <div v-if="setupStep === 'qr'" class="space-y-6">
            <div class="text-center">
              <div
                class="inline-flex items-center justify-center w-10 h-10 bg-blue-100 dark:bg-blue-900 rounded-full text-blue-600 dark:text-blue-400 font-semibold mb-4"
              >
                {{ $t('MFA_SETTINGS.SETUP.STEP_NUMBER_1') }}
              </div>
              <h3
                class="text-lg font-medium text-slate-900 dark:text-slate-100"
              >
                {{ $t('MFA_SETTINGS.SETUP.STEP1_TITLE') }}
              </h3>
              <p class="mt-2 text-sm text-slate-600 dark:text-slate-400">
                {{ $t('MFA_SETTINGS.SETUP.STEP1_DESCRIPTION') }}
              </p>
            </div>

            <!-- QR Code Display -->
            <div class="flex justify-center">
              <div class="bg-white p-4 rounded-lg border-2 border-slate-200">
                <img
                  v-if="qrCodeUrl"
                  :src="qrCodeUrl"
                  alt="MFA QR Code"
                  class="w-48 h-48"
                />
                <div
                  v-else
                  class="w-48 h-48 flex items-center justify-center bg-slate-50"
                >
                  <span class="text-slate-400">{{
                    $t('MFA_SETTINGS.SETUP.LOADING_QR')
                  }}</span>
                </div>
              </div>
            </div>

            <!-- Manual Entry Option -->
            <details
              class="border border-slate-200 dark:border-slate-700 rounded-lg"
            >
              <summary
                class="px-4 py-3 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-900 text-sm font-medium text-slate-700 dark:text-slate-300"
              >
                {{ $t('MFA_SETTINGS.SETUP.MANUAL_ENTRY') }}
              </summary>
              <div class="px-4 pb-4">
                <label
                  class="block text-xs text-slate-500 dark:text-slate-400 mb-2"
                >
                  {{ $t('MFA_SETTINGS.SETUP.SECRET_KEY') }}
                </label>
                <div class="flex items-center space-x-2">
                  <input
                    type="text"
                    :value="secretKey"
                    readonly
                    class="flex-1 px-3 py-2 bg-slate-100 dark:bg-slate-900 border border-slate-300 dark:border-slate-600 rounded-lg font-mono text-sm"
                  />
                  <button
                    class="px-3 py-2 bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300 rounded-lg hover:bg-slate-300 dark:hover:bg-slate-600"
                    @click="copySecret"
                  >
                    {{ $t('MFA_SETTINGS.SETUP.COPY') }}
                  </button>
                </div>
              </div>
            </details>

            <!-- Verification Input -->
            <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
              <label
                class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
              >
                {{ $t('MFA_SETTINGS.SETUP.ENTER_CODE') }}
              </label>
              <div class="flex items-center space-x-3">
                <input
                  v-model="verificationCode"
                  type="text"
                  maxlength="6"
                  pattern="[0-9]{6}"
                  :placeholder="$t('MFA_SETTINGS.SETUP.ENTER_CODE_PLACEHOLDER')"
                  class="flex-1 max-w-xs px-4 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-slate-900 dark:text-slate-100"
                  @keyup.enter="verifyCode"
                />
                <button
                  :disabled="verificationCode.length !== 6"
                  class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:bg-slate-400 disabled:cursor-not-allowed transition-colors"
                  @click="verifyCode"
                >
                  {{ $t('MFA_SETTINGS.SETUP.VERIFY_BUTTON') }}
                </button>
              </div>
              <p
                v-if="verificationError"
                class="mt-2 text-sm text-red-600 dark:text-red-400"
              >
                {{ verificationError }}
              </p>
            </div>
          </div>

          <!-- Step 2: Backup Codes -->
          <div v-if="setupStep === 'backup'" class="space-y-6">
            <div class="text-center">
              <div
                class="inline-flex items-center justify-center w-10 h-10 bg-blue-100 dark:bg-blue-900 rounded-full text-blue-600 dark:text-blue-400 font-semibold mb-4"
              >
                {{ $t('MFA_SETTINGS.SETUP.STEP_NUMBER_2') }}
              </div>
              <h3
                class="text-lg font-medium text-slate-900 dark:text-slate-100"
              >
                {{ $t('MFA_SETTINGS.BACKUP.TITLE') }}
              </h3>
              <p class="mt-2 text-sm text-slate-600 dark:text-slate-400">
                {{ $t('MFA_SETTINGS.BACKUP.DESCRIPTION') }}
              </p>
            </div>

            <!-- Warning Alert -->
            <div
              class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-4"
            >
              <div class="flex">
                <svg
                  class="w-5 h-5 text-amber-600 dark:text-amber-400 mr-2 flex-shrink-0 mt-0.5"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path
                    fill-rule="evenodd"
                    d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                    clip-rule="evenodd"
                  />
                </svg>
                <p class="text-sm text-amber-800 dark:text-amber-200">
                  <strong>
                    {{ $t('MFA_SETTINGS.BACKUP.IMPORTANT') }}
                  </strong>
                  {{ $t('MFA_SETTINGS.BACKUP.IMPORTANT_NOTE') }}
                </p>
              </div>
            </div>

            <!-- Backup Codes Grid -->
            <div class="bg-slate-50 dark:bg-slate-900 rounded-lg p-6">
              <div class="grid grid-cols-2 gap-3">
                <div
                  v-for="(code, index) in backupCodes"
                  :key="index"
                  class="px-3 py-2 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded font-mono text-sm text-center"
                >
                  {{ code }}
                </div>
              </div>

              <div class="mt-6 flex items-center justify-center space-x-3">
                <button
                  class="inline-flex items-center px-3 py-2 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-lg text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700"
                  @click="downloadBackupCodes"
                >
                  <svg
                    class="w-4 h-4 mr-2"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                    />
                  </svg>
                  {{ $t('MFA_SETTINGS.BACKUP.DOWNLOAD') }}
                </button>
                <button
                  class="inline-flex items-center px-3 py-2 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-lg text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700"
                  @click="copyBackupCodes"
                >
                  <svg
                    class="w-4 h-4 mr-2"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
                    />
                  </svg>
                  {{ $t('MFA_SETTINGS.BACKUP.COPY_ALL') }}
                </button>
              </div>
            </div>

            <!-- Confirmation -->
            <div class="border-t border-slate-200 dark:border-slate-700 pt-6">
              <label class="flex items-start space-x-3">
                <input
                  v-model="backupCodesConfirmed"
                  type="checkbox"
                  class="mt-1 rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                />
                <span class="text-sm text-slate-700 dark:text-slate-300">
                  {{ $t('MFA_SETTINGS.BACKUP.CONFIRM') }}
                </span>
              </label>

              <button
                :disabled="!backupCodesConfirmed"
                class="mt-4 w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:bg-slate-400 disabled:cursor-not-allowed transition-colors"
                @click="completeMfaSetup"
              >
                {{ $t('MFA_SETTINGS.BACKUP.COMPLETE_SETUP') }}
              </button>
            </div>
          </div>
        </div>

        <!-- MFA Enabled State -->
        <div v-if="mfaEnabled" class="space-y-6">
          <!-- Status Info -->
          <div
            class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4"
          >
            <div class="flex">
              <svg
                class="w-5 h-5 text-green-600 dark:text-green-400 mr-2"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                  clip-rule="evenodd"
                />
              </svg>
              <div>
                <p
                  class="text-sm font-medium text-green-800 dark:text-green-200"
                >
                  {{ $t('MFA_SETTINGS.STATUS_ENABLED') }}
                </p>
                <p class="mt-1 text-sm text-green-700 dark:text-green-300">
                  {{ $t('MFA_SETTINGS.STATUS_ENABLED_DESC') }}
                </p>
              </div>
            </div>
          </div>

          <!-- Actions -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Regenerate Backup Codes -->
            <div
              class="border border-slate-200 dark:border-slate-700 rounded-lg p-4"
            >
              <h4 class="font-medium text-slate-900 dark:text-slate-100 mb-2">
                {{ $t('MFA_SETTINGS.MANAGEMENT.BACKUP_CODES') }}
              </h4>
              <p class="text-sm text-slate-600 dark:text-slate-400 mb-4">
                {{ $t('MFA_SETTINGS.MANAGEMENT.BACKUP_CODES_DESC') }}
              </p>
              <button
                class="w-full px-3 py-2 bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-700 text-sm font-medium"
                @click="showRegenerateDialog = true"
              >
                {{ $t('MFA_SETTINGS.MANAGEMENT.REGENERATE') }}
              </button>
            </div>

            <!-- Disable MFA -->
            <div
              class="border border-red-200 dark:border-red-900 rounded-lg p-4"
            >
              <h4 class="font-medium text-slate-900 dark:text-slate-100 mb-2">
                {{ $t('MFA_SETTINGS.MANAGEMENT.DISABLE_MFA') }}
              </h4>
              <p class="text-sm text-slate-600 dark:text-slate-400 mb-4">
                {{ $t('MFA_SETTINGS.MANAGEMENT.DISABLE_MFA_DESC') }}
              </p>
              <button
                class="w-full px-3 py-2 bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400 border border-red-200 dark:border-red-800 rounded-lg hover:bg-red-100 dark:hover:bg-red-900/30 text-sm font-medium"
                @click="showDisableDialog = true"
              >
                {{ $t('MFA_SETTINGS.MANAGEMENT.DISABLE_BUTTON') }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Disable MFA Modal -->
    <div v-if="showDisableDialog" class="fixed inset-0 z-50 overflow-y-auto">
      <div
        class="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0"
      >
        <div
          class="fixed inset-0 transition-opacity"
          @click="showDisableDialog = false"
        >
          <div class="absolute inset-0 bg-gray-500 opacity-75" />
        </div>

        <div
          class="inline-block align-bottom bg-white dark:bg-slate-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
        >
          <div class="bg-white dark:bg-slate-800 px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div class="sm:flex sm:items-start">
              <div
                class="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-red-100 dark:bg-red-900/20 sm:mx-0 sm:h-10 sm:w-10"
              >
                <svg
                  class="h-6 w-6 text-red-600 dark:text-red-400"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                  />
                </svg>
              </div>
              <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                <h3
                  class="text-lg leading-6 font-medium text-gray-900 dark:text-gray-100"
                >
                  {{ $t('MFA_SETTINGS.DISABLE.TITLE') }}
                </h3>
                <div class="mt-2">
                  <p class="text-sm text-gray-500 dark:text-gray-400">
                    {{ $t('MFA_SETTINGS.DISABLE.DESCRIPTION') }}
                  </p>

                  <div class="mt-4 space-y-4">
                    <div>
                      <label
                        class="block text-sm font-medium text-gray-700 dark:text-gray-300"
                      >
                        {{ $t('MFA_SETTINGS.DISABLE.PASSWORD') }}
                      </label>
                      <input
                        v-model="disablePassword"
                        type="password"
                        class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-900 dark:text-slate-100"
                      />
                    </div>

                    <div>
                      <label
                        class="block text-sm font-medium text-gray-700 dark:text-gray-300"
                      >
                        {{ $t('MFA_SETTINGS.DISABLE.OTP_CODE') }}
                      </label>
                      <input
                        v-model="disableOtpCode"
                        type="text"
                        maxlength="6"
                        :placeholder="
                          $t('MFA_SETTINGS.DISABLE.OTP_CODE_PLACEHOLDER')
                        "
                        class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-900 dark:text-slate-100"
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div
            class="bg-gray-50 dark:bg-slate-900 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse"
          >
            <button
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm"
              @click="disableMfa"
            >
              {{ $t('MFA_SETTINGS.DISABLE.CONFIRM') }}
            </button>
            <button
              class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 dark:border-gray-600 shadow-sm px-4 py-2 bg-white dark:bg-slate-800 text-base font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
              @click="showDisableDialog = false"
            >
              {{ $t('MFA_SETTINGS.DISABLE.CANCEL') }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Regenerate Backup Codes Modal -->
    <div v-if="showRegenerateDialog" class="fixed inset-0 z-50 overflow-y-auto">
      <div
        class="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0"
      >
        <div
          class="fixed inset-0 transition-opacity"
          @click="showRegenerateDialog = false"
        >
          <div class="absolute inset-0 bg-gray-500 opacity-75" />
        </div>

        <div
          class="inline-block align-bottom bg-white dark:bg-slate-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
        >
          <div class="bg-white dark:bg-slate-800 px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <h3
              class="text-lg leading-6 font-medium text-gray-900 dark:text-gray-100"
            >
              {{ $t('MFA_SETTINGS.REGENERATE.TITLE') }}
            </h3>
            <div class="mt-2">
              <p class="text-sm text-gray-500 dark:text-gray-400">
                {{ $t('MFA_SETTINGS.REGENERATE.DESCRIPTION') }}
              </p>

              <div class="mt-4">
                <label
                  class="block text-sm font-medium text-gray-700 dark:text-gray-300"
                >
                  {{ $t('MFA_SETTINGS.REGENERATE.OTP_CODE') }}
                </label>
                <input
                  v-model="regenerateOtpCode"
                  type="text"
                  maxlength="6"
                  :placeholder="
                    $t('MFA_SETTINGS.REGENERATE.OTP_CODE_PLACEHOLDER')
                  "
                  class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-900 dark:text-slate-100"
                />
              </div>
            </div>
          </div>
          <div
            class="bg-gray-50 dark:bg-slate-900 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse"
          >
            <button
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:ml-3 sm:w-auto sm:text-sm"
              @click="regenerateBackupCodes"
            >
              {{ $t('MFA_SETTINGS.REGENERATE.CONFIRM') }}
            </button>
            <button
              class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 dark:border-gray-600 shadow-sm px-4 py-2 bg-white dark:bg-slate-800 text-base font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-slate-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
              @click="showRegenerateDialog = false"
            >
              {{ $t('MFA_SETTINGS.DISABLE.CANCEL') }}
            </button>
          </div>
        </div>
      </div>
    </div>
    <!-- Backup Codes Display Modal (for regenerated codes) -->
    <div v-if="showBackupCodesModal" class="fixed inset-0 z-50 overflow-y-auto">
      <div
        class="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0"
      >
        <div
          class="fixed inset-0 transition-opacity"
          @click="showBackupCodesModal = false"
        >
          <div class="absolute inset-0 bg-gray-500 opacity-75" />
        </div>

        <div
          class="inline-block align-bottom bg-white dark:bg-slate-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-2xl sm:w-full"
        >
          <div class="bg-white dark:bg-slate-800 px-4 pt-5 pb-4 sm:p-6">
            <div class="text-center mb-6">
              <div
                class="inline-flex items-center justify-center w-16 h-16 bg-green-100 dark:bg-green-900 rounded-full mb-4"
              >
                <svg
                  class="w-8 h-8 text-green-600 dark:text-green-400"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path
                    fill-rule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
              <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100">
                {{ $t('MFA_SETTINGS.REGENERATE.NEW_CODES_TITLE') }}
              </h3>
              <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
                {{ $t('MFA_SETTINGS.REGENERATE.NEW_CODES_DESC') }}
              </p>
            </div>

            <!-- Warning Alert -->
            <div
              class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-4 mb-4"
            >
              <div class="flex">
                <svg
                  class="w-5 h-5 text-amber-600 dark:text-amber-400 mr-2 flex-shrink-0 mt-0.5"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path
                    fill-rule="evenodd"
                    d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                    clip-rule="evenodd"
                  />
                </svg>
                <p class="text-sm text-amber-800 dark:text-amber-200">
                  <strong>
                    {{ $t('MFA_SETTINGS.REGENERATE.CODES_IMPORTANT') }}
                  </strong>
                  {{ $t('MFA_SETTINGS.REGENERATE.CODES_IMPORTANT_NOTE') }}
                </p>
              </div>
            </div>

            <!-- Backup Codes Display -->
            <div class="bg-slate-50 dark:bg-slate-900 rounded-lg p-6 mb-4">
              <div class="grid grid-cols-2 gap-3">
                <div
                  v-for="(code, index) in backupCodes"
                  :key="index"
                  class="font-mono text-sm bg-white dark:bg-slate-800 px-3 py-2 rounded border border-slate-200 dark:border-slate-700"
                >
                  {{ code }}
                </div>
              </div>
            </div>

            <!-- Actions -->
            <div class="flex items-center justify-center space-x-3 mb-4">
              <button
                class="inline-flex items-center px-4 py-2 bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded-lg text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-600"
                @click="downloadBackupCodes"
              >
                <svg
                  class="w-4 h-4 mr-2"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  />
                </svg>
                {{ $t('MFA_SETTINGS.REGENERATE.DOWNLOAD_CODES') }}
              </button>
              <button
                class="inline-flex items-center px-4 py-2 bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded-lg text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-600"
                @click="copyBackupCodes"
              >
                <svg
                  class="w-4 h-4 mr-2"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
                  />
                </svg>
                {{ $t('MFA_SETTINGS.REGENERATE.COPY_ALL_CODES') }}
              </button>
            </div>

            <div class="text-center">
              <button
                class="inline-flex justify-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium"
                @click="showBackupCodesModal = false"
              >
                {{ $t('MFA_SETTINGS.REGENERATE.CODES_SAVED') }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
