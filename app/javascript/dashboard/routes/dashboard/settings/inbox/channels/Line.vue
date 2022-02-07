<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.LINE_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.LINE_CHANNEL.DESC')"
    />
    <form class="row" @submit.prevent="createChannel()">
      <div class="medium-8 columns">
        <label :class="{ error: $v.channelName.$error }">
          {{ $t('INBOX_MGMT.ADD.LINE_CHANNEL.CHANNEL_NAME.LABEL') }}
          <input
            v-model.trim="channelName"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.LINE_CHANNEL.CHANNEL_NAME.PLACEHOLDER')
            "
            @blur="$v.channelName.$touch"
          />
          <span v-if="$v.channelName.$error" class="message">{{
            $t('INBOX_MGMT.ADD.LINE_CHANNEL.CHANNEL_NAME.ERROR')
          }}</span>
        </label>
      </div>

      <div class="medium-8 columns">
        <label :class="{ error: $v.lineChannelId.$error }">
          {{ $t('INBOX_MGMT.ADD.LINE_CHANNEL.LINE_CHANNEL_ID.LABEL') }}
          <input
            v-model.trim="lineChannelId"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.LINE_CHANNEL.LINE_CHANNEL_ID.PLACEHOLDER')
            "
            @blur="$v.lineChannelId.$touch"
          />
        </label>
      </div>

      <div class="medium-8 columns">
        <label :class="{ error: $v.lineChannelSecret.$error }">
          {{ $t('INBOX_MGMT.ADD.LINE_CHANNEL.LINE_CHANNEL_SECRET.LABEL') }}
          <input
            v-model.trim="lineChannelSecret"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.LINE_CHANNEL.LINE_CHANNEL_SECRET.PLACEHOLDER')
            "
            @blur="$v.lineChannelSecret.$touch"
          />
        </label>
      </div>

      <div class="medium-8 columns">
        <label :class="{ error: $v.lineChannelToken.$error }">
          {{ $t('INBOX_MGMT.ADD.LINE_CHANNEL.LINE_CHANNEL_TOKEN.LABEL') }}
          <input
            v-model.trim="lineChannelToken"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.LINE_CHANNEL.LINE_CHANNEL_TOKEN.PLACEHOLDER')
            "
            @blur="$v.lineChannelToken.$touch"
          />
        </label>
      </div>

      <div class="medium-12 columns">
        <woot-submit-button
          :loading="uiFlags.isCreating"
          :button-text="$t('INBOX_MGMT.ADD.LINE_CHANNEL.SUBMIT_BUTTON')"
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
      channelName: '',
      lineChannelId: '',
      lineChannelSecret: '',
      lineChannelToken: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    channelName: { required },
    lineChannelId: { required },
    lineChannelSecret: { required },
    lineChannelToken: { required },
  },
  methods: {
    async createChannel() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      try {
        const lineChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.channelName,
            channel: {
              type: 'line',
              line_channel_id: this.lineChannelId,
              line_channel_secret: this.lineChannelSecret,
              line_channel_token: this.lineChannelToken,
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: lineChannel.id,
          },
        });
      } catch (error) {
        this.showAlert(
          this.$t('INBOX_MGMT.ADD.LINE_CHANNEL.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>
