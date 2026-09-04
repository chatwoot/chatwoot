<script setup>
import { computed, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useVuelidate } from '@vuelidate/core';
import {
  email as emailRule,
  required,
  requiredIf,
} from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';

import PageHeader from '../../../SettingsSubPageHeader.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const IMAP_AUTH_OPTIONS = ['plain', 'login', 'cram-md5'];
const SMTP_AUTH_OPTIONS = [
  'plain',
  'login',
  'cram-md5',
  'xoauth',
  'xoauth2',
  'ntlm',
  'gssapi',
];
const SMTP_VERIFY_OPTIONS = [
  'none',
  'peer',
  'client_once',
  'fail_if_no_peer_cert',
];

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const uiFlags = useMapGetter('inboxes/getUIFlags');

const state = reactive({
  channelName: '',
  email: '',
  imapAddress: '',
  imapPort: 993,
  imapLogin: '',
  imapPassword: '',
  imapEnableSSL: true,
  imapAuthentication: 'plain',
  imapFetchInterval: 1,
  smtpAddress: '',
  smtpPort: 587,
  smtpLogin: '',
  smtpPassword: '',
  smtpDomain: '',
  smtpEncryption: 'starttls',
  smtpVerifyMode: 'none',
  smtpAuthentication: 'login',
});

const selectOptions = options =>
  options.map(value => ({ label: value, value }));

const importWindowOptions = computed(() => [
  {
    value: 1,
    label: t('INBOX_MGMT.ADD.EMAIL_CHANNEL.IMPORT_OPTIONS.ONE_DAY'),
  },
  {
    value: 7,
    label: t('INBOX_MGMT.ADD.EMAIL_CHANNEL.IMPORT_OPTIONS.SEVEN_DAYS'),
  },
  {
    value: 30,
    label: t('INBOX_MGMT.ADD.EMAIL_CHANNEL.IMPORT_OPTIONS.THIRTY_DAYS'),
  },
]);

const isSMTPConfigured = computed(() =>
  [
    state.smtpAddress,
    state.smtpLogin,
    state.smtpPassword,
    state.smtpDomain,
  ].some(value => value?.trim())
);

const smtpRequired = requiredIf(() => isSMTPConfigured.value);

const validationRules = {
  channelName: { required },
  email: { required, email: emailRule },
  imapAddress: { required },
  imapPort: { required },
  imapLogin: { required },
  imapPassword: { required },
  smtpAddress: { required: smtpRequired },
  smtpPort: { required: smtpRequired },
  smtpLogin: { required: smtpRequired },
  smtpPassword: { required: smtpRequired },
  smtpDomain: { required: smtpRequired },
};

const v$ = useVuelidate(validationRules, state);
const fieldState = field => (v$.value[field]?.$error ? 'error' : 'info');

watch(
  () => state.email,
  value => {
    state.imapLogin = state.imapLogin || value;
  }
);

const buildChannelPayload = () => ({
  type: 'email',
  email: state.email,
  imap_enabled: true,
  imap_address: state.imapAddress,
  imap_port: state.imapPort,
  imap_login: state.imapLogin,
  imap_password: state.imapPassword,
  imap_enable_ssl: state.imapEnableSSL,
  imap_authentication: state.imapAuthentication,
  smtp_enabled: isSMTPConfigured.value,
  smtp_address: state.smtpAddress,
  smtp_port: state.smtpPort,
  smtp_login: state.smtpLogin,
  smtp_password: state.smtpPassword,
  smtp_domain: state.smtpDomain,
  smtp_enable_ssl_tls: state.smtpEncryption === 'ssl',
  smtp_enable_starttls_auto: state.smtpEncryption === 'starttls',
  smtp_openssl_verify_mode: state.smtpVerifyMode,
  smtp_authentication: state.smtpAuthentication,
});

async function createChannel() {
  const isValid = await v$.value.$validate();
  if (!isValid) return;

  try {
    const emailChannel = await store.dispatch('inboxes/createChannel', {
      name: state.channelName.trim(),
      imap_fetch_interval: state.imapFetchInterval,
      channel: buildChannelPayload(),
    });

    router.replace({
      name: 'settings_inboxes_add_agents',
      params: { page: 'new', inbox_id: emailChannel.id },
    });
  } catch (error) {
    useAlert(
      error?.message || t('INBOX_MGMT.ADD.EMAIL_CHANNEL.API.ERROR_MESSAGE')
    );
  }
}
</script>

