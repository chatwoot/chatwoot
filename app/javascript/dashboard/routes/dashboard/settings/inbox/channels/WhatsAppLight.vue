<script>
/* global axios */
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      inboxName: '',
      phoneNumber: '',
      isCreating: false,
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required, isPhoneE164OrEmpty },
  },
  methods: {
    async createChannel() {
      // Prevent multiple submissions
      if (this.isCreating) {
        return;
      }

      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      this.isCreating = true;

      try {
        const response = await axios.post(
          `/api/v1/accounts/${this.$route.params.accountId}/channels/whapi_channels`,
          {
            whapi_channel: {
              name: this.inboxName?.trim(),
              phone_number: this.phoneNumber,
            },
          }
        );

        const inboxId = response.data.inbox.id;

        // Redirect to agent assignment immediately
        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: inboxId,
          },
        });
      } catch (error) {
        const errorMessage =
          error.response?.data?.error ||
          this.$t('INBOX_MGMT.ADD.WHATSAPP_LIGHT.API.ERROR_MESSAGE');
        useAlert(errorMessage);
        this.isCreating = false;
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-wrap flex-col mx-0">
    <form
      class="flex flex-wrap flex-col mx-0"
      @submit.prevent="createChannel()"
    >
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.inboxName.$error }">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_LIGHT.INBOX_NAME.LABEL') }}
          <input
            v-model="inboxName"
            type="text"
            :disabled="isCreating"
            :placeholder="
              $t('INBOX_MGMT.ADD.WHATSAPP_LIGHT.INBOX_NAME.PLACEHOLDER')
            "
            @blur="v$.inboxName.$touch"
          />
          <span v-if="v$.inboxName.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_LIGHT.INBOX_NAME.ERROR') }}
          </span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.phoneNumber.$error }">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_LIGHT.PHONE_NUMBER.LABEL') }}
          <input
            v-model="phoneNumber"
            type="text"
            :disabled="isCreating"
            :placeholder="
              $t('INBOX_MGMT.ADD.WHATSAPP_LIGHT.PHONE_NUMBER.PLACEHOLDER')
            "
            @blur="v$.phoneNumber.$touch"
          />
          <span v-if="v$.phoneNumber.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_LIGHT.PHONE_NUMBER.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-full mt-4">
        <NextButton
          :is-loading="isCreating"
          :disabled="isCreating"
          type="submit"
          solid
          blue
          :label="$t('INBOX_MGMT.ADD.WHATSAPP_LIGHT.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>
