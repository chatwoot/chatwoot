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
            :class="{ error: $v.address.$error }"
            class="medium-9 columns"
            :label="$t('INBOX_MGMT.SMTP.ADDRESS.LABEL')"
            :placeholder="$t('INBOX_MGMT.SMTP.ADDRESS.PLACE_HOLDER')"
            @blur="$v.address.$touch"
          />
          <woot-input
            v-model="port"
            type="number"
            :class="{ error: $v.port.$error }"
            class="medium-9 columns"
            :label="$t('INBOX_MGMT.SMTP.PORT.LABEL')"
            :placeholder="$t('INBOX_MGMT.SMTP.PORT.PLACE_HOLDER')"
            @blur="$v.port.$touch"
          />
          <woot-input
            v-model="email"
            :class="{ error: $v.email.$error }"
            class="medium-9 columns"
            :label="$t('INBOX_MGMT.SMTP.EMAIL.LABEL')"
            :placeholder="$t('INBOX_MGMT.SMTP.EMAIL.PLACE_HOLDER')"
            @blur="$v.email.$touch"
          />
          <woot-input
            v-model="password"
            :class="{ error: $v.password.$error }"
            class="medium-9 columns"
            :label="$t('INBOX_MGMT.SMTP.PASSWORD.LABEL')"
            :placeholder="$t('INBOX_MGMT.SMTP.PASSWORD.PLACE_HOLDER')"
            type="password"
            @blur="$v.password.$touch"
          />
          <woot-input
            v-model.trim="domain"
            :class="{ error: $v.domain.$error }"
            class="medium-9 columns"
            :label="$t('INBOX_MGMT.SMTP.DOMAIN.LABEL')"
            :placeholder="$t('INBOX_MGMT.SMTP.DOMAIN.PLACE_HOLDER')"
            @blur="$v.domain.$touch"
          />
          <input-radio-group
            :label="$t('INBOX_MGMT.SMTP.ENCRYPTION')"
            :items="encryptionProtocols"
            :action="handleEncryptionChange"
          />
          <single-select-dropdown
            class="medium-9 columns"
            :label="$t('INBOX_MGMT.SMTP.OPEN_SSL_VERIFY_MODE')"
            :selected="openSSLVerifyMode"
            :options="openSSLVerifyModes"
            :action="handleSSLModeChange"
          />
        </div>
        <woot-submit-button
          :button-text="$t('INBOX_MGMT.SMTP.UPDATE')"
          :loading="uiFlags.isUpdatingInbox"
          :disabled="($v.$invalid && isSMTPEnabled) || uiFlags.isUpdatingSMTP"
        />
      </form>
    </settings-section>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import SettingsSection from 'dashboard/components/SettingsSection';
import { required, minLength, email } from 'vuelidate/lib/validators';
import InputRadioGroup from './components/InputRadioGroup';
import SingleSelectDropdown from './components/SingleSelectDropdown';

export default {
  components: {
    SettingsSection,
    InputRadioGroup,
    SingleSelectDropdown,
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
      ssl: false,
      starttls: true,
      openSSLVerifyMode: 'none',
      encryptionProtocols: [
        { id: 'ssl', title: 'SSL/TLS', checked: false },
        { id: 'starttls', title: 'STARTTLS', checked: true },
      ],
      openSSLVerifyModes: [
        { key: 1, value: 'none' },
        { key: 2, value: 'peer' },
        { key: 3, value: 'client_once' },
        { key: 4, value: 'fail_if_no_peer_cert' },
      ],
    };
  },
  validations: {
    address: { required },
    port: {
      required,
      minLength: minLength(2),
    },
    email: { required, email },
    password: { required },
    domain: { required },
  },
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
        smtp_enable_starttls_auto,
        smtp_enable_ssl_tls,
        smtp_openssl_verify_mode,
      } = this.inbox;
      this.isSMTPEnabled = smtp_enabled;
      this.address = smtp_address;
      this.port = smtp_port;
      this.email = smtp_email;
      this.password = smtp_password;
      this.domain = smtp_domain;
      this.starttls = smtp_enable_starttls_auto;
      this.ssl = smtp_enable_ssl_tls;
      this.openSSLVerifyMode = smtp_openssl_verify_mode;

      this.encryptionProtocols = [
        { id: 'ssl', title: 'SSL/TLS', checked: smtp_enable_ssl_tls },
        {
          id: 'starttls',
          title: 'STARTTLS',
          checked: smtp_enable_starttls_auto,
        },
      ];
    },
    handleEncryptionChange(encryption) {
      if (encryption.id === 'ssl') {
        this.ssl = true;
        this.starttls = false;
      } else {
        this.ssl = false;
        this.starttls = true;
      }
    },
    handleSSLModeChange(mode) {
      this.openSSLVerifyMode = mode;
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
            smtp_enable_ssl_tls: this.ssl,
            smtp_enable_starttls_auto: this.starttls,
            smtp_openssl_verify_mode: this.openSSLVerifyMode,
          },
        };
        await this.$store.dispatch('inboxes/updateInboxSMTP', payload);
        this.showAlert(this.$t('INBOX_MGMT.SMTP.EDIT.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.SMTP.EDIT.ERROR_MESSAGE'));
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