<template>
  <div class="overflow-auto col-span-6 p-6 w-full h-full">
    <PageHeader
      :header-title="t('INBOX_MGMT.ADD.EMAIL_CHANNEL.TITLE')"
      :header-content="t('INBOX_MGMT.ADD.EMAIL_CHANNEL.DESC')"
    />

    <form class="max-w-3xl" @submit.prevent="createChannel">
      <div class="grid grid-cols-1 gap-x-4 md:grid-cols-2">
        <Input
          v-model="state.channelName"
          :label="t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_NAME.LABEL')"
          :placeholder="
            t('INBOX_MGMT.ADD.EMAIL_CHANNEL.CHANNEL_NAME.PLACEHOLDER')
          "
          :message-type="fieldState('channelName')"
          @blur="v$.channelName.$touch"
        />
        <Input
          v-model="state.email"
          :label="t('INBOX_MGMT.ADD.EMAIL_CHANNEL.EMAIL.LABEL')"
          :placeholder="t('INBOX_MGMT.ADD.EMAIL_CHANNEL.EMAIL.PLACEHOLDER')"
          :message-type="fieldState('email')"
          @blur="v$.email.$touch"
        />
      </div>

      <section class="pt-5 mt-6 border-t border-n-weak">
        <h3 class="mb-1 text-sm font-medium text-n-slate-12">
          {{ t('INBOX_MGMT.IMAP.TITLE') }}
        </h3>
        <p class="mb-4 text-sm text-n-slate-11">
          {{ t('INBOX_MGMT.IMAP.CREATE_HELP') }}
        </p>

        <div class="grid grid-cols-1 gap-x-4 gap-y-4 md:grid-cols-2">
          <Input
            v-model="state.imapAddress"
            :label="t('INBOX_MGMT.IMAP.ADDRESS.LABEL')"
            :placeholder="t('INBOX_MGMT.IMAP.ADDRESS.PLACE_HOLDER')"
            :message-type="fieldState('imapAddress')"
            @blur="v$.imapAddress.$touch"
          />
          <div class="flex flex-col gap-2">
            <Input
              v-model="state.imapPort"
              type="number"
              :label="t('INBOX_MGMT.IMAP.PORT.LABEL')"
              :placeholder="t('INBOX_MGMT.IMAP.PORT.PLACE_HOLDER')"
              :message-type="fieldState('imapPort')"
              @blur="v$.imapPort.$touch"
            />
            <label
              for="imap-enable-ssl"
              class="flex items-center gap-2 text-sm font-medium text-n-slate-12"
            >
              <input
                id="imap-enable-ssl"
                v-model="state.imapEnableSSL"
                type="checkbox"
              />
              {{ t('INBOX_MGMT.IMAP.ENABLE_SSL') }}
            </label>
          </div>
          <Input
            v-model="state.imapLogin"
            :label="t('INBOX_MGMT.IMAP.LOGIN.LABEL')"
            :placeholder="t('INBOX_MGMT.IMAP.LOGIN.PLACE_HOLDER')"
            :message-type="fieldState('imapLogin')"
            @blur="v$.imapLogin.$touch"
          />
          <Input
            v-model="state.imapPassword"
            type="password"
            :label="t('INBOX_MGMT.IMAP.PASSWORD.LABEL')"
            :placeholder="t('INBOX_MGMT.IMAP.PASSWORD.PLACE_HOLDER')"
            :message-type="fieldState('imapPassword')"
            @blur="v$.imapPassword.$touch"
          />
        </div>

        <div class="grid grid-cols-1 gap-x-4 gap-y-4 mt-4 md:grid-cols-2">
          <label class="flex flex-col gap-1">
            <span class="text-heading-3 text-n-slate-12">
              {{ t('INBOX_MGMT.IMAP.AUTH_MECHANISM') }}
            </span>
            <Select
              v-model="state.imapAuthentication"
              :options="selectOptions(IMAP_AUTH_OPTIONS)"
            />
          </label>
          <label class="flex flex-col gap-1">
            <span class="text-heading-3 text-n-slate-12">
              {{ t('INBOX_MGMT.ADD.EMAIL_CHANNEL.FETCH_EMAILS_FROM') }}
            </span>
            <Select
              v-model="state.imapFetchInterval"
              :options="importWindowOptions"
            />
          </label>
        </div>
      </section>

      <section class="pt-5 mt-6 border-t border-n-weak">
        <h3 class="mb-1 text-sm font-medium text-n-slate-12">
          {{ t('INBOX_MGMT.SMTP.TITLE') }}
        </h3>
        <p class="mb-4 text-sm text-n-slate-11">
          {{ t('INBOX_MGMT.SMTP.CREATE_HELP') }}
        </p>

        <div class="grid grid-cols-1 gap-x-4 gap-y-4 md:grid-cols-2">
          <Input
            v-model="state.smtpAddress"
            :label="t('INBOX_MGMT.SMTP.ADDRESS.LABEL')"
            :placeholder="t('INBOX_MGMT.SMTP.ADDRESS.PLACE_HOLDER')"
            :message-type="fieldState('smtpAddress')"
            @blur="v$.smtpAddress.$touch"
          />
          <Input
            v-model="state.smtpPort"
            type="number"
            :label="t('INBOX_MGMT.SMTP.PORT.LABEL')"
            :placeholder="t('INBOX_MGMT.SMTP.PORT.PLACE_HOLDER')"
            :message-type="fieldState('smtpPort')"
            @blur="v$.smtpPort.$touch"
          />
          <Input
            v-model="state.smtpLogin"
            :label="t('INBOX_MGMT.SMTP.LOGIN.LABEL')"
            :placeholder="t('INBOX_MGMT.SMTP.LOGIN.PLACE_HOLDER')"
            :message-type="fieldState('smtpLogin')"
            @blur="v$.smtpLogin.$touch"
          />
          <Input
            v-model="state.smtpPassword"
            type="password"
            :label="t('INBOX_MGMT.SMTP.PASSWORD.LABEL')"
            :placeholder="t('INBOX_MGMT.SMTP.PASSWORD.PLACE_HOLDER')"
            :message-type="fieldState('smtpPassword')"
            @blur="v$.smtpPassword.$touch"
          />
          <Input
            v-model="state.smtpDomain"
            :label="t('INBOX_MGMT.SMTP.DOMAIN.LABEL')"
            :placeholder="t('INBOX_MGMT.SMTP.DOMAIN.PLACE_HOLDER')"
            :message-type="fieldState('smtpDomain')"
            @blur="v$.smtpDomain.$touch"
          />
          <label class="flex flex-col gap-1">
            <span class="text-heading-3 text-n-slate-12">
              {{ t('INBOX_MGMT.SMTP.AUTH_MECHANISM') }}
            </span>
            <Select
              v-model="state.smtpAuthentication"
              :options="selectOptions(SMTP_AUTH_OPTIONS)"
            />
          </label>
        </div>

        <div class="grid grid-cols-1 gap-x-4 gap-y-4 mt-4 md:grid-cols-2">
          <label class="flex flex-col gap-1">
            <span class="text-heading-3 text-n-slate-12">
              {{ t('INBOX_MGMT.SMTP.ENCRYPTION') }}
            </span>
            <Select
              v-model="state.smtpEncryption"
              :options="[
                { value: 'starttls', label: t('INBOX_MGMT.SMTP.START_TLS') },
                { value: 'ssl', label: t('INBOX_MGMT.SMTP.SSL_TLS') },
              ]"
            />
          </label>
          <label class="flex flex-col gap-1">
            <span class="text-heading-3 text-n-slate-12">
              {{ t('INBOX_MGMT.SMTP.OPEN_SSL_VERIFY_MODE') }}
            </span>
            <Select
              v-model="state.smtpVerifyMode"
              :options="selectOptions(SMTP_VERIFY_OPTIONS)"
            />
          </label>
        </div>
      </section>

      <div class="w-full mt-6">
        <NextButton
          :is-loading="uiFlags.isCreating"
          type="submit"
          solid
          blue
          :label="t('INBOX_MGMT.ADD.EMAIL_CHANNEL.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>
