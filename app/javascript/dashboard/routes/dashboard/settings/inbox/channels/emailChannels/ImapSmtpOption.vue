<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required, requiredIf, email } from '@vuelidate/validators';
import router from '../../../../../index';
import PageHeader from '../../../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    PageHeader,
    NextButton,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      channelName: '',
      email: '',
      imapAddress: '',
      imapPort: 993,
      imapLogin: '',
      imapPassword: '',
      imapEnableSSL: true,
      imapAuthentication: 'plain',
      smtpAddress: '',
      smtpPort: 587,
      smtpLogin: '',
      smtpPassword: '',
      smtpDomain: '',
      smtpEncryption: 'starttls',
      smtpVerifyMode: 'none',
      smtpAuthentication: 'login',
      imapFetchInterval: 1,
      imapAuthMechanisms: ['plain', 'login', 'cram-md5'],
      smtpVerifyModes: ['none', 'peer', 'client_once', 'fail_if_no_peer_cert'],
      smtpAuthMechanisms: [
        'plain',
        'login',
        'cram-md5',
        'xoauth',
        'xoauth2',
        'ntlm',
        'gssapi',
      ],
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
    isSMTPConfigured() {
      return [
        this.smtpAddress,
        this.smtpLogin,
        this.smtpPassword,
        this.smtpDomain,
      ].some(value => value?.trim());
    },
  },
  validations: {
    channelName: { required },
    email: { required, email },
    imapAddress: { required },
    imapPort: { required },
    imapLogin: { required },
    imapPassword: { required },
    smtpAddress: { required: requiredIf('isSMTPConfigured') },
    smtpPort: { required: requiredIf('isSMTPConfigured') },
    smtpLogin: { required: requiredIf('isSMTPConfigured') },
    smtpPassword: { required: requiredIf('isSMTPConfigured') },
    smtpDomain: { required: requiredIf('isSMTPConfigured') },
  },
  watch: {
    email(value) {
      const domain = value.split('@')[1] || '';
      this.imapLogin = this.imapLogin || value;
      this.smtpLogin = this.smtpLogin || value;
      this.smtpDomain = this.smtpDomain || domain;
    },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const emailChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.channelName?.trim(),
            imap_fetch_interval: this.imapFetchInterval,
            channel: {
              type: 'email',
              email: this.email,
              imap_enabled: true,
              imap_address: this.imapAddress,
              imap_port: this.imapPort,
              imap_login: this.imapLogin,
              imap_password: this.imapPassword,
              imap_enable_ssl: this.imapEnableSSL,
              imap_authentication: this.imapAuthentication,
              smtp_enabled: this.isSMTPConfigured,
              smtp_address: this.smtpAddress,
              smtp_port: this.smtpPort,
              smtp_login: this.smtpLogin,
              smtp_password: this.smtpPassword,
              smtp_domain: this.smtpDomain,
              smtp_enable_ssl_tls: this.smtpEncryption === 'ssl',
              smtp_enable_starttls_auto: this.smtpEncryption === 'starttls',
              smtp_openssl_verify_mode: this.smtpVerifyMode,
              smtp_authentication: this.smtpAuthentication,
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
        useAlert(
          error?.message ||
            this.$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.DESC')"
    />
    <form class="max-w-3xl" @submit.prevent="createChannel">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-x-4">
        <woot-input
          v-model="channelName"
          :class="{ error: v$.channelName.$error }"
          :label="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_NAME.LABEL')"
          :placeholder="
            $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_NAME.PLACEHOLDER')
          "
          @blur="v$.channelName.$touch"
        />
        <woot-input
          v-model="email"
          :class="{ error: v$.email.$error }"
          :label="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.EMAIL.LABEL')"
          :placeholder="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.EMAIL.PLACEHOLDER')"
          @blur="v$.email.$touch"
        />
      </div>

      <div class="mt-6 pt-5 border-t border-n-weak">
        <h3 class="mb-1 text-sm font-medium text-n-slate-12">
          {{ $t('INBOX_MGMT.IMAP.TITLE') }}
        </h3>
        <p class="mb-4 text-sm text-n-slate-11">
          {{ $t('INBOX_MGMT.IMAP.CREATE_HELP') }}
        </p>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-x-4">
          <woot-input
            v-model="imapAddress"
            :class="{ error: v$.imapAddress.$error }"
            :label="$t('INBOX_MGMT.IMAP.ADDRESS.LABEL')"
            :placeholder="$t('INBOX_MGMT.IMAP.ADDRESS.PLACE_HOLDER')"
            @blur="v$.imapAddress.$touch"
          />
          <div>
            <woot-input
              v-model="imapPort"
              type="number"
              :class="{ error: v$.imapPort.$error }"
              :label="$t('INBOX_MGMT.IMAP.PORT.LABEL')"
              :placeholder="$t('INBOX_MGMT.IMAP.PORT.PLACE_HOLDER')"
              @blur="v$.imapPort.$touch"
            />
            <label
              for="imap-enable-ssl"
              class="flex items-center -mt-2 mb-4 text-sm font-medium text-n-slate-12"
            >
              <input
                id="imap-enable-ssl"
                v-model="imapEnableSSL"
                type="checkbox"
                class="ltr:mr-2 rtl:ml-2"
              />
              {{ $t('INBOX_MGMT.IMAP.ENABLE_SSL') }}
            </label>
          </div>
          <woot-input
            v-model="imapLogin"
            :class="{ error: v$.imapLogin.$error }"
            :label="$t('INBOX_MGMT.IMAP.LOGIN.LABEL')"
            :placeholder="$t('INBOX_MGMT.IMAP.LOGIN.PLACE_HOLDER')"
            @blur="v$.imapLogin.$touch"
          />
          <woot-input
            v-model="imapPassword"
            type="password"
            :class="{ error: v$.imapPassword.$error }"
            :label="$t('INBOX_MGMT.IMAP.PASSWORD.LABEL')"
            :placeholder="$t('INBOX_MGMT.IMAP.PASSWORD.PLACE_HOLDER')"
            @blur="v$.imapPassword.$touch"
          />
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-x-4">
          <label>
            {{ $t('INBOX_MGMT.IMAP.AUTH_MECHANISM') }}
            <select v-model="imapAuthentication">
              <option
                v-for="authentication in imapAuthMechanisms"
                :key="authentication"
                :value="authentication"
              >
                {{ authentication }}
              </option>
            </select>
          </label>
          <label>
            {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.FETCH_EMAILS_FROM') }}
            <select v-model="imapFetchInterval">
              <option :value="1">
                {{ $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.IMPORT_OPTIONS.ONE_DAY') }}
              </option>
              <option :value="7">
                {{
                  $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.IMPORT_OPTIONS.SEVEN_DAYS')
                }}
              </option>
              <option :value="30">
                {{
                  $t('INBOX_MGMT.ADD.EMAIL_CHANNEL.IMPORT_OPTIONS.THIRTY_DAYS')
                }}
              </option>
            </select>
          </label>
        </div>
      </div>

      <div class="mt-6 pt-5 border-t border-n-weak">
        <div class="mb-4">
          <h3 class="mb-1 text-sm font-medium text-n-slate-12">
            {{ $t('INBOX_MGMT.SMTP.TITLE') }}
          </h3>
          <p class="text-sm text-n-slate-11">
            {{ $t('INBOX_MGMT.SMTP.CREATE_HELP') }}
          </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-x-4">
          <woot-input
            v-model="smtpAddress"
            :class="{ error: v$.smtpAddress.$error }"
            :label="$t('INBOX_MGMT.SMTP.ADDRESS.LABEL')"
            :placeholder="$t('INBOX_MGMT.SMTP.ADDRESS.PLACE_HOLDER')"
            @blur="v$.smtpAddress.$touch"
          />
          <woot-input
            v-model="smtpPort"
            type="number"
            :class="{ error: v$.smtpPort.$error }"
            :label="$t('INBOX_MGMT.SMTP.PORT.LABEL')"
            :placeholder="$t('INBOX_MGMT.SMTP.PORT.PLACE_HOLDER')"
            @blur="v$.smtpPort.$touch"
          />
          <woot-input
            v-model="smtpLogin"
            :class="{ error: v$.smtpLogin.$error }"
            :label="$t('INBOX_MGMT.SMTP.LOGIN.LABEL')"
            :placeholder="$t('INBOX_MGMT.SMTP.LOGIN.PLACE_HOLDER')"
            @blur="v$.smtpLogin.$touch"
          />
          <woot-input
            v-model="smtpPassword"
            type="password"
            :class="{ error: v$.smtpPassword.$error }"
            :label="$t('INBOX_MGMT.SMTP.PASSWORD.LABEL')"
            :placeholder="$t('INBOX_MGMT.SMTP.PASSWORD.PLACE_HOLDER')"
            @blur="v$.smtpPassword.$touch"
          />
          <woot-input
            v-model="smtpDomain"
            :class="{ error: v$.smtpDomain.$error }"
            :label="$t('INBOX_MGMT.SMTP.DOMAIN.LABEL')"
            :placeholder="$t('INBOX_MGMT.SMTP.DOMAIN.PLACE_HOLDER')"
            @blur="v$.smtpDomain.$touch"
          />
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-x-4">
          <label>
            {{ $t('INBOX_MGMT.SMTP.ENCRYPTION') }}
            <select v-model="smtpEncryption">
              <option value="starttls">
                {{ $t('INBOX_MGMT.SMTP.START_TLS') }}
              </option>
              <option value="ssl">{{ $t('INBOX_MGMT.SMTP.SSL_TLS') }}</option>
            </select>
          </label>
          <label>
            {{ $t('INBOX_MGMT.SMTP.OPEN_SSL_VERIFY_MODE') }}
            <select v-model="smtpVerifyMode">
              <option v-for="mode in smtpVerifyModes" :key="mode" :value="mode">
                {{ mode }}
              </option>
            </select>
          </label>
          <label>
            {{ $t('INBOX_MGMT.SMTP.AUTH_MECHANISM') }}
            <select v-model="smtpAuthentication">
              <option
                v-for="authentication in smtpAuthMechanisms"
                :key="authentication"
                :value="authentication"
              >
                {{ authentication }}
              </option>
            </select>
          </label>
        </div>
      </div>

      <div class="w-full mt-6">
        <NextButton
          :is-loading="uiFlags.isCreating"
          type="submit"
          solid
          blue
          :label="$t('INBOX_MGMT.ADD.EMAIL_CHANNEL.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>
