<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import AccessToken from 'dashboard/routes/dashboard/settings/profile/AccessToken.vue';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const enforced = ref(props.inbox.callback_auth_enforced);
const isUpdating = ref(false);

const copyPassword = async () => {
  try {
    await copyTextToClipboard(props.inbox.callback_auth_password);
    useAlert(t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
  } catch (error) {
    useAlert(t('COMPONENTS.CODE.COPY_ERROR'));
  }
};

const updateEnforced = async value => {
  isUpdating.value = true;
  try {
    await store.dispatch('inboxes/updateInbox', {
      id: props.inbox.id,
      formData: false,
      channel: { callback_auth_enforced: value },
    });
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    enforced.value = !value;
    useAlert(t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
  } finally {
    isUpdating.value = false;
  }
};
</script>

<template>
  <SettingsFieldSection
    :label="t('INBOX_MGMT.ADD.SMS.BANDWIDTH.CALLBACK_AUTH.TITLE')"
    :help-text="t('INBOX_MGMT.ADD.SMS.BANDWIDTH.CALLBACK_AUTH.DESCRIPTION')"
  >
    <div class="flex flex-col gap-3">
      <span class="text-body-main text-n-slate-11">
        {{ t('INBOX_MGMT.ADD.SMS.BANDWIDTH.CALLBACK_AUTH.USERNAME') }}
      </span>
      <woot-code :script="inbox.callback_auth_username" />
      <span class="text-body-main text-n-slate-11">
        {{ t('INBOX_MGMT.ADD.SMS.BANDWIDTH.CALLBACK_AUTH.PASSWORD') }}
      </span>
      <AccessToken
        :value="inbox.callback_auth_password"
        :show-reset-button="false"
        @on-copy="copyPassword"
      />
    </div>
  </SettingsFieldSection>
  <SettingsFieldSection
    :label="t('INBOX_MGMT.ADD.SMS.BANDWIDTH.CALLBACK_AUTH.ENFORCE')"
    :help-text="
      t('INBOX_MGMT.ADD.SMS.BANDWIDTH.CALLBACK_AUTH.ENFORCE_DESCRIPTION')
    "
  >
    <ToggleSwitch
      v-model="enforced"
      :disabled="isUpdating"
      @update:model-value="updateEnforced"
    />
  </SettingsFieldSection>
</template>
