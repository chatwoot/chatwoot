<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../dashboard/routes/index';

const shouldBeWebhookUrl = (value = '') =>
  value ? value.startsWith('http') : true;

export default {
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      channelName: '',
      webhookUrl: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    channelName: { required },
    webhookUrl: { shouldBeWebhookUrl },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const apiChannel = await this.$store.dispatch('inboxes/createChannel', {
          name: this.channelName,
          channel: {
            type: 'api',
            webhook_url: this.webhookUrl,
          },
        });

        router.replace({
          name: 'onboarding_setup_inbox_add_agents',
          params: {
            inbox_id: apiChannel.id,
          },
        });
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.ADD.API_CHANNEL.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full flex-shrink-0 flex-grow-0"
  >
    <form class="flex flex-wrap mx-0" @submit.prevent="createChannel()">
      <div class="w-full flex-shrink-0 flex-grow-0 max-w-full">
        <label :class="{ error: v$.channelName.$error }">
          {{ $t('INBOX_MGMT.ADD.API_CHANNEL.CHANNEL_NAME.LABEL') }}
          <input
            v-model="channelName"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.API_CHANNEL.CHANNEL_NAME.PLACEHOLDER')
            "
            @blur="v$.channelName.$touch"
          />
          <span v-if="v$.channelName.$error" class="message">{{
            $t('INBOX_MGMT.ADD.API_CHANNEL.CHANNEL_NAME.ERROR')
          }}</span>
        </label>
      </div>

      <div class="w-full flex-shrink-0 flex-grow-0 max-w-full">
        <label :class="{ error: v$.webhookUrl.$error }">
          {{ $t('INBOX_MGMT.ADD.API_CHANNEL.WEBHOOK_URL.LABEL') }}
          <input
            v-model="webhookUrl"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.API_CHANNEL.WEBHOOK_URL.PLACEHOLDER')
            "
            @blur="v$.webhookUrl.$touch"
          />
        </label>
        <p class="help-text">
          {{ $t('INBOX_MGMT.ADD.API_CHANNEL.WEBHOOK_URL.SUBTITLE') }}
        </p>
      </div>

      <div class="w-full mt-4">
        <woot-submit-button
          :loading="uiFlags.isCreating"
          :button-text="$t('INBOX_MGMT.ADD.API_CHANNEL.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>
