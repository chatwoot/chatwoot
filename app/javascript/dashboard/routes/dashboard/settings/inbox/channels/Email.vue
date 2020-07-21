<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.DESC')"
    />
    <form class="row" @submit.prevent="createChannel()">
      <div class="medium-8 columns">
        <label :class="{ error: $v.channelName.$error }">
          {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_NAME.LABEL') }}
          <input
            v-model.trim="channelName"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_NAME.PLACEHOLDER')
            "
            @blur="$v.channelName.$touch"
          />
          <span v-if="$v.channelName.$error" class="message">{{
            $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_NAME.ERROR')
          }}</span>
        </label>
      </div>

      <div class="medium-8 columns">
        <label :class="{ error: $v.email.$error }">
          {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.EMAIL.LABEL') }}
          <input
            v-model.trim="email"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.EMAIL.PLACEHOLDER')"
            @blur="$v.email.$touch"
          />
        </label>
        <p class="help-text">
          {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.EMAIL.SUBTITLE') }}
        </p>
      </div>

      <div class="medium-12 columns">
        <woot-submit-button
          :loading="uiFlags.isCreating"
          :button-text="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.SUBMIT_BUTTON')"
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

const validEmail = (value = '') => value.includes('@');

export default {
  components: {
    PageHeader,
  },
  mixins: [alertMixin],
  data() {
    return {
      channelName: '',
      email: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    channelName: { required },
    email: { required, validEmail },
  },
  methods: {
    async createChannel() {
      this.$v.$touch();
      if (this.$v.$invalid) {
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
        this.showAlert(
          this.$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>
