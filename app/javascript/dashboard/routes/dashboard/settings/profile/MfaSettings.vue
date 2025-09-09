<script setup>
import { ref, onMounted } from 'vue';
import QRCode from 'qrcode';
import mfaAPI from 'dashboard/api/mfa';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useAlert } from 'dashboard/composables';
import FormSection from 'dashboard/components/FormSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

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

// Dialog refs
const disableDialogRef = ref(null);
const regenerateDialogRef = ref(null);
const backupCodesDialogRef = ref(null);
const disablePassword = ref('');
const disableOtpCode = ref('');
const regenerateOtpCode = ref('');

// Input styles to match other profile sections
const inputStyles = {
  borderRadius: '0.75rem',
  padding: '0.375rem 0.75rem',
  fontSize: '0.875rem',
  marginBottom: '0.125rem',
};

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
  useAlert('Two-factor authentication has been enabled successfully');
};

// Disable MFA
const disableMfa = async () => {
  try {
    await mfaAPI.disable(disablePassword.value, disableOtpCode.value);
    mfaEnabled.value = false;
    backupCodesGenerated.value = false;
    disableDialogRef.value?.close();
    disablePassword.value = '';
    disableOtpCode.value = '';
    useAlert('Two-factor authentication has been disabled');
  } catch (error) {
    useAlert('Failed to disable MFA. Please check your credentials.');
  }
};

// Regenerate backup codes
const regenerateBackupCodes = async () => {
  try {
    const response = await mfaAPI.regenerateBackupCodes(
      regenerateOtpCode.value
    );
    backupCodes.value = response.data.backup_codes;
    regenerateDialogRef.value?.close();
    regenerateOtpCode.value = '';
    backupCodesDialogRef.value?.open();
    useAlert('New backup codes have been generated');
  } catch (error) {
    useAlert('Failed to regenerate backup codes');
  }
};

// Utility functions
const copySecret = async () => {
  await copyTextToClipboard(secretKey.value);
  useAlert('Secret key copied to clipboard');
};

