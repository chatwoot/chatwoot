<template>
  <div class="wizard-body small-9 columns">
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.XMPP.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.XMPP.DESC')"
    />
    <form class="row" @submit.prevent="createChannel()">
      <div class="medium-8 columns">
        <label :class="{ error: $v.channelName.$error }">
          {{ $t('INBOX_MGMT.ADD.XMPP.CHANNEL_NAME.LABEL') }}
          <input
            v-model.trim="channelName"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.XMPP.CHANNEL_NAME.PLACEHOLDER')"
            @blur="$v.channelName.$touch"
          />
          <span v-if="$v.channelName.$error" class="message">{{
            $t('INBOX_MGMT.ADD.XMPP.CHANNEL_NAME.ERROR')
          }}</span>
        </label>
      </div>

      <div class="medium-8 columns">
        <label :class="{ error: $v.jid.$error }">
          {{ $t('INBOX_MGMT.ADD.XMPP.JID.LABEL') }}
          <input
            v-model.trim="jid"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.XMPP.JID.PLACEHOLDER')"
            @blur="$v.jid.$touch"
          />
        </label>
      </div>

      <div class="medium-8 columns">
        <label :class="{ error: $v.password.$error }">
          {{ $t('INBOX_MGMT.ADD.XMPP.PASSWORD.LABEL') }}
          <input
            v-model.trim="password"
            type="password"
            :placeholder="$t('INBOX_MGMT.ADD.XMPP.PASSWORD.PLACEHOLDER')"
            @blur="$v.password.$touch"
          />
        </label>
      </div>

      <div class="medium-12 columns">
        <woot-submit-button
          :loading="uiFlags.isCreating"
          :button-text="$t('INBOX_MGMT.ADD.XMPP.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import { required, email } from 'vuelidate/lib/validators';
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
      jid: '',
      password: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    channelName: { required },
    jid: { required, email },
    password: { required },
  },
  methods: {
    async createChannel() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      try {
        const xmppChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.channelName,
            channel: {
              type: 'xmpp',
              jid: this.jid,
              password: this.password,
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: xmppChannel.id,
          },
        });
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.ADD.XMPP.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
