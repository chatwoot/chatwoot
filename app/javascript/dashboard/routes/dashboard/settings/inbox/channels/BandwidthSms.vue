<script setup>
import { computed, reactive } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import NextButton from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const router = useRouter();
const { t } = useI18n();
const uiFlags = useMapGetter('inboxes/getUIFlags');
const form = reactive({
  accountId: '',
  clientId: '',
  clientSecret: '',
  applicationId: '',
  inboxName: '',
  phoneNumber: '',
});
const rules = computed(() => ({
  inboxName: { required },
  phoneNumber: { required, e164: value => /^\+[1-9]\d{1,14}$/.test(value) },
  clientId: { required },
  clientSecret: { required },
  applicationId: { required },
  accountId: { required },
}));
const v$ = useVuelidate(rules, form);

const createChannel = async () => {
  if (!(await v$.value.$validate())) return;

  try {
    const smsChannel = await store.dispatch('inboxes/createChannel', {
      name: form.inboxName.trim(),
      channel: {
        type: 'sms',
        phone_number: form.phoneNumber,
        provider_config: {
          client_id: form.clientId,
          client_secret: form.clientSecret,
          application_id: form.applicationId,
          account_id: form.accountId,
        },
      },
    });
    router.replace({
      name: 'settings_inboxes_add_agents',
      params: { page: 'new', inbox_id: smsChannel.id },
    });
  } catch (error) {
    useAlert(error.message || t('INBOX_MGMT.ADD.SMS.API.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <form class="flex flex-wrap flex-col mx-0" @submit.prevent="createChannel()">
    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.inboxName.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.INBOX_NAME.LABEL') }}
        <input
          v-model="form.inboxName"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.INBOX_NAME.PLACEHOLDER')
          "
          @blur="v$.inboxName.$touch"
        />
        <span v-if="v$.inboxName.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.INBOX_NAME.ERROR')
        }}</span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.phoneNumber.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.PHONE_NUMBER.LABEL') }}
        <input
          v-model="form.phoneNumber"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.PHONE_NUMBER.PLACEHOLDER')
          "
          @blur="v$.phoneNumber.$touch"
        />
        <span v-if="v$.phoneNumber.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.PHONE_NUMBER.ERROR')
        }}</span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.accountId.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.ACCOUNT_ID.LABEL') }}
        <input
          v-model="form.accountId"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.ACCOUNT_ID.PLACEHOLDER')
          "
          @blur="v$.accountId.$touch"
        />
        <span v-if="v$.accountId.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.ACCOUNT_ID.ERROR')
        }}</span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.applicationId.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.APPLICATION_ID.LABEL') }}
        <input
          v-model="form.applicationId"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.APPLICATION_ID.PLACEHOLDER')
          "
          @blur="v$.applicationId.$touch"
        />
        <span v-if="v$.applicationId.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.APPLICATION_ID.ERROR')
        }}</span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.clientId.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.CLIENT_ID.LABEL') }}
        <input
          v-model="form.clientId"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.CLIENT_ID.PLACEHOLDER')
          "
          @blur="v$.clientId.$touch"
        />
        <span v-if="v$.clientId.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.CLIENT_ID.ERROR')
        }}</span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.clientSecret.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.CLIENT_SECRET.LABEL') }}
        <input
          v-model="form.clientSecret"
          type="password"
          autocomplete="new-password"
          :placeholder="
            $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.CLIENT_SECRET.PLACEHOLDER')
          "
          @blur="v$.clientSecret.$touch"
        />
        <span v-if="v$.clientSecret.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.BANDWIDTH.CLIENT_SECRET.ERROR')
        }}</span>
      </label>
    </div>

    <div class="w-full mt-4">
      <NextButton
        :is-loading="uiFlags.isCreating"
        type="submit"
        solid
        blue
        :label="$t('INBOX_MGMT.ADD.SMS.BANDWIDTH.SUBMIT_BUTTON')"
      />
    </div>
  </form>
</template>