const copyBackupCodes = async () => {
  const codesText = backupCodes.value.join('\n');
  await copyTextToClipboard(codesText);
  useAlert('Backup codes copied to clipboard');
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

const cancelSetup = () => {
  showSetup.value = false;
  setupStep.value = 'qr';
  verificationCode.value = '';
  verificationError.value = '';
  backupCodesConfirmed.value = false;
};
</script>

<template>
  <div class="grid py-16 px-5 font-inter mx-auto gap-16 sm:max-w-screen-md">
    <!-- Page Header -->
    <div class="flex flex-col gap-6">
      <h2 class="text-2xl font-medium text-n-slate-12">
        {{ $t('MFA_SETTINGS.TITLE') }}
      </h2>
      <p class="text-sm text-n-slate-11">
        {{ $t('MFA_SETTINGS.SUBTITLE') }}
      </p>
    </div>

    <!-- MFA Status Section -->
    <FormSection
      :title="$t('MFA_SETTINGS.STATUS_TITLE')"
      :description="$t('MFA_SETTINGS.STATUS_DESCRIPTION')"
    >
      <!-- MFA Setup Flow -->
      <div v-if="showSetup && !mfaEnabled">
        <!-- Step 1: QR Code -->
        <div v-if="setupStep === 'qr'" class="space-y-6">
          <div class="text-center">
            <h3 class="text-lg font-medium text-n-slate-12 mb-2">
              {{ $t('MFA_SETTINGS.SETUP.STEP1_TITLE') }}
            </h3>
            <p class="text-sm text-n-slate-11">
              {{ $t('MFA_SETTINGS.SETUP.STEP1_DESCRIPTION') }}
            </p>
          </div>

          <!-- QR Code Display -->
          <div class="flex justify-center">
            <div
              class="bg-white dark:bg-n-slate-3 p-4 rounded-lg border-2 border-n-slate-4 dark:border-n-slate-6"
            >
              <img
                v-if="qrCodeUrl"
                :src="qrCodeUrl"
                alt="MFA QR Code"
                class="w-48 h-48"
              />
              <div
                v-else
                class="w-48 h-48 flex items-center justify-center bg-n-slate-2 dark:bg-n-slate-3"
              >
                <span class="text-n-slate-10">
                  {{ $t('MFA_SETTINGS.SETUP.LOADING_QR') }}
                </span>
              </div>
            </div>
          </div>

          <!-- Manual Entry Option -->
          <details class="border border-n-slate-4 rounded-lg">
            <summary
              class="px-4 py-3 cursor-pointer hover:bg-n-slate-2 dark:hover:bg-n-slate-3 text-sm font-medium text-n-slate-11"
            >
              {{ $t('MFA_SETTINGS.SETUP.MANUAL_ENTRY') }}
            </summary>
            <div class="px-4 pb-4">
              <label class="block text-xs text-n-slate-10 mb-2">
                {{ $t('MFA_SETTINGS.SETUP.SECRET_KEY') }}
              </label>
              <div class="flex items-center gap-2">
                <woot-input
                  :value="secretKey"
                  readonly
                  :styles="inputStyles"
                  class="flex-1"
                />
                <NextButton
                  variant="outline"
                  color="slate"
                  size="sm"
                  :label="$t('MFA_SETTINGS.SETUP.COPY')"
                  @click="copySecret"
                />
              </div>
            </div>
          </details>

          <!-- Verification Input -->
          <div class="space-y-4">
            <woot-input
              v-model="verificationCode"
              type="text"
              maxlength="6"
              pattern="[0-9]{6}"
              :styles="inputStyles"
              :label="$t('MFA_SETTINGS.SETUP.ENTER_CODE')"
              :placeholder="$t('MFA_SETTINGS.SETUP.ENTER_CODE_PLACEHOLDER')"
              :error="verificationError"
              @keyup.enter="verifyCode"
            />

            <div class="flex gap-3">
              <NextButton
                variant="outline"
                color="slate"
                :label="$t('MFA_SETTINGS.SETUP.CANCEL')"
                @click="cancelSetup"
              />
              <NextButton
                :disabled="verificationCode.length !== 6"
                :label="$t('MFA_SETTINGS.SETUP.VERIFY_BUTTON')"
                @click="verifyCode"
              />
            </div>
          </div>
        </div>

        <!-- Step 2: Backup Codes -->
        <div v-if="setupStep === 'backup'" class="space-y-6">
          <div class="text-center">
            <h3 class="text-lg font-medium text-n-slate-12 mb-2">
              {{ $t('MFA_SETTINGS.BACKUP.TITLE') }}
            </h3>
            <p class="text-sm text-n-slate-11">
              {{ $t('MFA_SETTINGS.BACKUP.DESCRIPTION') }}
            </p>
          </div>

          <!-- Warning Alert -->
          <div
            class="bg-n-slate-2 dark:bg-n-solid-3 border border-n-slate-4 dark:border-n-slate-6 rounded-lg p-4"
          >
            <div class="flex">
              <i
                class="fluent-icon icon-warning text-xl text-n-slate-10 mr-2 flex-shrink-0 mt-0.5"
              />
              <p class="text-sm text-n-slate-11">
                <strong>{{ $t('MFA_SETTINGS.BACKUP.IMPORTANT') }}</strong>
                {{ $t('MFA_SETTINGS.BACKUP.IMPORTANT_NOTE') }}
              </p>
            </div>
          </div>

          <!-- Backup Codes Grid -->
          <div class="bg-n-slate-2 dark:bg-n-solid-3 rounded-lg p-6">
            <div class="grid grid-cols-2 gap-3">
              <div
                v-for="(code, index) in backupCodes"
                :key="index"
                class="px-3 py-2 bg-white dark:bg-n-slate-3 border border-n-slate-4 dark:border-n-slate-6 rounded font-mono text-sm text-center text-n-slate-12"
              >
                {{ code }}
              </div>
            </div>

            <div class="mt-6 flex items-center justify-center gap-3">
              <NextButton
                variant="outline"
                color="slate"
                size="sm"
                icon="arrow-download"
                :label="$t('MFA_SETTINGS.BACKUP.DOWNLOAD')"
                @click="downloadBackupCodes"
              />
              <NextButton
                variant="outline"
                color="slate"
                size="sm"
                icon="clipboard-copy"
                :label="$t('MFA_SETTINGS.BACKUP.COPY_ALL')"
                @click="copyBackupCodes"
              />
            </div>
          </div>

          <!-- Confirmation -->
          <div class="space-y-4">
            <label class="flex items-start gap-3">
              <input
                v-model="backupCodesConfirmed"
                type="checkbox"
                class="mt-1 rounded border-n-slate-4 text-n-blue-9 focus:ring-n-blue-8"
              />
              <span class="text-sm text-n-slate-11">
                {{ $t('MFA_SETTINGS.BACKUP.CONFIRM') }}
              </span>
            </label>

            <NextButton
              :disabled="!backupCodesConfirmed"
              :label="$t('MFA_SETTINGS.BACKUP.COMPLETE_SETUP')"
              @click="completeMfaSetup"
            />
          </div>
        </div>
      </div>

      <!-- MFA Disabled State -->
      <div v-else-if="!mfaEnabled" class="space-y-6">
        <div
          class="bg-n-slate-2 dark:bg-n-solid-3 rounded-lg p-6 border border-n-slate-4 dark:border-n-slate-6 text-center"
        >
          <i
            class="fluent-icon icon-shield-keyhole text-5xl text-n-slate-10 mx-auto mb-4 block"
          />
          <h3 class="text-lg font-medium text-n-slate-12 mb-2">
            {{ $t('MFA_SETTINGS.ENHANCE_SECURITY') }}
          </h3>
          <p class="text-sm text-n-slate-11 mb-6 max-w-md mx-auto">
            {{ $t('MFA_SETTINGS.ENHANCE_SECURITY_DESC') }}
          </p>
          <NextButton
            icon="add"
            :label="$t('MFA_SETTINGS.ENABLE_BUTTON')"
            @click="startMfaSetup"
          />
        </div>
      </div>

      <!-- MFA Enabled State -->
      <div v-else class="space-y-6">
        <!-- Status Info -->
        <div
          class="bg-n-slate-2 dark:bg-n-solid-3 border border-n-slate-4 dark:border-n-slate-6 rounded-lg p-4"
        >
          <div class="flex">
            <i
              class="fluent-icon icon-checkmark-circle text-xl text-n-slate-10 mr-2"
            />
            <div>
              <p class="text-sm font-medium text-n-slate-12">
                {{ $t('MFA_SETTINGS.STATUS_ENABLED') }}
              </p>
              <p class="mt-1 text-sm text-n-slate-11">
                {{ $t('MFA_SETTINGS.STATUS_ENABLED_DESC') }}
              </p>
            </div>
          </div>
        </div>

        <!-- Actions -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <!-- Regenerate Backup Codes -->
          <div
            class="bg-n-slate-2 dark:bg-n-solid-3 border border-n-slate-4 dark:border-n-slate-6 rounded-lg p-5"
          >
            <div class="flex items-start space-x-3">
              <i class="fluent-icon icon-key text-xl text-n-slate-10 mt-0.5" />
              <div class="flex-1">
                <h4 class="font-medium text-n-slate-12 mb-2">
                  {{ $t('MFA_SETTINGS.MANAGEMENT.BACKUP_CODES') }}
                </h4>
                <p class="text-sm text-n-slate-11 mb-4">
                  {{ $t('MFA_SETTINGS.MANAGEMENT.BACKUP_CODES_DESC') }}
                </p>
                <NextButton
                  variant="outline"
                  color="slate"
                  size="sm"
                  :label="$t('MFA_SETTINGS.MANAGEMENT.REGENERATE')"
                  @click="regenerateDialogRef?.open()"
                />
              </div>
            </div>
          </div>

          <!-- Disable MFA -->
          <div
            class="bg-n-slate-2 dark:bg-n-solid-3 border border-n-slate-4 dark:border-n-slate-6 rounded-lg p-5"
          >
            <div class="flex items-start space-x-3">
              <i
                class="fluent-icon icon-lock-closed-key-open text-xl text-n-slate-10 mt-0.5"
              />
              <div class="flex-1">
                <h4 class="font-medium text-n-slate-12 mb-2">
                  {{ $t('MFA_SETTINGS.MANAGEMENT.DISABLE_MFA') }}
                </h4>
                <p class="text-sm text-n-slate-11 mb-4">
                  {{ $t('MFA_SETTINGS.MANAGEMENT.DISABLE_MFA_DESC') }}
                </p>
                <NextButton
                  variant="outline"
                  color="ruby"
                  size="sm"
                  :label="$t('MFA_SETTINGS.MANAGEMENT.DISABLE_BUTTON')"
                  @click="disableDialogRef?.open()"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </FormSection>

    <!-- Disable MFA Dialog -->
    <Dialog
      ref="disableDialogRef"
      type="alert"
      :title="$t('MFA_SETTINGS.DISABLE.TITLE')"
      :description="$t('MFA_SETTINGS.DISABLE.DESCRIPTION')"
      :confirm-button-label="$t('MFA_SETTINGS.DISABLE.CONFIRM')"
      :cancel-button-label="$t('MFA_SETTINGS.DISABLE.CANCEL')"
      @confirm="disableMfa"
    >
      <div class="space-y-4">
        <woot-input
          v-model="disablePassword"
          type="password"
          :styles="inputStyles"
          :label="$t('MFA_SETTINGS.DISABLE.PASSWORD')"
        />
        <woot-input
          v-model="disableOtpCode"
          type="text"
          maxlength="6"
          :styles="inputStyles"
          :label="$t('MFA_SETTINGS.DISABLE.OTP_CODE')"
          :placeholder="$t('MFA_SETTINGS.DISABLE.OTP_CODE_PLACEHOLDER')"
        />
      </div>
    </Dialog>

    <!-- Regenerate Backup Codes Dialog -->
    <Dialog
      ref="regenerateDialogRef"
      type="edit"
      :title="$t('MFA_SETTINGS.REGENERATE.TITLE')"
      :description="$t('MFA_SETTINGS.REGENERATE.DESCRIPTION')"
      :confirm-button-label="$t('MFA_SETTINGS.REGENERATE.CONFIRM')"
      :cancel-button-label="$t('MFA_SETTINGS.DISABLE.CANCEL')"
      @confirm="regenerateBackupCodes"
    >
      <woot-input
        v-model="regenerateOtpCode"
        type="text"
        maxlength="6"
        :styles="inputStyles"
        :label="$t('MFA_SETTINGS.REGENERATE.OTP_CODE')"
        :placeholder="$t('MFA_SETTINGS.REGENERATE.OTP_CODE_PLACEHOLDER')"
      />
    </Dialog>

    <!-- Backup Codes Display Dialog -->
    <Dialog
      ref="backupCodesDialogRef"
      type="edit"
      width="2xl"
      :title="$t('MFA_SETTINGS.REGENERATE.NEW_CODES_TITLE')"
      :description="$t('MFA_SETTINGS.REGENERATE.NEW_CODES_DESC')"
      :show-cancel-button="false"
      :confirm-button-label="$t('MFA_SETTINGS.REGENERATE.CODES_SAVED')"
      @confirm="backupCodesDialogRef?.close()"
    >
      <!-- Warning Alert -->
      <div
        class="bg-n-slate-2 dark:bg-n-solid-3 border border-n-slate-4 dark:border-n-slate-6 rounded-lg p-4 mb-4"
      >
        <div class="flex">
          <i
            class="fluent-icon icon-warning text-xl text-n-slate-10 mr-2 flex-shrink-0 mt-0.5"
          />
          <p class="text-sm text-n-slate-11">
            <strong>{{ $t('MFA_SETTINGS.REGENERATE.CODES_IMPORTANT') }}</strong>
            {{ $t('MFA_SETTINGS.REGENERATE.CODES_IMPORTANT_NOTE') }}
          </p>
        </div>
      </div>

      <!-- Backup Codes Display -->
      <div class="bg-n-slate-2 dark:bg-n-solid-3 rounded-lg p-6 mb-4">
        <div class="grid grid-cols-2 gap-3">
          <div
            v-for="(code, index) in backupCodes"
            :key="index"
            class="font-mono text-sm bg-white dark:bg-n-slate-3 px-3 py-2 rounded border border-n-slate-4 dark:border-n-slate-6 text-n-slate-12 text-center"
          >
            {{ code }}
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex items-center justify-center gap-3">
        <NextButton
          variant="outline"
          color="slate"
          size="sm"
          icon="arrow-download"
          :label="$t('MFA_SETTINGS.REGENERATE.DOWNLOAD_CODES')"
          @click="downloadBackupCodes"
        />
        <NextButton
          variant="outline"
          color="slate"
          size="sm"
          icon="clipboard-copy"
          :label="$t('MFA_SETTINGS.REGENERATE.COPY_ALL_CODES')"
          @click="copyBackupCodes"
        />
      </div>
    </Dialog>
  </div>
</template>
