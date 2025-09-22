<script setup>
import { ref } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import { isPhoneE164OrEmpty, isNumber } from 'shared/helpers/Validators';

import NextButton from 'dashboard/components-next/button/Button.vue';

const store = useStore();

// State (replaces data())
const inboxName = ref('');
const phoneNumber = ref('');
const apiKey = ref('');
const phoneNumberId = ref('');
const businessAccountId = ref('');

// Store access (replaces mapGetters)
const uiFlags = useMapGetter('inboxes/getUIFlags');

// Validation setup
const rules = {
  inboxName: { required },
  phoneNumber: { required, isPhoneE164OrEmpty },
  apiKey: { required },
  phoneNumberId: { required, isNumber },
  businessAccountId: { required, isNumber },
};

const v$ = useVuelidate(rules, {
  inboxName,
  phoneNumber,
  apiKey,
  phoneNumberId,
  businessAccountId,
});

// Methods (converted to functions)
const createChannel = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) {
    return;
  }

  try {
    const whatsappChannel = await store.dispatch('inboxes/createChannel', {
      name: inboxName.value,
      channel: {
        type: 'whatsapp',
        phone_number: phoneNumber.value,
        provider: 'whatsapp_cloud',
        provider_config: {
          api_key: apiKey.value,
          phone_number_id: phoneNumberId.value,
          business_account_id: businessAccountId.value,
        },
      },
    });

    router.replace({
      name: 'settings_inboxes_invite_team',
      params: {
        page: 'new',
        inbox_id: whatsappChannel.id,
      },
    });
  } catch (error) {
    useAlert(error.message || 'An error occurred while creating the channel');
  }
};
</script>

<template>
  <form class="flex flex-wrap flex-col mx-0" @submit.prevent="createChannel()">
    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.inboxName.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
        <input
          v-model="inboxName"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.PLACEHOLDER')"
          @blur="v$.inboxName.$touch"
        />
        <span v-if="v$.inboxName.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
        </span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.phoneNumber.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.LABEL') }}
        <input
          v-model="phoneNumber"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.PLACEHOLDER')"
          @blur="v$.phoneNumber.$touch"
        />
        <span v-if="v$.phoneNumber.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.ERROR') }}
        </span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.phoneNumberId.$error }">
        <span>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER_ID.LABEL') }}
        </span>
        <input
          v-model="phoneNumberId"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER_ID.PLACEHOLDER')
          "
          @blur="v$.phoneNumberId.$touch"
        />
        <span v-if="v$.phoneNumberId.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER_ID.ERROR') }}
        </span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.businessAccountId.$error }">
        <span>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.BUSINESS_ACCOUNT_ID.LABEL') }}
        </span>
        <input
          v-model="businessAccountId"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP.BUSINESS_ACCOUNT_ID.PLACEHOLDER')
          "
          @blur="v$.businessAccountId.$touch"
        />
        <span v-if="v$.businessAccountId.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.BUSINESS_ACCOUNT_ID.ERROR') }}
        </span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.apiKey.$error }">
        <span>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.LABEL') }}
        </span>
        <input
          v-model="apiKey"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.PLACEHOLDER')"
          @blur="v$.apiKey.$touch"
        />
        <span v-if="v$.apiKey.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.ERROR') }}
        </span>
      </label>
    </div>

    <div class="w-full mt-4">
      <NextButton
        :is-loading="uiFlags.isCreating"
        type="submit"
        solid
        blue
        :label="$t('INBOX_MGMT.ADD.WHATSAPP.SUBMIT_BUTTON')"
      />
    </div>
  </form>
</template>
