<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
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
        const baleChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            channel: {
              type: 'bale',
              bot_token: this.botToken,
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: baleChannel.id,
          },
        });
      } catch (error) {
        useAlert(
          error.message ||
            this.$t('INBOX_MGMT.ADD.BALE_CHANNEL.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.BALE_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.BALE_CHANNEL.DESC')"
    />
    <form
      class="flex flex-wrap flex-col mx-0"
      @submit.prevent="createChannel()"
    >
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.botToken.$error }">
          {{ $t('INBOX_MGMT.ADD.BALE_CHANNEL.BOT_TOKEN.LABEL') }}
          <input
            v-model="botToken"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.BALE_CHANNEL.BOT_TOKEN.PLACEHOLDER')
            "
            @blur="v$.botToken.$touch"
          />
        </label>
        <p class="help-text">
          {{ $t('INBOX_MGMT.ADD.BALE_CHANNEL.BOT_TOKEN.SUBTITLE') }}
        </p>
      </div>

      <div class="w-full mt-4">
        <NextButton
          :is-loading="uiFlags.isCreating"
          type="submit"
          solid
          blue
          :label="$t('INBOX_MGMT.ADD.BALE_CHANNEL.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>
