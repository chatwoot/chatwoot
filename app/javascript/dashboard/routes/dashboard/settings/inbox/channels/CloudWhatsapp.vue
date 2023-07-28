<template>
  <form class="mx-0 flex flex-wrap" @submit.prevent="createChannel()">
    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: $v.inboxName.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
        <input
          v-model.trim="inboxName"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.PLACEHOLDER')"
          @blur="$v.inboxName.$touch"
        />
        <span v-if="$v.inboxName.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR') }}
        </span>
      </label>
    </div>

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: $v.phoneNumber.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.LABEL') }}
        <input
          v-model.trim="phoneNumber"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.PLACEHOLDER')"
          @blur="$v.phoneNumber.$touch"
        />
        <span v-if="$v.phoneNumber.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.ERROR') }}
        </span>
      </label>
    </div>

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: $v.phoneNumberId.$error }">
        <span>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER_ID.LABEL') }}
        </span>
        <input
          v-model.trim="phoneNumberId"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER_ID.PLACEHOLDER')
          "
          @blur="$v.phoneNumberId.$touch"
        />
        <span v-if="$v.phoneNumberId.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER_ID.ERROR') }}
        </span>
      </label>
    </div>

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: $v.businessAccountId.$error }">
        <span>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.BUSINESS_ACCOUNT_ID.LABEL') }}
        </span>
        <input
          v-model.trim="businessAccountId"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP.BUSINESS_ACCOUNT_ID.PLACEHOLDER')
          "
          @blur="$v.businessAccountId.$touch"
        />
        <span v-if="$v.businessAccountId.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.BUSINESS_ACCOUNT_ID.ERROR') }}
        </span>
      </label>
    </div>

    <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
      <label :class="{ error: $v.appId.$error }">
        <span>
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.APP_ID.LABEL') }}
        </span>
        <input
          v-model.trim="appId"
          type="text"
          :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.APP_ID.PLACEHOLDER')"
          @blur="$v.appId.$touch"
        />
        <span v-if="$v.appId.$error" class="message">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.APP_ID.ERROR') }}
        </span>
      </label>
    </div>

    <div class="w-full">
      <woot-submit-button
        :loading="uiFlags.isCreating"
        :button-text="$t('INBOX_MGMT.ADD.WHATSAPP.SUBMIT_BUTTON')"
      />
    </div>
  </form>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import { isPhoneE164OrEmpty, isNumber } from 'shared/helpers/Validators';

export default {
  mixins: [alertMixin],
  data() {
    return {
      inboxName: '',
      phoneNumber: '',
      apiKey: '',
      appId: '',
      phoneNumberId: '',
      businessAccountId: '',
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required, isPhoneE164OrEmpty },
    appId: { required },
    phoneNumberId: { required, isNumber },
    businessAccountId: { required, isNumber },
  },
  methods: {
    async createChannel() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      const payload = {
        name: this.inboxName,
        channel: {
          type: 'whatsapp',
          phone_number: this.phoneNumber,
          provider: 'whatsapp_cloud',
          provider_config: {
            api_key: this.apiKey,
            app_id: this.appId,
            phone_number_id: this.phoneNumberId,
            business_account_id: this.businessAccountId,
          },
        },
      };

      this.$router.push({
        name: 'settings_inboxes_page_whatsapp_fb_login',
        params: {
          page: 'new',
          payload: payload,
        },
        query: {
          provider_type: 'whatsapp_cloud',
        },
      });
    },
  },
};
</script>
