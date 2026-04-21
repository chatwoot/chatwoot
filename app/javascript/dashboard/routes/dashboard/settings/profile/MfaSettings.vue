<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import { parseBoolean } from '@chatwoot/utils';
import mfaAPI from 'dashboard/api/mfa';
import { useAlert } from 'dashboard/composables';
import MfaStatusCard from './MfaStatusCard.vue';
import MfaSetupWizard from './MfaSetupWizard.vue';
import MfaManagementActions from './MfaManagementActions.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

const { t } = useI18n();
const router = useRouter();
const route = useRoute();

// State
const mfaEnabled = ref(false);
const backupCodesGenerated = ref(false);
const showSetup = ref(false);
const provisioningUri = ref('');
const qrCodeUrl = ref('');
const secretKey = ref('');
const backupCodes = ref([]);

// Component refs
const setupWizardRef = ref(null);
const managementActionsRef = ref(null);

// Load MFA status on mount
onMounted(async () => {
  // Check if MFA is enabled globally
  if (!parseBoolean(window.chatwootConfig?.isMfaEnabled)) {
    // Redirect to profile settings if MFA is disabled
    router.push({
      name: 'profile_settings_index',
      params: {
        accountId: route.params.accountId,
      },
    });
    return;
  }

  try {
    const response = await mfaAPI.get();
    mfaEnabled.value = response.data.enabled;
    backupCodesGenerated.value = response.data.backup_codes_generated;
  } catch (error) {
    // Handle error silently
  }
});

// Start MFA setup
const startMfaSetup = async () => {
  try {
    const response = await mfaAPI.enable();

    // Store the provisioning URI
    provisioningUri.value =
      response.data.provisioning_uri || response.data.provisioning_url;

    // Store QR code URL if provided by backend
    if (response.data.qr_code_url) {
      qrCodeUrl.value = response.data.qr_code_url;
    }

    secretKey.value = response.data.secret;
    // Backup codes are now generated after verification, not during enable
    backupCodes.value = [];
    showSetup.value = true;
  } catch (error) {
    useAlert(t('MFA_SETTINGS.SETUP.ERROR_STARTING'));
  }
};

// Verify OTP code
const verifyCode = async verificationCode => {
  try {
    const response = await mfaAPI.verify(verificationCode);
    // Store backup codes returned from verification
    if (response.data.backup_codes) {
      backupCodes.value = response.data.backup_codes;
    }
    return true;
  } catch (error) {
    setupWizardRef.value?.handleVerificationError(
      error.response?.data?.error || t('MFA_SETTINGS.SETUP.INVALID_CODE')
    );
    throw error;
  }
};

// Complete MFA setup
const completeMfaSetup = () => {
  mfaEnabled.value = true;
  backupCodesGenerated.value = true;
  showSetup.value = false;
  useAlert(t('MFA_SETTINGS.SETUP.SUCCESS'));
};

// Cancel setup
const cancelSetup = () => {
  showSetup.value = false;
};

// Disable MFA
const disableMfa = async ({ password, otpCode }) => {
  try {
    await mfaAPI.disable(password, otpCode);
    mfaEnabled.value = false;
    backupCodesGenerated.value = false;
    managementActionsRef.value?.resetDisableForm();
    useAlert(t('MFA_SETTINGS.DISABLE.SUCCESS'));
  } catch (error) {
    useAlert(t('MFA_SETTINGS.DISABLE.ERROR'));
  }
};

// Regenerate backup codes
const regenerateBackupCodes = async ({ otpCode }) => {
  try {
    const response = await mfaAPI.regenerateBackupCodes(otpCode);
    backupCodes.value = response.data.backup_codes;
    managementActionsRef.value?.resetRegenerateForm();
    managementActionsRef.value?.showBackupCodesDialog();
    useAlert(t('MFA_SETTINGS.REGENERATE.SUCCESS'));
  } catch (error) {
    useAlert(t('MFA_SETTINGS.REGENERATE.ERROR'));
  }
};
</script>

<template>
  <div class="grid w-full">
    <BaseSettingsHeader
      :title="$t('MFA_SETTINGS.TITLE')"
      :description="$t('MFA_SETTINGS.SUBTITLE')"
      :back-button-label="$t('PROFILE_SETTINGS.TITLE')"
    />

    <div class="grid gap-4 w-full mt-4">
      <!-- MFA Status Card -->
      <MfaStatusCard
        :mfa-enabled="mfaEnabled"
        :show-setup="showSetup"
        @enable-mfa="startMfaSetup"
      />

      <!-- MFA Setup Wizard -->
      <MfaSetupWizard
        ref="setupWizardRef"
        :show-setup="showSetup"
        :mfa-enabled="mfaEnabled"
        :provisioning-uri="provisioningUri"
        :secret-key="secretKey"
        :backup-codes="backupCodes"
        :qr-code-url-prop="qrCodeUrl"
        @cancel="cancelSetup"
        @verify="verifyCode"
        @complete="completeMfaSetup"
      />

      <!-- MFA Management Actions -->
      <MfaManagementActions
        ref="managementActionsRef"
        :mfa-enabled="mfaEnabled"
        :backup-codes="backupCodes"
        @disable-mfa="disableMfa"
        @regenerate-backup-codes="regenerateBackupCodes"
      />
    </div>
  </div>
</template>
