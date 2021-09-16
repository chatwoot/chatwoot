<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.WHATSAPP.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WHATSAPP.DESC')"
    />
    <form class="row" @submit.prevent="createChannel()">
      <div class="medium-8 columns">
        <label :class="{ error: $v.inboxName.$error }">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.LABEL') }}
          <input
            v-model.trim="inboxName"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.PLACEHOLDER')"
            @blur="$v.inboxName.$touch"
          />
          <span v-if="$v.inboxName.$error" class="message">{{
            $t('INBOX_MGMT.ADD.WHATSAPP.INBOX_NAME.ERROR')
          }}</span>
        </label>
      </div>

      <div class="medium-8 columns">
        <label :class="{ error: $v.phoneNumber.$error }">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.LABEL') }}
          <input
            v-model.trim="phoneNumber"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.PLACEHOLDER')
            "
            @blur="$v.phoneNumber.$touch"
          />
          <span v-if="$v.phoneNumber.$error" class="message">{{
            $t('INBOX_MGMT.ADD.WHATSAPP.PHONE_NUMBER.ERROR')
          }}</span>
        </label>
      </div>

      <div class="medium-8 columns">
        <label :class="{ error: $v.apiKey.$error }">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.LABEL') }}
          <input
            v-model.trim="apiKey"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.WHATSAPP.API_KEY.PLACEHOLDER')"
            @blur="$v.apiKey.$touch"
          />
        </label>
      </div>

      <div class="medium-12 columns">
        <woot-submit-button
          :loading="uiFlags.isCreating"
          :button-text="$t('INBOX_MGMT.ADD.WHATSAPP.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader';

const shouldStartWithPlusSign = (value = '') => value.startsWith('+');

export default {
  components: {
    PageHeader,
  },
  mixins: [alertMixin],
  data() {
    return {
      inboxName: '',
      phoneNumber: '',
      apiKey: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    inboxName: { required: true },
    phoneNumber: { required, shouldStartWithPlusSign },
    apiKey: { required },
  },
  methods: {
    async createChannel() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      try {
        const whatsappChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.inboxName,
            channel: {
              type: 'whatsapp',
              phone_number: this.phoneNumber,
              provider_config: {
                api_key: this.apiKey,
              },
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
        this.showAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
