<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required, email } from '@vuelidate/validators';
import router from '../../../../../index';
import PageHeader from '../../../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    PageHeader,
    NextButton,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      channelName: '',
      email: '',
      alertMessage: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    channelName: { required },
    email: { required, email },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const emailChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.channelName,
            channel: {
              type: 'email',
              email: this.email,
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: emailChannel.id,
          },
        });
      } catch (error) {
        const errorMessage = error?.message;
        this.alertMessage =
          errorMessage ||
          this.$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.API.ERROR_MESSAGE');
        useAlert(this.alertMessage);
      }
    },
  },
};
</script>

<template>
  <div
    class="border border-n-weak bg-n-solid-1 rounded-t-lg border-b-0 h-full w-full p-6 col-span-6 overflow-auto"
  >
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.DESC')"
    />
    <form
      class="flex flex-wrap flex-col mx-0"
      @submit.prevent="createChannel()"
    >
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.channelName.$error }">
          {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_NAME.LABEL') }}
          <input
            v-model="channelName"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_NAME.PLACEHOLDER')
            "
            @blur="v$.channelName.$touch"
          />
          <span v-if="v$.channelName.$error" class="message">{{
            $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_NAME.ERROR')
          }}</span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0 mb-4">
        <label :class="{ error: v$.email.$error }">
          {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.EMAIL.LABEL') }}
          <input
            v-model="email"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.EMAIL.PLACEHOLDER')"
            @blur="v$.email.$touch"
          />
          <p class="help-text">
            {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.EMAIL.SUBTITLE') }}
          </p>
        </label>
      </div>

      <div class="w-full mt-4">
        <NextButton
          :is-loading="uiFlags.isCreating"
          type="submit"
          solid
          blue
          :label="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>
