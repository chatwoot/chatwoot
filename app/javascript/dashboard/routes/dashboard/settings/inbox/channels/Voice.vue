<script setup>
import { reactive, computed } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import PageHeader from '../../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const store = useStore();
const router = useRouter();

const validPhoneNumber = value => {
  if (!value) return true;
  return /^\+[1-9]\d{1,14}$/.test(value);
};

const state = reactive({
  phoneNumber: '',
  accountSid: '',
  authToken: '',
  apiKeySid: '',
  apiKeySecret: '',
  twimlAppSid: '',
});

const validationRules = {
  phoneNumber: { required, validPhoneNumber },
  accountSid: { required },
  authToken: { required },
  apiKeySid: { required },
  apiKeySecret: { required },
  twimlAppSid: { required },
};

const v$ = useVuelidate(validationRules, state);
const uiFlags = computed(() => store.getters['inboxes/getUIFlags']);
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
  twimlAppSid: v$.value.twimlAppSid?.$error
    ? t('INBOX_MGMT.ADD.VOICE.TWILIO.TWIML_APP_SID.REQUIRED')
    : '',
}));

function getProviderConfig() {
  const config = {
    account_sid: state.accountSid,
    auth_token: state.authToken,
    api_key_sid: state.apiKeySid,
    api_key_secret: state.apiKeySecret,
  };
  if (state.twimlAppSid) config.outgoing_application_sid = state.twimlAppSid;
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
  <div
    class="overflow-auto col-span-6 p-6 w-full h-full rounded-t-lg border border-b-0 border-n-weak bg-n-solid-1"
  >
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.VOICE.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.VOICE.DESC')"
    />

    <form class="flex flex-col flex-wrap mx-0" @submit.prevent="createChannel">
      <div>
        <div>
          <label :class="{ error: !!formErrors.phoneNumber }">
            {{ $t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBER.LABEL') }}
            <input
              v-model.trim="state.phoneNumber"
              type="text"
              :placeholder="$t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBER.PLACEHOLDER')"
              @blur="v$.value.phoneNumber?.$touch"
            />
            <span v-if="formErrors.phoneNumber" class="message">
              {{ formErrors.phoneNumber }}
            </span>
          </label>
        </div>

        <div>
          <label :class="{ error: !!formErrors.accountSid }">
            {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.ACCOUNT_SID.LABEL') }}
            <input
              v-model.trim="state.accountSid"
              type="text"
              :placeholder="
                $t('INBOX_MGMT.ADD.VOICE.TWILIO.ACCOUNT_SID.PLACEHOLDER')
              "
              @blur="v$.value.accountSid?.$touch"
            />
            <span v-if="formErrors.accountSid" class="message">
              {{ formErrors.accountSid }}
            </span>
          </label>
        </div>

        <div>
          <label :class="{ error: !!formErrors.authToken }">
            {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.AUTH_TOKEN.LABEL') }}
            <input
              v-model.trim="state.authToken"
              type="password"
              :placeholder="
                $t('INBOX_MGMT.ADD.VOICE.TWILIO.AUTH_TOKEN.PLACEHOLDER')
              "
              @blur="v$.value.authToken?.$touch"
            />
            <span v-if="formErrors.authToken" class="message">
              {{ formErrors.authToken }}
            </span>
          </label>
        </div>

        <div>
          <label :class="{ error: !!formErrors.apiKeySid }">
            {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.LABEL') }}
            <input
              v-model.trim="state.apiKeySid"
              type="text"
              :placeholder="
                $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.PLACEHOLDER')
              "
              @blur="v$.value.apiKeySid?.$touch"
            />
            <span v-if="formErrors.apiKeySid" class="message">
              {{ formErrors.apiKeySid }}
            </span>
          </label>
        </div>

        <div>
          <label :class="{ error: !!formErrors.apiKeySecret }">
            {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.LABEL') }}
            <input
              v-model.trim="state.apiKeySecret"
              type="password"
              :placeholder="
                $t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.PLACEHOLDER')
              "
              @blur="v$.value.apiKeySecret?.$touch"
            />
            <span v-if="formErrors.apiKeySecret" class="message">
              {{ formErrors.apiKeySecret }}
            </span>
          </label>
        </div>

        <div>
          <label :class="{ error: !!formErrors.twimlAppSid }">
            {{ $t('INBOX_MGMT.ADD.VOICE.TWILIO.TWIML_APP_SID.LABEL') }}
            <input
              v-model.trim="state.twimlAppSid"
              type="text"
              :placeholder="
                $t('INBOX_MGMT.ADD.VOICE.TWILIO.TWIML_APP_SID.PLACEHOLDER')
              "
              @blur="v$.value.twimlAppSid?.$touch"
            />
            <span v-if="formErrors.twimlAppSid" class="message">
              {{ formErrors.twimlAppSid }}
            </span>
          </label>
        </div>
      </div>

      <div class="mt-4">
        <NextButton
          :is-loading="uiFlags.isCreating"
          :is-disabled="isSubmitDisabled"
          :label="$t('INBOX_MGMT.ADD.VOICE.SUBMIT_BUTTON')"
          type="submit"
          color="blue"
        />
      </div>
    </form>
  </div>
</template>
