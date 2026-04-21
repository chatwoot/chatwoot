<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  mfaEnabled: {
    type: Boolean,
    required: true,
  },
  backupCodes: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['disableMfa', 'regenerateBackupCodes']);

const { t } = useI18n();

// Dialog refs
const disableDialogRef = ref(null);
const regenerateDialogRef = ref(null);
const backupCodesDialogRef = ref(null);

// Form values
const disablePassword = ref('');
const disableOtpCode = ref('');
const regenerateOtpCode = ref('');

// Utility functions
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

const handleDisableMfa = async () => {
  emit('disableMfa', {
    password: disablePassword.value,
    otpCode: disableOtpCode.value,
  });
};

const handleRegenerateBackupCodes = async () => {
  emit('regenerateBackupCodes', {
    otpCode: regenerateOtpCode.value,
  });
};

// Methods exposed for parent component
const resetDisableForm = () => {
  disablePassword.value = '';
  disableOtpCode.value = '';
  disableDialogRef.value?.close();
};

const resetRegenerateForm = () => {
  regenerateOtpCode.value = '';
  regenerateDialogRef.value?.close();
};

const showBackupCodesDialog = () => {
  backupCodesDialogRef.value?.open();
};

defineExpose({
  resetDisableForm,
  resetRegenerateForm,
  showBackupCodesDialog,
});
</script>

<template>
  <div v-if="mfaEnabled">
    <!-- Actions Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <!-- Regenerate Backup Codes -->
      <div class="bg-n-solid-1 rounded-xl outline-1 outline-n-weak outline p-5">
        <div class="flex-1 flex flex-col gap-2">
          <div class="flex items-center gap-2">
            <Icon
              icon="i-lucide-key"
              class="size-4 flex-shrink-0 text-n-slate-11"
            />
            <h4 class="font-medium text-n-slate-12">
              {{ $t('MFA_SETTINGS.MANAGEMENT.BACKUP_CODES') }}
            </h4>
          </div>
          <p class="text-sm text-n-slate-11">
            {{ $t('MFA_SETTINGS.MANAGEMENT.BACKUP_CODES_DESC') }}
          </p>
          <Button
            faded
            slate
            :label="$t('MFA_SETTINGS.MANAGEMENT.REGENERATE')"
            @click="regenerateDialogRef?.open()"
          />
        </div>
      </div>

      <!-- Disable MFA -->
      <div class="bg-n-solid-1 rounded-xl outline-1 outline-n-weak outline p-5">
        <div class="flex-1 flex flex-col gap-2">
          <div class="flex items-center gap-2">
            <Icon
              icon="i-lucide-lock-keyhole-open"
              class="size-4 flex-shrink-0 text-n-slate-11"
            />
            <h4 class="font-medium text-n-slate-12">
              {{ $t('MFA_SETTINGS.MANAGEMENT.DISABLE_MFA') }}
            </h4>
          </div>
          <p class="text-sm text-n-slate-11">
            {{ $t('MFA_SETTINGS.MANAGEMENT.DISABLE_MFA_DESC') }}
          </p>
          <Button
            faded
            ruby
            :label="$t('MFA_SETTINGS.MANAGEMENT.DISABLE_BUTTON')"
            @click="disableDialogRef?.open()"
          />
        </div>
      </div>
    </div>

    <!-- Disable MFA Dialog -->
    <Dialog
      ref="disableDialogRef"
      type="alert"
      :title="$t('MFA_SETTINGS.DISABLE.TITLE')"
      :description="$t('MFA_SETTINGS.DISABLE.DESCRIPTION')"
      :confirm-button-label="$t('MFA_SETTINGS.DISABLE.CONFIRM')"
      :cancel-button-label="$t('MFA_SETTINGS.DISABLE.CANCEL')"
      @confirm="handleDisableMfa"
    >
      <div class="space-y-4">
        <Input
          v-model="disablePassword"
          type="password"
          :label="$t('MFA_SETTINGS.DISABLE.PASSWORD')"
        />
        <Input
          v-model="disableOtpCode"
          type="text"
          maxlength="6"
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
      @confirm="handleRegenerateBackupCodes"
    >
      <Input
        v-model="regenerateOtpCode"
        type="text"
        maxlength="6"
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
    </Dialog>
  </div>
  <template v-else />
</template>
