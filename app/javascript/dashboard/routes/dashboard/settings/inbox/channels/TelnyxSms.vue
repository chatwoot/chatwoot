<script setup>
import { reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { required } from '@vuelidate/validators';

import NextButton from 'dashboard/components-next/button/Button.vue';

const shouldStartWithPlusSign = (value = '') => value.startsWith('+');

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const uiFlags = useMapGetter('inboxes/getUIFlags');

const state = reactive({
  apiKey: '',
  messagingProfileId: '',
  inboxName: '',
  phoneNumber: '',
});

const validationRules = {
  inboxName: { required },
  phoneNumber: { required, shouldStartWithPlusSign },
  apiKey: { required },
  messagingProfileId: { required },
};

const v$ = useVuelidate(validationRules, state);

async function createChannel() {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  try {
    const smsChannel = await store.dispatch('inboxes/createChannel', {
      name: state.inboxName.trim(),
      channel: {
        type: 'telnyx_sms',
        phone_number: state.phoneNumber,
        provider_config: {
          api_key: state.apiKey,
          messaging_profile_id: state.messagingProfileId,
        },
      },
    });

    router.replace({
      name: 'settings_inboxes_add_agents',
      params: {
        page: 'new',
        inbox_id: smsChannel.id,
      },
    });
  } catch {
    useAlert(t('INBOX_MGMT.ADD.SMS.API.ERROR_MESSAGE'));
  }
}
</script>

<template>
  <form class="flex flex-wrap flex-col mx-0" @submit.prevent="createChannel()">
    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.inboxName.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.TELNYX.INBOX_NAME.LABEL') }}
        <input
          v-model="state.inboxName"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.SMS.TELNYX.INBOX_NAME.PLACEHOLDER')"
          @blur="v$.inboxName.$touch"
        />
        <span v-if="v$.inboxName.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.TELNYX.INBOX_NAME.ERROR')
        }}</span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.phoneNumber.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.TELNYX.PHONE_NUMBER.LABEL') }}
        <input
          v-model="state.phoneNumber"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.SMS.TELNYX.PHONE_NUMBER.PLACEHOLDER')
          "
          @blur="v$.phoneNumber.$touch"
        />
        <span v-if="v$.phoneNumber.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.TELNYX.PHONE_NUMBER.ERROR')
        }}</span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.apiKey.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.TELNYX.API_KEY.LABEL') }}
        <input
          v-model="state.apiKey"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.SMS.TELNYX.API_KEY.PLACEHOLDER')"
          @blur="v$.apiKey.$touch"
        />
        <span v-if="v$.apiKey.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.TELNYX.API_KEY.ERROR')
        }}</span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.messagingProfileId.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.TELNYX.MESSAGING_PROFILE_ID.LABEL') }}
        <input
          v-model="state.messagingProfileId"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.SMS.TELNYX.MESSAGING_PROFILE_ID.PLACEHOLDER')
          "
          @blur="v$.messagingProfileId.$touch"
        />
        <span v-if="v$.messagingProfileId.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.TELNYX.MESSAGING_PROFILE_ID.ERROR')
        }}</span>
      </label>
    </div>

    <div class="w-full mt-4">
      <NextButton
        :is-loading="uiFlags.isCreating"
        type="submit"
        solid
        blue
        :label="$t('INBOX_MGMT.ADD.SMS.TELNYX.SUBMIT_BUTTON')"
      />
    </div>
  </form>
</template>
