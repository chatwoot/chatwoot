<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';

import NextButton from 'dashboard/components-next/button/Button.vue';

const shouldStartWithPlusSign = (value = '') => value.startsWith('+');

export default {
  components: {
    NextButton,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      authId: '',
      authToken: '',
      inboxName: '',
      phoneNumber: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required, shouldStartWithPlusSign },
    authId: { required },
    authToken: { required },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const plivoChannel = await this.$store.dispatch('inboxes/createChannel', {
          name: this.inboxName?.trim(),
          channel: {
            type: 'plivo',
            phone_number: this.phoneNumber,
            provider_config: {
              auth_id: this.authId,
              auth_token: this.authToken,
            },
          },
        });

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: plivoChannel.id,
          },
        });
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.ADD.SMS.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<template>
  <form class="flex flex-wrap flex-col mx-0" @submit.prevent="createChannel()">
    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.inboxName.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.PLIVO.INBOX_NAME.LABEL') }}
        <input
          v-model="inboxName"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.SMS.PLIVO.INBOX_NAME.PLACEHOLDER')"
          @blur="v$.inboxName.$touch"
        />
        <span v-if="v$.inboxName.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.PLIVO.INBOX_NAME.ERROR')
        }}</span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.phoneNumber.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.PLIVO.PHONE_NUMBER.LABEL') }}
        <input
          v-model="phoneNumber"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.SMS.PLIVO.PHONE_NUMBER.PLACEHOLDER')"
          @blur="v$.phoneNumber.$touch"
        />
        <span v-if="v$.phoneNumber.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.PLIVO.PHONE_NUMBER.ERROR')
        }}</span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.authId.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.PLIVO.AUTH_ID.LABEL') }}
        <input
          v-model="authId"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.SMS.PLIVO.AUTH_ID.PLACEHOLDER')"
          @blur="v$.authId.$touch"
        />
        <span v-if="v$.authId.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.PLIVO.AUTH_ID.ERROR')
        }}</span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.authToken.$error }">
        {{ $t('INBOX_MGMT.ADD.SMS.PLIVO.AUTH_TOKEN.LABEL') }}
        <input
          v-model="authToken"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.SMS.PLIVO.AUTH_TOKEN.PLACEHOLDER')"
          @blur="v$.authToken.$touch"
        />
        <span v-if="v$.authToken.$error" class="message">{{
          $t('INBOX_MGMT.ADD.SMS.PLIVO.AUTH_TOKEN.ERROR')
        }}</span>
      </label>
    </div>

    <div class="w-full mt-4">
      <NextButton
        :is-loading="uiFlags.isCreating"
        type="submit"
        solid
        blue
        :label="$t('INBOX_MGMT.ADD.SMS.PLIVO.SUBMIT_BUTTON')"
      />
    </div>
  </form>
</template>
