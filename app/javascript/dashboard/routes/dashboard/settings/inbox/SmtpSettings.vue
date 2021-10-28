<template>
  <div class="settings--content">
    <settings-section
      :title="$t('INBOX_MGMT.SMTP.TITLE')"
      :sub-title="$t('INBOX_MGMT.SMTP.SUBTITLE')"
    >
      <form @submit.prevent="updateInbox">
        <label for="toggle-enable-smtp">
          <input
            v-model="isSMTPEnabled"
            type="checkbox"
            name="toggle-enable-smtp"
          />
          {{ $t('INBOX_MGMT.SMTP.TOGGLE_AVAILABILITY') }}
        </label>
        <p>{{ $t('INBOX_MGMT.SMTP.TOGGLE_HELP') }}</p>
        <div v-if="isSMTPEnabled" class="smtp-details-wrap">
          <woot-input
            v-model.trim="address"
            class="medium-9 columns"
            label="Address"
            placeholder="Address (Eg: smtp.gmail.com)"
          />
          <woot-input
            v-model="port"
            class="medium-9 columns"
            label="Port"
            placeholder="Port"
          />
          <woot-input
            v-model="email"
            class="medium-9 columns"
            label="Email"
            placeholder="Email"
          />
          <woot-input
            v-model="password"
            class="medium-9 columns"
            label="Password"
            placeholder="Password"
            type="password"
          />
          <woot-input
            v-model.trim="domain"
            class="medium-9 columns"
            label="Domain"
            placeholder="Domain"
          />
        </div>
        <woot-submit-button
          :button-text="$t('INBOX_MGMT.SMTP.UPDATE')"
          :loading="uiFlags.isUpdatingInbox"
        />
      </form>
    </settings-section>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import SettingsSection from 'dashboard/components/SettingsSection';
import { required } from 'vuelidate/lib/validators';

export default {
  components: {
    SettingsSection,
  },
  mixins: [alertMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      isSMTPEnabled: false,
      address: '',
      port: '',
      email: '',
      password: '',
      domain: '',
    };
  },
  validations: {},
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  watch: {
    inbox() {
      this.setDefaults();
    },
  },
  mounted() {
    this.setDefaults();
  },
  methods: {
    setDefaults() {
      const {
        smtp_enabled,
        smtp_address,
        smtp_port,
        smtp_email,
        smtp_password,
        smtp_domain,
      } = this.inbox;
      this.isSMTPEnabled = smtp_enabled;
      this.address = smtp_address;
      this.port = smtp_port;
      this.email = smtp_email;
      this.password = smtp_password;
      this.domain = smtp_domain;
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            smtp_enabled: this.isSMTPEnabled,
            smtp_address: this.address,
            smtp_port: this.port,
            smtp_email: this.email,
            smtp_password: this.password,
            smtp_domain: this.domain,
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.smtp-details-wrap {
  margin-bottom: var(--space-medium);
}
</style>
