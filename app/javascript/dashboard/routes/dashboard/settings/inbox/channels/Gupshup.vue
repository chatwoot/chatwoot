<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.GUPSHUP.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.GUPSHUP.DESC')"
    />
    <form class="row" @submit.prevent="createChannel()">
      <div class="medium-8 columns">
        <label :class="{ error: $v.channelName.$error }">
          {{ $t('INBOX_MGMT.ADD.GUPSHUP.CHANNEL_NAME.LABEL') }}
          <input
            v-model.trim="channelName"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.GUPSHUP.CHANNEL_NAME.PLACEHOLDER')"
            @blur="$v.channelName.$touch"
          />
          <span v-if="$v.channelName.$error" class="message">{{
            $t('INBOX_MGMT.ADD.GUPSHUP.CHANNEL_NAME.ERROR')
          }}</span>
        </label>
      </div>

      <div class="medium-8 columns">
        <label :class="{ error: $v.phoneNumber.$error }">
          {{ $t('INBOX_MGMT.ADD.GUPSHUP.PHONE_NUMBER.LABEL') }}
          <input
            v-model.trim="phoneNumber"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.GUPSHUP.PHONE_NUMBER.PLACEHOLDER')"
            @blur="$v.phoneNumber.$touch"
          />
          <span v-if="$v.phoneNumber.$error" class="message">{{
            $t('INBOX_MGMT.ADD.GUPSHUP.PHONE_NUMBER.ERROR')
          }}</span>
        </label>
      </div>

      <div class="medium-8 columns">
        <label :class="{ error: $v.app.$error }">
          {{ $t('INBOX_MGMT.ADD.GUPSHUP.APP.LABEL') }}
          <input
            v-model.trim="app"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.GUPSHUP.APP.PLACEHOLDER')"
            @blur="$v.app.$touch"
          />
          <span v-if="$v.app.$error" class="message">{{
            $t('INBOX_MGMT.ADD.GUPSHUP.APP.ERROR')
          }}</span>
        </label>
      </div>
      <div class="medium-8 columns">
        <label :class="{ error: $v.apikey.$error }">
          {{ $t('INBOX_MGMT.ADD.GUPSHUP.APIKEY.LABEL') }}
          <input
            v-model.trim="apikey"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.GUPSHUP.APIKEY.PLACEHOLDER')"
            @blur="$v.apikey.$touch"
          />
          <span v-if="$v.apikey.$error" class="message">{{
            $t('INBOX_MGMT.ADD.GUPSHUP.APIKEY.ERROR')
          }}</span>
        </label>
      </div>

      <div class="medium-12 columns">
        <woot-submit-button
          :loading="uiFlags.isCreating"
          :button-text="$t('INBOX_MGMT.ADD.GUPSHUP.SUBMIT_BUTTON')"
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

export default {
  components: {
    PageHeader,
  },
  mixins: [alertMixin],
  data() {
    return {
      app: '',
      apikey: '',
      channelName: '',
      phoneNumber: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    channelName: { required },
    phoneNumber: { required },
    apikey: { required },
    app: { required },
  },
  methods: {
    async createChannel() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      try {
        // eslint-disable-next-line no-shadow
        const gupshupChannel = await this.$store.dispatch(
          'inboxes/createGupshupChannel',
          {
            gupshup_channel: {
              name: this.channelName,
              app: this.app,
              apikey: this.apikey,
              phone_number: `${this.phoneNumber.replace(/\D/g, '')}`,
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: gupshupChannel.id,
          },
        });
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.ADD.GUPSHUP.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
