<script setup>
import { ref } from 'vue';
import axios from 'axios';
import { useI18n } from 'vue-i18n';
import {
  parseAPIErrorResponse,
  setAuthCredentials,
} from 'dashboard/store/utils/api';
import MfaSetupWizard from 'dashboard/routes/dashboard/settings/profile/MfaSetupWizard.vue';

const props = defineProps({
  mfaSetupToken: {
    type: String,
    required: true,
  },
  provisioningUrl: {
    type: String,
    required: true,
  },
  secret: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['verified', 'cancel']);

const { t } = useI18n();

const setupWizardRef = ref(null);
const backupCodes = ref([]);
const authResponse = ref(null);

const onComplete = () => {
  if (!authResponse.value) return;
  setAuthCredentials(authResponse.value);
  emit('verified', authResponse.value.data);
};

const onVerify = async otpCode => {
  try {
    const response = await axios.post('/auth/sign_in', {
      mfa_setup_token: props.mfaSetupToken,
      otp_code: otpCode,
    });
    authResponse.value = response;
    backupCodes.value = response.data.backup_codes || [];
    if (!backupCodes.value.length) {
      onComplete();
    }
  } catch (error) {
    setupWizardRef.value?.handleVerificationError(
      parseAPIErrorResponse(error) || t('MFA_SETTINGS.SETUP.INVALID_CODE')
    );
  }
};
</script>

<template>
  <div
    class="bg-white shadow sm:mx-auto sm:w-full sm:max-w-lg dark:bg-n-solid-2 p-8 sm:shadow-lg sm:rounded-lg"
  >
    <div class="mb-6 text-center">
      <h2 class="text-lg font-medium text-n-slate-12 mb-2">
        {{ $t('MFA_ENFORCED_SETUP.TITLE') }}
      </h2>
      <p class="text-sm text-n-slate-11">
        {{ $t('MFA_ENFORCED_SETUP.DESCRIPTION') }}
      </p>
    </div>
    <MfaSetupWizard
      ref="setupWizardRef"
      show-setup
      :mfa-enabled="false"
      :provisioning-uri="provisioningUrl"
      :secret-key="secret"
      :backup-codes="backupCodes"
      @verify="onVerify"
      @complete="onComplete"
      @cancel="emit('cancel')"
    />
  </div>
</template>
