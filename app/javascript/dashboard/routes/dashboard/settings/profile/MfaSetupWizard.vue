<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import QRCode from 'qrcode';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  showSetup: {
    type: Boolean,
    required: true,
  },
  mfaEnabled: {
    type: Boolean,
    required: true,
  },
  provisioningUri: {
    type: String,
    default: '',
  },
  secretKey: {
    type: String,
    default: '',
  },
  backupCodes: {
    type: Array,
    default: () => [],
  },
  qrCodeUrlProp: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['cancel', 'verify', 'complete']);

const { t } = useI18n();

// Local state
const setupStep = ref('qr');
const qrCodeUrl = ref('');
const verificationCode = ref('');
const verificationError = ref('');
const backupCodesConfirmed = ref(false);

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

// Watch for provisioning URI changes
watch(
  () => props.provisioningUri,
  async newUri => {
    if (newUri) {
      qrCodeUrl.value = await generateQRCode(newUri);
    } else if (props.qrCodeUrlProp) {
      qrCodeUrl.value = props.qrCodeUrlProp;
    }
  },
  { immediate: true }
);

const verifyCode = async () => {
  verificationError.value = '';
  try {
    emit('verify', verificationCode.value);
    setupStep.value = 'backup';
    verificationCode.value = '';
  } catch (error) {
    verificationError.value = t('MFA_SETTINGS.SETUP.INVALID_CODE');
  }
};

const copySecret = async () => {
  await copyTextToClipboard(props.secretKey);
  useAlert(t('MFA_SETTINGS.SETUP.SECRET_COPIED'));
};

const copyBackupCodes = async () => {
  const codesText = props.backupCodes.join('\n');
  await copyTextToClipboard(codesText);
  useAlert(t('MFA_SETTINGS.BACKUP.CODES_COPIED'));
};

const downloadBackupCodes = () => {
  const codesText = `Chatwoot Two-Factor Authentication Backup Codes\n\n${props.backupCodes.join('\n')}\n\nKeep these codes in a safe place.`;
  const blob = new Blob([codesText], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'chatwoot-backup-codes.txt';
  a.click();
  URL.revokeObjectURL(url);
};

const cancelSetup = () => {
  setupStep.value = 'qr';
  verificationCode.value = '';
  verificationError.value = '';
  backupCodesConfirmed.value = false;
  emit('cancel');
};

const completeMfaSetup = () => {
  setupStep.value = 'qr';
  backupCodesConfirmed.value = false;
  emit('complete');
};

// Reset when showSetup changes
watch(
  () => props.showSetup,
  newVal => {
    if (newVal) {
      setupStep.value = 'qr';
      verificationCode.value = '';
      verificationError.value = '';
      backupCodesConfirmed.value = false;
    }
  }
);

// Handle verification error
const handleVerificationError = error => {
  verificationError.value = error || t('MFA_SETTINGS.SETUP.INVALID_CODE');
};

defineExpose({
  handleVerificationError,
  setupStep,
});
</script>

<template>
  <div v-if="showSetup && !mfaEnabled">
    <!-- Step 1: QR Code -->
    <div v-if="setupStep === 'qr'" class="space-y-6">
      <div
        class="bg-n-solid-1 rounded-xl outline-1 outline-n-weak outline p-10 flex flex-col gap-4"
      >
        <div class="text-center">
          <h3 class="text-lg font-medium text-n-slate-12 mb-2">
            {{ $t('MFA_SETTINGS.SETUP.STEP1_TITLE') }}
          </h3>
          <p class="text-sm text-n-slate-11">
            {{ $t('MFA_SETTINGS.SETUP.STEP1_DESCRIPTION') }}
          </p>
        </div>
        <div class="flex justify-center">
          <div
            class="bg-n-background p-4 rounded-lg outline outline-1 outline-n-weak"
          >
            <img
              v-if="qrCodeUrl"
              :src="qrCodeUrl"
              alt="MFA QR Code"
              class="w-48 h-48 dark:invert-0"
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
              <Input :model-value="secretKey" readonly class="flex-1" />
              <Button
                variant="outline"
                color="slate"
                size="sm"
                :label="$t('MFA_SETTINGS.SETUP.COPY')"
                @click="copySecret"
              />
            </div>
          </div>
        </details>

        <div class="flex flex-col items-start gap-3 w-full">
          <Input
            v-model="verificationCode"
            type="text"
            maxlength="6"
            pattern="[0-9]{6}"
            :label="$t('MFA_SETTINGS.SETUP.ENTER_CODE')"
            :placeholder="$t('MFA_SETTINGS.SETUP.ENTER_CODE_PLACEHOLDER')"
            :message="verificationError"
            :message-type="verificationError ? 'error' : 'info'"
            class="w-full"
            @keyup.enter="verifyCode"
          />

          <div class="flex gap-3 mt-1 w-full justify-between">
            <Button
              faded
              color="slate"
              class="flex-1"
              :label="$t('MFA_SETTINGS.SETUP.CANCEL')"
              @click="cancelSetup"
            />
            <Button
              class="flex-1"
              :disabled="verificationCode.length !== 6"
              :label="$t('MFA_SETTINGS.SETUP.VERIFY_BUTTON')"
              @click="verifyCode"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Step 2: Backup Codes -->
    <div v-if="setupStep === 'backup'" class="space-y-6">
      <div class="text-start">
        <h3 class="text-lg font-medium text-n-slate-12 mb-2">
          {{ $t('MFA_SETTINGS.BACKUP.TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11">
          {{ $t('MFA_SETTINGS.BACKUP.DESCRIPTION') }}
        </p>
      </div>

      <!-- Warning Alert -->
      <div
        class="flex items-start gap-2 p-4 bg-n-solid-1 outline outline-n-weak rounded-xl outline-1"
      >
        <Icon
          icon="i-lucide-alert-circle"
          class="size-4 text-n-slate-10 flex-shrink-0 mt-0.5"
        />
        <p class="text-sm text-n-slate-11">
          <strong>{{ $t('MFA_SETTINGS.BACKUP.IMPORTANT') }}</strong>
          {{ $t('MFA_SETTINGS.BACKUP.IMPORTANT_NOTE') }}
        </p>
      </div>

      <!-- Backup Codes Grid -->
      <div
        class="bg-n-solid-1 rounded-xl outline-1 outline-n-weak outline flex flex-col gap-6 p-6"
      >
        <div class="grid grid-cols-2 xs:grid-cols-4 sm:grid-cols-5 gap-3">
          <span
            v-for="(code, index) in backupCodes"
            :key="index"
            class="px-1 py-2 font-mono text-base text-center text-n-slate-12"
          >
            {{ code }}
          </span>
        </div>

        <div class="flex items-center justify-center gap-3">
          <Button
            outline
            slate
            sm
            icon="i-lucide-download"
            :label="$t('MFA_SETTINGS.BACKUP.DOWNLOAD')"
            @click="downloadBackupCodes"
          />
          <Button
            outline
            slate
            sm
            icon="i-lucide-clipboard"
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

        <Button
          :disabled="!backupCodesConfirmed"
          :label="$t('MFA_SETTINGS.BACKUP.COMPLETE_SETUP')"
          @click="completeMfaSetup"
        />
      </div>
    </div>
  </div>
  <template v-else />
</template>
