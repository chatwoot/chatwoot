<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required, helpers } from '@vuelidate/validators';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';

const isValidIndoPhone = helpers.withMessage(
  'Phone number must start with 62 and contain only digits',
  value => /^62\d{6,15}$/.test(value || '')
);

export default {
  components: {
    PageHeader,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      inboxName: '',
      phoneNumber: '',
      isLoading: false,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required, isValidIndoPhone },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) return;

      this.isLoading = true; 
      try {
        const channel = await this.$store.dispatch('inboxes/createWhatsAppUnofficialChannel', {
          phoneNumber: this.phoneNumber,
          inboxName: this.inboxName,
        });
        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: channel.inbox_id,
          },
          query: {
            webhook_url: channel.webhook_url,
          },
        });
      } catch (error) {
        console.error(error);
        useAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP_UNOFFICIAL_CHANNEL.ERROR_MESSAGE'));
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <div class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.WHATSAPP_UNOFFICIAL_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WHATSAPP_UNOFFICIAL_CHANNEL.DESC')"
    />

    <form class="flex flex-wrap mx-0" @submit.prevent="createChannel()">
      <!-- Inbox Name -->
      <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
        <label :class="{ error: v$.inboxName.$error }">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_UNOFFICIAL_CHANNEL.CHANNEL_NAME.LABEL') }}
          <input
            v-model="inboxName"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP_UNOFFICIAL_CHANNEL.CHANNEL_NAME.PLACEHOLDER')"
            @blur="v$.inboxName.$touch"
          />
          <span v-if="v$.inboxName.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_UNOFFICIAL_CHANNEL.CHANNEL_NAME.ERROR') }}
          </span>
        </label>
      </div>

      <!-- Phone Number -->
      <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
        <label :class="{ error: v$.phoneNumber.$error }">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_UNOFFICIAL_CHANNEL.PHONE_NUMBER.LABEL') }}
          <input
            v-model="phoneNumber"
            type="text"
            placeholder="628xxxxxxxxxx"
            @blur="v$.phoneNumber.$touch"
          />
          <span v-if="v$.phoneNumber.$error" class="message">
            Phone number must start with 62 and be valid
          </span>
        </label>
        <p class="help-text">Enter the phone number in Indonesian format, starting with 62.</p>
      </div>

      <!-- Submit Button -->
      <div class="w-full">
        <woot-submit-button
          :loading="isLoading"
          :button-text="$t('INBOX_MGMT.ADD.WHATSAPP_UNOFFICIAL_CHANNEL.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>
