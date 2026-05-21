<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
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
      channelName: '',
      appId: '',
      issuerId: '',
      keyId: '',
      privateKey: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    channelName: { required },
    appId: { required },
    issuerId: { required },
    keyId: { required },
    privateKey: { required },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) return;

      try {
        const appStoreChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.channelName?.trim(),
            channel: {
              type: 'app_store',
              app_id: this.appId.trim(),
              issuer_id: this.issuerId.trim(),
              key_id: this.keyId.trim(),
              private_key: this.privateKey.trim(),
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: appStoreChannel.id,
          },
        });
      } catch (error) {
        useAlert(
          error.message || this.$t('INBOX_MGMT.ADD.APP_STORE.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.APP_STORE.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.APP_STORE.DESC')"
    />
    <form
      class="flex flex-wrap flex-col mx-0"
      @submit.prevent="createChannel()"
    >
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.channelName.$error }">
          {{ $t('INBOX_MGMT.ADD.APP_STORE.CHANNEL_NAME.LABEL') }}
          <input
            v-model="channelName"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.APP_STORE.CHANNEL_NAME.PLACEHOLDER')
            "
            @blur="v$.channelName.$touch"
          />
          <span v-if="v$.channelName.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.APP_STORE.CHANNEL_NAME.ERROR') }}
          </span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.appId.$error }">
          {{ $t('INBOX_MGMT.ADD.APP_STORE.APP_ID.LABEL') }}
          <input
            v-model="appId"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.APP_STORE.APP_ID.PLACEHOLDER')"
            @blur="v$.appId.$touch"
          />
          <span v-if="v$.appId.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.APP_STORE.APP_ID.ERROR') }}
          </span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.issuerId.$error }">
          {{ $t('INBOX_MGMT.ADD.APP_STORE.ISSUER_ID.LABEL') }}
          <input
            v-model="issuerId"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.APP_STORE.ISSUER_ID.PLACEHOLDER')"
            @blur="v$.issuerId.$touch"
          />
          <span v-if="v$.issuerId.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.APP_STORE.ISSUER_ID.ERROR') }}
          </span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.keyId.$error }">
          {{ $t('INBOX_MGMT.ADD.APP_STORE.KEY_ID.LABEL') }}
          <input
            v-model="keyId"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.APP_STORE.KEY_ID.PLACEHOLDER')"
            @blur="v$.keyId.$touch"
          />
          <span v-if="v$.keyId.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.APP_STORE.KEY_ID.ERROR') }}
          </span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.privateKey.$error }">
          {{ $t('INBOX_MGMT.ADD.APP_STORE.PRIVATE_KEY.LABEL') }}
          <textarea
            v-model="privateKey"
            rows="8"
            :placeholder="
              $t('INBOX_MGMT.ADD.APP_STORE.PRIVATE_KEY.PLACEHOLDER')
            "
            @blur="v$.privateKey.$touch"
          />
          <span v-if="v$.privateKey.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.APP_STORE.PRIVATE_KEY.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-full mt-4">
        <NextButton
          :is-loading="uiFlags.isCreating"
          type="submit"
          solid
          blue
          :label="$t('INBOX_MGMT.ADD.APP_STORE.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>
