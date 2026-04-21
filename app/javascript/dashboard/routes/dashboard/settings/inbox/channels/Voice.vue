<script setup>
import { reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { isPhoneE164 } from 'shared/helpers/Validators';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import PageHeader from '../../SettingsSubPageHeader.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const store = useStore();
const router = useRouter();

const state = reactive({
  phoneNumber: '',
  accountSid: '',
  authToken: '',
  apiKeySid: '',
  apiKeySecret: '',
});

const uiFlags = useMapGetter('inboxes/getUIFlags');

const validationRules = {
  phoneNumber: { required, isPhoneE164 },
  accountSid: { required },
  authToken: { required },
  apiKeySid: { required },
  apiKeySecret: { required },
};

const v$ = useVuelidate(validationRules, state);
const isSubmitDisabled = computed(() => v$.value.$invalid);

const formErrors = computed(() => ({
  phoneNumber: v$.value.phoneNumber?.$error
    ? t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBER.ERROR')
    : '',
  accountSid: v$.value.accountSid?.$error
    ? t('INBOX_MGMT.ADD.VOICE.TWILIO.ACCOUNT_SID.REQUIRED')
    : '',
  authToken: v$.value.authToken?.$error
    ? t('INBOX_MGMT.ADD.VOICE.TWILIO.AUTH_TOKEN.REQUIRED')
    : '',
  apiKeySid: v$.value.apiKeySid?.$error
    ? t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.REQUIRED')
    : '',
  apiKeySecret: v$.value.apiKeySecret?.$error
    ? t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.REQUIRED')
    : '',
}));

function getProviderConfig() {
  const config = {
    account_sid: state.accountSid,
    auth_token: state.authToken,
    api_key_sid: state.apiKeySid,
    api_key_secret: state.apiKeySecret,
  };
  return config;
}

async function createChannel() {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  try {
    const channel = await store.dispatch('inboxes/createVoiceChannel', {
      name: `Voice (${state.phoneNumber})`,
      voice: {
        phone_number: state.phoneNumber,
        provider: 'twilio',
        provider_config: getProviderConfig(),
      },
    });

    router.replace({
      name: 'settings_inboxes_add_agents',
      params: { page: 'new', inbox_id: channel.id },
    });
  } catch (error) {
    useAlert(
      error.response?.data?.message ||
        t('INBOX_MGMT.ADD.VOICE.API.ERROR_MESSAGE')
    );
  }
}
</script>

<template>
  <div class="overflow-auto col-span-6 p-6 w-full h-full">
    <PageHeader
      :header-title="t('INBOX_MGMT.ADD.VOICE.TITLE')"
      :header-content="t('INBOX_MGMT.ADD.VOICE.DESC')"
    />

    <form
      class="flex flex-col gap-4 flex-wrap mx-0"
      @submit.prevent="createChannel"
    >
      <Input
        v-model="state.phoneNumber"
        :label="t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBER.LABEL')"
        :placeholder="t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBER.PLACEHOLDER')"
        :message="formErrors.phoneNumber"
        :message-type="formErrors.phoneNumber ? 'error' : 'info'"
        @blur="v$.phoneNumber?.$touch"
      />

      <Input
        v-model="state.accountSid"
        :label="t('INBOX_MGMT.ADD.VOICE.TWILIO.ACCOUNT_SID.LABEL')"
        :placeholder="t('INBOX_MGMT.ADD.VOICE.TWILIO.ACCOUNT_SID.PLACEHOLDER')"
        :message="formErrors.accountSid"
        :message-type="formErrors.accountSid ? 'error' : 'info'"
        @blur="v$.accountSid?.$touch"
      />

      <Input
        v-model="state.authToken"
        type="password"
        :label="t('INBOX_MGMT.ADD.VOICE.TWILIO.AUTH_TOKEN.LABEL')"
        :placeholder="t('INBOX_MGMT.ADD.VOICE.TWILIO.AUTH_TOKEN.PLACEHOLDER')"
        :message="formErrors.authToken"
        :message-type="formErrors.authToken ? 'error' : 'info'"
        @blur="v$.authToken?.$touch"
      />

      <Input
        v-model="state.apiKeySid"
        :label="t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.LABEL')"
        :placeholder="t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.PLACEHOLDER')"
        :message="formErrors.apiKeySid"
        :message-type="formErrors.apiKeySid ? 'error' : 'info'"
        @blur="v$.apiKeySid?.$touch"
      />

      <Input
        v-model="state.apiKeySecret"
        type="password"
        :label="t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.LABEL')"
        :placeholder="
          t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.PLACEHOLDER')
        "
        :message="formErrors.apiKeySecret"
        :message-type="formErrors.apiKeySecret ? 'error' : 'info'"
        @blur="v$.apiKeySecret?.$touch"
      />

      <div>
        <NextButton
          :is-loading="uiFlags.isCreating"
          :disabled="isSubmitDisabled"
          :label="t('INBOX_MGMT.ADD.VOICE.SUBMIT_BUTTON')"
          type="submit"
        />
      </div>
    </form>
  </div>
</template>
