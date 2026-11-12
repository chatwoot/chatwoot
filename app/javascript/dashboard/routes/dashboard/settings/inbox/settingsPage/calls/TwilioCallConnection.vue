<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import NextInput from 'dashboard/components-next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import CallSettingsOption from './CallSettingsOption.vue';

// Turns calling on for a Twilio number, and shows or replaces the credentials it uses. Saves on
// its own, since Twilio is set up for the number as it is turned on.
const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();

const wantsVoice = ref(false);
const isManaging = ref(false);
const isSaving = ref(false);
const apiKeySid = ref(props.inbox.api_key_sid || '');
const apiKeySecret = ref('');
const authToken = ref('');

watch(
  () => [props.inbox.id, props.inbox.voice_enabled],
  () => {
    wantsVoice.value = false;
    isManaging.value = false;
    apiKeySid.value = props.inbox.api_key_sid || '';
  }
);

const hasSavedCredentials = computed(
  () => !!props.inbox.api_key_sid && !!props.inbox.has_api_key_secret
);
// An SMS inbox turning calls on also needs the account's auth token, to verify Twilio's webhooks
const needsAuthToken = computed(
  () => !!props.inbox.api_key_sid && !props.inbox.account_auth_token_configured
);
const showsKeyFields = computed(
  () => isManaging.value || !hasSavedCredentials.value
);
const showsForm = computed(
  () =>
    isManaging.value ||
    (wantsVoice.value && (!hasSavedCredentials.value || needsAuthToken.value))
);
const maskedAccountSid = computed(() => {
  const sid = props.inbox.account_sid;
  return sid ? `${sid.slice(0, 2)}…${sid.slice(-4)}` : '';
});
const canSubmit = computed(() => {
  if (needsAuthToken.value && !authToken.value) return false;
  if (showsKeyFields.value) return !!apiKeySid.value && !!apiKeySecret.value;
  return true;
});

const save = async voiceEnabled => {
  isSaving.value = true;
  const channel = { voice_enabled: voiceEnabled };
  if (voiceEnabled && needsAuthToken.value)
    channel.auth_token = authToken.value;
  if (voiceEnabled && showsKeyFields.value) {
    channel.api_key_sid = apiKeySid.value;
    channel.api_key_secret = apiKeySecret.value;
  }
  try {
    await store.dispatch('inboxes/updateInbox', {
      id: props.inbox.id,
      formData: false,
      channel,
    });
    apiKeySecret.value = '';
    authToken.value = '';
    isManaging.value = false;
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (_) {
    useAlert(t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
  } finally {
    isSaving.value = false;
  }
};

// Saved credentials turn calling on straight away; otherwise the form asks for them first
const toggleVoice = value => {
  wantsVoice.value = value;
  if (value && !showsForm.value) save(true);
};
</script>

<template>
  <div
    class="flex flex-col gap-4"
    :class="{ 'pointer-events-none opacity-60': isSaving }"
  >
    <CallSettingsOption
      v-if="!inbox.voice_enabled"
      :model-value="wantsVoice"
      :label="t('INBOX_MGMT.CALL_SETTINGS.CALLING.ENABLE')"
      :help="t('INBOX_MGMT.CALL_SETTINGS.CALLING.ENABLE_HELP')"
      @update:model-value="toggleVoice"
    />
    <div v-else class="flex flex-wrap items-center gap-2 text-body-main">
      <span
        class="px-2 py-0.5 rounded-md bg-n-teal-3 text-n-teal-11 font-mono text-sm"
      >
        {{ t('INBOX_MGMT.CALL_SETTINGS.CALLING.CONNECTED') }}
      </span>
      <span v-if="maskedAccountSid" class="text-n-slate-12">
        {{
          t('INBOX_MGMT.CALL_SETTINGS.CALLING.TWILIO_ACCOUNT', {
            sid: maskedAccountSid,
          })
        }}
      </span>
      <NextButton
        :label="
          isManaging
            ? t('INBOX_MGMT.CALL_SETTINGS.CALLING.HIDE_CONNECTION')
            : t('INBOX_MGMT.CALL_SETTINGS.CALLING.MANAGE_CONNECTION')
        "
        link
        sm
        @click="isManaging = !isManaging"
      />
    </div>
    <div
      v-if="showsForm"
      class="flex flex-col gap-4 p-4 rounded-xl outline outline-1 -outline-offset-1 outline-n-weak"
    >
      <p class="text-body-main text-n-slate-11">
        {{
          isManaging
            ? t('INBOX_MGMT.CALL_SETTINGS.CALLING.REPLACE_HELP')
            : t('INBOX_MGMT.CALL_SETTINGS.CALLING.CREDENTIALS_HELP')
        }}
      </p>
      <template v-if="showsKeyFields">
        <NextInput
          v-model="apiKeySid"
          :label="t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.LABEL')"
          :placeholder="
            t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SID.PLACEHOLDER')
          "
        />
        <NextInput
          v-model="apiKeySecret"
          type="password"
          :label="t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.LABEL')"
          :placeholder="
            t('INBOX_MGMT.ADD.VOICE.TWILIO.API_KEY_SECRET.PLACEHOLDER')
          "
        />
      </template>
      <NextInput
        v-if="needsAuthToken"
        v-model="authToken"
        type="password"
        :label="t('INBOX_MGMT.ADD.VOICE.TWILIO.AUTH_TOKEN.LABEL')"
        :placeholder="t('INBOX_MGMT.ADD.VOICE.TWILIO.AUTH_TOKEN.PLACEHOLDER')"
      />
      <div class="flex items-center justify-end gap-2">
        <NextButton
          v-if="isManaging"
          :label="t('INBOX_MGMT.CALL_SETTINGS.CALLING.TURN_OFF')"
          ruby
          faded
          sm
          class="me-auto"
          @click="save(false)"
        />
        <NextButton
          :label="
            isManaging
              ? t('INBOX_MGMT.CALL_SETTINGS.CALLING.UPDATE_CONNECTION')
              : t('INBOX_MGMT.CALL_SETTINGS.CALLING.CONNECT')
          "
          :disabled="!canSubmit"
          :is-loading="isSaving"
          sm
          @click="save(true)"
        />
      </div>
    </div>
  </div>
</template>
