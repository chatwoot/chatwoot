<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { formatDistanceToNow, fromUnixTime } from 'date-fns';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import passkeysAPI from 'dashboard/api/passkeys';
import {
  createPasskey,
  isPasskeySupported,
  isPasskeyPromptDismissed,
} from 'dashboard/helper/webauthn';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const { t } = useI18n();

const passkeys = ref([]);
const secondFactorRequired = ref(false);
const supported = isPasskeySupported();

const addDialogRef = ref(null);
const removeDialogRef = ref(null);
const isAdding = ref(false);
const name = ref('');
const password = ref('');
const otpCode = ref('');
const passkeyToRemove = ref(null);

const relativeTime = timestamp =>
  formatDistanceToNow(fromUnixTime(timestamp), { addSuffix: true });

const fetchPasskeys = async () => {
  try {
    const { data } = await passkeysAPI.get();
    passkeys.value = data.payload;
    secondFactorRequired.value = data.second_factor_required;
  } catch {
    useAlert(t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.FETCH_ERROR'));
  }
};

const openAddDialog = () => {
  name.value = '';
  password.value = '';
  otpCode.value = '';
  addDialogRef.value?.open();
};

const addPasskey = async () => {
  isAdding.value = true;
  try {
    const { data: options } = await passkeysAPI.registrationOptions({
      password: password.value,
      otpCode: otpCode.value,
    });
    const credential = await createPasskey(options);
    const { data: passkey } = await passkeysAPI.register(
      credential,
      name.value
    );
    passkeys.value = [...passkeys.value, passkey];
    addDialogRef.value?.close();
    useAlert(t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.ADD_SUCCESS'));
  } catch (error) {
    if (isPasskeyPromptDismissed(error)) return;

    useAlert(
      error?.response
        ? parseAPIErrorResponse(error)
        : t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.ADD_ERROR')
    );
  } finally {
    isAdding.value = false;
  }
};

const confirmRemove = passkey => {
  passkeyToRemove.value = passkey;
  removeDialogRef.value?.open();
};

const removePasskey = async () => {
  const passkey = passkeyToRemove.value;
  try {
    await passkeysAPI.delete(passkey.id);
    passkeys.value = passkeys.value.filter(item => item.id !== passkey.id);
    useAlert(t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.REMOVE_SUCCESS'));
  } catch {
    useAlert(t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.REMOVE_ERROR'));
  } finally {
    removeDialogRef.value?.close();
    passkeyToRemove.value = null;
  }
};

onMounted(fetchPasskeys);
</script>

<template>
  <div class="flex flex-col gap-3">
    <p
      v-if="!passkeys.length"
      class="text-body-para text-n-slate-11"
      data-testid="passkeys-empty"
    >
      {{ $t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.EMPTY') }}
    </p>
    <div
      v-for="passkey in passkeys"
      :key="passkey.id"
      class="flex items-center justify-between gap-4 rounded-xl border border-n-slate-4 bg-n-background p-4"
    >
      <div class="flex items-start gap-3">
        <Icon
          icon="i-lucide-key-round"
          class="size-5 mt-0.5 text-n-slate-10 flex-shrink-0"
        />
        <div class="flex flex-col gap-1">
          <div class="flex items-center gap-2">
            <span class="text-heading-3 text-n-slate-12">
              {{ passkey.name }}
            </span>
            <span
              v-if="passkey.backed_up"
              class="rounded-full bg-n-slate-3 px-2 py-0.5 text-caption text-n-slate-11"
            >
              {{ $t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.SYNCED') }}
            </span>
          </div>
          <div class="flex flex-wrap gap-x-3 text-body-b3 text-n-slate-10">
            <span>
              {{ $t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.CREATED') }}
              {{ relativeTime(passkey.created_at) }}
            </span>
            <span v-if="passkey.last_used_at">
              {{ $t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.LAST_USED') }}
              {{ relativeTime(passkey.last_used_at) }}
            </span>
            <span v-else>
              {{ $t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.NEVER_USED') }}
            </span>
          </div>
        </div>
      </div>
      <Button
        type="button"
        faded
        xs
        color="ruby"
        :label="$t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.REMOVE')"
        @click="confirmRemove(passkey)"
      />
    </div>
    <div>
      <Button
        v-if="supported"
        type="button"
        faded
        icon="i-lucide-plus"
        data-testid="add-passkey"
        :label="$t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.ADD')"
        @click="openAddDialog"
      />
      <p v-else class="text-body-b3 text-n-slate-10">
        {{ $t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.UNSUPPORTED') }}
      </p>
    </div>

    <Dialog
      ref="addDialogRef"
      type="edit"
      :title="$t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.ADD_DIALOG.TITLE')"
      :description="
        $t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.ADD_DIALOG.DESCRIPTION')
      "
      :confirm-button-label="
        $t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.ADD_DIALOG.CONFIRM')
      "
      :cancel-button-label="
        $t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.ADD_DIALOG.CANCEL')
      "
      :is-loading="isAdding"
      :disable-confirm-button="!password || (secondFactorRequired && !otpCode)"
      @confirm="addPasskey"
    >
      <div class="space-y-4">
        <Input
          v-model="name"
          type="text"
          maxlength="64"
          :label="$t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.ADD_DIALOG.NAME')"
          :placeholder="
            $t(
              'PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.ADD_DIALOG.NAME_PLACEHOLDER'
            )
          "
        />
        <Input
          v-model="password"
          type="password"
          :label="
            $t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.ADD_DIALOG.PASSWORD')
          "
        />
        <Input
          v-if="secondFactorRequired"
          v-model="otpCode"
          type="text"
          maxlength="6"
          :label="
            $t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.ADD_DIALOG.OTP_CODE')
          "
          :placeholder="
            $t(
              'PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.ADD_DIALOG.OTP_CODE_PLACEHOLDER'
            )
          "
        />
      </div>
    </Dialog>

    <Dialog
      ref="removeDialogRef"
      type="alert"
      :title="$t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.REMOVE_DIALOG.TITLE')"
      :description="
        $t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.REMOVE_DIALOG.DESCRIPTION')
      "
      :confirm-button-label="
        $t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.REMOVE_DIALOG.CONFIRM')
      "
      :cancel-button-label="
        $t('PROFILE_SETTINGS.FORM.PASSKEYS_SECTION.REMOVE_DIALOG.CANCEL')
      "
      @confirm="removePasskey"
    />
  </div>
</template>
