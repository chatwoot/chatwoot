<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import InputRadioGroup from './components/InputRadioGroup.vue';
import SingleSelectDropdown from './components/SingleSelectDropdown.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    SettingsSection,
    InputRadioGroup,
    SingleSelectDropdown,
    NextButton,
  },
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      isSMTPEnabled: false,
      address: '',
      port: '',
      login: '',
      password: '',
      domain: '',
      ssl: false,
      starttls: true,
      openSSLVerifyMode: 'none',
      authMechanism: 'login',
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
      authMechanisms: [
        { key: 1, value: 'plain' },
        { key: 2, value: 'login' },
        { key: 3, value: 'cram-md5' },
        { key: 4, value: 'xoauth' },
        { key: 5, value: 'xoauth2' },
        { key: 6, value: 'ntlm' },
        { key: 7, value: 'gssapi' },
      ],
    };
  },
  validations: {
    address: { required },
    port: {
      required,
      minLength: minLength(2),
    },
    login: { required },
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
        smtp_login,
        smtp_password,
        smtp_domain,
        smtp_enable_starttls_auto,
        smtp_enable_ssl_tls,
        smtp_openssl_verify_mode,
        smtp_authentication,
      } = this.inbox;
      this.isSMTPEnabled = smtp_enabled;
      this.address = smtp_address;
      this.port = smtp_port;
      this.login = smtp_login;
      this.password = smtp_password;
      this.domain = smtp_domain;
      this.starttls = smtp_enable_starttls_auto;
      this.ssl = smtp_enable_ssl_tls;
      this.openSSLVerifyMode = smtp_openssl_verify_mode;
      this.authMechanism = smtp_authentication;

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
    handleAuthMechanismChange(mode) {
      this.authMechanism = mode;
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          channel: {
            smtp_enabled: this.isSMTPEnabled,
            smtp_address: this.address,
            smtp_port: this.port,
            smtp_login: this.login,
            smtp_password: this.password,
            smtp_domain: this.domain,
            smtp_enable_ssl_tls: this.ssl,
            smtp_enable_starttls_auto: this.starttls,
            smtp_openssl_verify_mode: this.openSSLVerifyMode,
            smtp_authentication: this.authMechanism,
          },
        };
        await this.$store.dispatch('inboxes/updateInboxSMTP', payload);
        useAlert(this.$t('INBOX_MGMT.SMTP.EDIT.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.SMTP.EDIT.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<template>
  <div class="mx-8">
    <SettingsSection
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
        <div v-if="isSMTPEnabled" class="mb-6">
          <woot-input
            v-model="address"
            :class="{ error: v$.address.$error }"
            class="max-w-[75%] w-full"
            :label="$t('INBOX_MGMT.SMTP.ADDRESS.LABEL')"
            :placeholder="$t('INBOX_MGMT.SMTP.ADDRESS.PLACE_HOLDER')"
            @blur="v$.address.$touch"
          />
          <woot-input
            v-model="port"
            type="number"
            :class="{ error: v$.port.$error }"
            class="max-w-[75%] w-full"
            :label="$t('INBOX_MGMT.SMTP.PORT.LABEL')"
            :placeholder="$t('INBOX_MGMT.SMTP.PORT.PLACE_HOLDER')"
            @blur="v$.port.$touch"
          />
          <woot-input
            v-model="login"
            :class="{ error: v$.login.$error }"
            class="max-w-[75%] w-full"
            :label="$t('INBOX_MGMT.SMTP.LOGIN.LABEL')"
            :placeholder="$t('INBOX_MGMT.SMTP.LOGIN.PLACE_HOLDER')"
            @blur="v$.login.$touch"
          />
          <woot-input
            v-model="password"
            :class="{ error: v$.password.$error }"
            class="max-w-[75%] w-full"
            :label="$t('INBOX_MGMT.SMTP.PASSWORD.LABEL')"
            :placeholder="$t('INBOX_MGMT.SMTP.PASSWORD.PLACE_HOLDER')"
            type="password"
            @blur="v$.password.$touch"
          />
          <woot-input
            v-model="domain"
            :class="{ error: v$.domain.$error }"
            class="max-w-[75%] w-full"
            :label="$t('INBOX_MGMT.SMTP.DOMAIN.LABEL')"
            :placeholder="$t('INBOX_MGMT.SMTP.DOMAIN.PLACE_HOLDER')"
            @blur="v$.domain.$touch"
          />
          <InputRadioGroup
            :label="$t('INBOX_MGMT.SMTP.ENCRYPTION')"
            :items="encryptionProtocols"
            :action="handleEncryptionChange"
          />
          <SingleSelectDropdown
            class="max-w-[75%] w-full"
            :label="$t('INBOX_MGMT.SMTP.OPEN_SSL_VERIFY_MODE')"
            :selected="openSSLVerifyMode"
            :options="openSSLVerifyModes"
            :action="handleSSLModeChange"
          />
          <SingleSelectDropdown
            class="max-w-[75%] w-full"
            :label="$t('INBOX_MGMT.SMTP.AUTH_MECHANISM')"
            :selected="authMechanism"
            :options="authMechanisms"
            :action="handleAuthMechanismChange"
          />
        </div>
        <NextButton
          type="submit"
          :label="$t('INBOX_MGMT.SMTP.UPDATE')"
          :is-loading="uiFlags.isUpdatingSMTP"
          :disabled="(v$.$invalid && isSMTPEnabled) || uiFlags.isUpdatingSMTP"
        />
      </form>
    </SettingsSection>
  </div>
</template>
