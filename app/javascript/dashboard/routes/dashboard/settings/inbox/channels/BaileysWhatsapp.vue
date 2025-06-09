<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required, requiredIf } from '@vuelidate/validators';
import router from '../../../../index';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';
import { isValidURL } from '../../../../../helper/URLHelper';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

export default {
  components: {
    NextButton,
    // eslint-disable-next-line vue/no-reserved-component-names
    Switch,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      inboxName: '',
      phoneNumber: '',
      apiKey: '',
      providerUrl: '',
      showAdvancedOptions: false,
      markAsRead: true,
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  validations() {
    return {
      inboxName: { required },
      phoneNumber: { required, isPhoneE164OrEmpty },
      providerUrl: {
        isValidURL: value => !value || isValidURL(value),
        requiredIf: requiredIf(this.apiKey),
      },
      apiKey: { requiredIf: requiredIf(this.providerUrl) },
    };
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const providerConfig = {
          mark_as_read: this.markAsRead,
        };

        if (this.apiKey || this.providerUrl) {
          providerConfig.api_key = this.apiKey;
          providerConfig.url = this.providerUrl;
        }

        const whatsappChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.inboxName,
            channel: {
              type: 'whatsapp',
              phone_number: this.phoneNumber,
              provider: 'baileys',
              provider_config: providerConfig,
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: whatsappChannel.id,
          },
        });
      } catch (error) {
        useAlert(
          error.message || this.$t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE')
        );
      }
    },
    setShowAdvancedOptions() {
      this.showAdvancedOptions = true;
    },
  },
};
</script>

<template>
  <form class="flex flex-wrap mx-0" @submit.prevent="createChannel()">
    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
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

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
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

    <div
      v-if="!showAdvancedOptions"
      class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%] mb-4"
    >
      <NextButton icon="i-lucide-plus" sm link @click="setShowAdvancedOptions">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.ADVANCED_OPTIONS') }}
      </NextButton>
    </div>
    <template v-else>
      <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
        <span class="text-sm text-gray-600">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.ADVANCED_OPTIONS') }}
        </span>
        <label :class="{ error: v$.providerUrl.$error }">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDER_URL.LABEL') }}
          <input
            v-model="providerUrl"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDER_URL.PLACEHOLDER')
            "
          />
          <span v-if="v$.providerUrl.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDER_URL.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
        <label :class="{ error: v$.apiKey.$error }">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.LABEL') }}
          <input
            v-model="apiKey"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.PLACEHOLDER')"
          />
          <span v-if="v$.apiKey.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
        <label>
          <div class="flex mb-2 items-center">
            <span class="mr-2 text-sm">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP.MARK_AS_READ.LABEL') }}
            </span>
            <Switch id="markAsRead" v-model="markAsRead" />
          </div>
        </label>
      </div>
    </template>

    <div class="w-full">
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
