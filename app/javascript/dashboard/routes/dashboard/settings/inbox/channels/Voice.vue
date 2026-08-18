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
  inboxName: '',
  phoneNumber: '',
});

const uiFlags = useMapGetter('inboxes/getUIFlags');

const validationRules = {
  inboxName: { required },
  phoneNumber: { required, isPhoneE164 },
};

const v$ = useVuelidate(validationRules, state);
const isSubmitDisabled = computed(() => v$.value.$invalid);

const formErrors = computed(() => ({
  inboxName: v$.value.inboxName?.$error
    ? t('INBOX_MGMT.ADD.VOICE.INBOX_NAME.ERROR')
    : '',
  phoneNumber: v$.value.phoneNumber?.$error
    ? t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBER.ERROR')
    : '',
}));

async function createChannel() {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  try {
    const channel = await store.dispatch('inboxes/createVoiceChannel', {
      name: state.inboxName.trim(),
      voice: { phone_number: state.phoneNumber },
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
        v-model="state.inboxName"
        :label="t('INBOX_MGMT.ADD.VOICE.INBOX_NAME.LABEL')"
        :placeholder="t('INBOX_MGMT.ADD.VOICE.INBOX_NAME.PLACEHOLDER')"
        :message="formErrors.inboxName"
        :message-type="formErrors.inboxName ? 'error' : 'info'"
        @blur="v$.inboxName?.$touch"
      />

      <Input
        v-model="state.phoneNumber"
        :label="t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBER.LABEL')"
        :placeholder="t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBER.PLACEHOLDER')"
        :message="
          formErrors.phoneNumber || t('INBOX_MGMT.ADD.VOICE.PHONE_NUMBER.HELP')
        "
        :message-type="formErrors.phoneNumber ? 'error' : 'info'"
        @blur="v$.phoneNumber?.$touch"
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
