<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';

import router from '../../../../dashboard/routes/index';

import PageHeader from '../../../../dashboard/routes/dashboard/settings/SettingsSubPageHeader.vue';

export default {
  components: {
    PageHeader,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      botToken: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    botToken: { required },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const telegramChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            channel: {
              type: 'telegram',
              bot_token: this.botToken,
            },
          }
        );

        router.replace({
          name: 'onboarding_setup_inbox_add_agents',
          params: {
            inbox_id: telegramChannel.id,
          },
        });
      } catch (error) {
        useAlert(
          error.message ||
            this.$t('INBOX_MGMT.ADD.TELEGRAM_CHANNEL.API.ERROR_MESSAGE')
        );
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
        <label :class="{ error: v$.botToken.$error }">
          {{ $t('INBOX_MGMT.ADD.TELEGRAM_CHANNEL.BOT_TOKEN.LABEL') }}
          <input
            v-model="botToken"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.TELEGRAM_CHANNEL.BOT_TOKEN.PLACEHOLDER')
            "
            @blur="v$.botToken.$touch"
          />
        </label>
        <p class="help-text">
          {{ $t('INBOX_MGMT.ADD.TELEGRAM_CHANNEL.BOT_TOKEN.SUBTITLE') }}
        </p>
      </div>

      <div class="w-full mt-4">
        <woot-submit-button
          :loading="uiFlags.isCreating"
          :button-text="$t('INBOX_MGMT.ADD.TELEGRAM_CHANNEL.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>
