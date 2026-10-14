<script setup>
import { computed, onMounted, reactive, ref, watchEffect } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import NextInput from 'dashboard/components-next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  inbox: { type: Object, required: true },
});

const store = useStore();
const { t } = useI18n();
const isUpdating = ref(false);
const isLoading = ref(true);
const secretVisible = ref(false);
const form = reactive({
  account_id: props.inbox.provider_config?.account_id || '',
  application_id: props.inbox.provider_config?.application_id || '',
  client_id: props.inbox.provider_config?.client_id || '',
  client_secret: '',
});
watchEffect(() => {
  form.account_id = props.inbox.provider_config?.account_id || '';
  form.application_id = props.inbox.provider_config?.application_id || '';
});
const fields = computed(() => [
  {
    key: 'account_id',
    readonly: true,
    label: t('INBOX_MGMT.ADD.SMS.BANDWIDTH.ACCOUNT_ID.LABEL'),
    placeholder: t('INBOX_MGMT.ADD.SMS.BANDWIDTH.ACCOUNT_ID.PLACEHOLDER'),
  },
  {
    key: 'application_id',
    readonly: true,
    label: t('INBOX_MGMT.ADD.SMS.BANDWIDTH.APPLICATION_ID.LABEL'),
    placeholder: t('INBOX_MGMT.ADD.SMS.BANDWIDTH.APPLICATION_ID.PLACEHOLDER'),
  },
  {
    key: 'client_id',
    label: t('INBOX_MGMT.ADD.SMS.BANDWIDTH.CLIENT_ID.LABEL'),
    placeholder: t('INBOX_MGMT.ADD.SMS.BANDWIDTH.CLIENT_ID.PLACEHOLDER'),
  },
  {
    key: 'client_secret',
    label: t('INBOX_MGMT.ADD.SMS.BANDWIDTH.CLIENT_SECRET.LABEL'),
    placeholder: t('INBOX_MGMT.ADD.SMS.BANDWIDTH.CLIENT_SECRET.PLACEHOLDER'),
  },
]);
const isDisabled = computed(
  () =>
    isLoading.value ||
    isUpdating.value ||
    fields.value.some(field => !form[field.key].trim())
);

onMounted(async () => {
  try {
    const inbox = await store.dispatch('inboxes/getItem', props.inbox.id);
    form.client_id = inbox.provider_config?.client_id || '';
    isLoading.value = false;
  } catch (error) {
    useAlert(
      error.message || t('INBOX_MGMT.ADD.SMS.BANDWIDTH.OAUTH.LOAD_ERROR')
    );
  }
});

const saveCredentials = async () => {
  if (isDisabled.value) return;

  isUpdating.value = true;
  try {
    await store.dispatch('inboxes/updateInbox', {
      id: props.inbox.id,
      formData: false,
      channel: {
        provider_config: {
          client_id: form.client_id,
          client_secret: form.client_secret,
        },
      },
    });
    form.client_secret = '';
    secretVisible.value = false;
    useAlert(t('INBOX_MGMT.ADD.SMS.BANDWIDTH.OAUTH.SUCCESS'));
  } catch (error) {
    useAlert(error.message || t('INBOX_MGMT.ADD.SMS.BANDWIDTH.OAUTH.ERROR'));
  } finally {
    isUpdating.value = false;
  }
};
</script>

<template>
  <div>
    <SettingsFieldSection
      class="[&>div>label]:self-start"
      :label="t('INBOX_MGMT.ADD.SMS.BANDWIDTH.OAUTH.TITLE')"
      :help-text="
        inbox.bandwidth_oauth_enabled
          ? t('INBOX_MGMT.ADD.SMS.BANDWIDTH.OAUTH.DESCRIPTION')
          : ''
      "
    >
      <form class="flex flex-col gap-4" @submit.prevent="saveCredentials">
        <div v-for="field in fields" :key="field.key" class="relative">
          <NextInput
            v-model="form[field.key]"
            :type="
              field.key === 'client_secret' && !secretVisible
                ? 'password'
                : 'text'
            "
            :label="field.label"
            :placeholder="field.placeholder"
            :readonly="field.readonly"
            :message="
              field.readonly
                ? t('INBOX_MGMT.ADD.SMS.BANDWIDTH.OAUTH.READ_ONLY')
                : ''
            "
            :custom-input-class="{
              '!text-n-slate-11 !bg-n-slate-2': field.readonly,
              '!pe-12': field.key === 'client_secret',
            }"
            :disabled="isLoading || isUpdating"
          />
          <NextButton
            v-if="field.key === 'client_secret'"
            type="button"
            class="absolute end-1 bottom-1"
            :icon="secretVisible ? 'i-lucide-eye-off' : 'i-lucide-eye'"
            :aria-label="
              secretVisible
                ? t('INBOX_MGMT.ADD.SMS.BANDWIDTH.OAUTH.HIDE_SECRET')
                : t('INBOX_MGMT.ADD.SMS.BANDWIDTH.OAUTH.SHOW_SECRET')
            "
            :aria-pressed="secretVisible"
            :disabled="isLoading || isUpdating"
            slate
            ghost
            sm
            @click="secretVisible = !secretVisible"
          />
        </div>
        <NextButton
          type="submit"
          class="self-start"
          :label="t('INBOX_MGMT.ADD.SMS.BANDWIDTH.OAUTH.SAVE')"
          :is-loading="isUpdating"
          :disabled="isDisabled"
        />
      </form>
    </SettingsFieldSection>
    <SettingsFieldSection
      :label="t('INBOX_MGMT.ADD.SMS.BANDWIDTH.API_CALLBACK.TITLE')"
      :help-text="t('INBOX_MGMT.ADD.SMS.BANDWIDTH.OAUTH.CALLBACK_DESCRIPTION')"
    >
      <woot-code :script="inbox.callback_webhook_url" />
    </SettingsFieldSection>
  </div>
</template>
