<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import Switch from 'next/switch/Switch.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();

const method = ref('smtp');
const smtp = ref({
  address: '',
  port: 587,
  user_name: '',
  password: '',
  authentication: 'login',
  domain: '',
  enable_starttls_auto: true,
  ssl: false,
  tls: false,
  sender_email: '',
  sender_name: '',
});
const otpViaEmail = ref(false);
const crmModules = ref({
  deals: true,
  companies: true,
  tasks: true,
  reports: true,
});
const isSubmitting = ref(false);

const methodOptions = computed(() => [
  { id: 'smtp', name: t('EMAIL_WEBMAIL.FORM.METHOD.SMTP') },
  { id: 'sendmail', name: t('EMAIL_WEBMAIL.FORM.METHOD.SENDMAIL') },
]);
const authOptions = computed(() => [
  { id: 'login', name: 'LOGIN' },
  { id: 'plain', name: 'PLAIN' },
  { id: 'cram_md5', name: 'CRAM-MD5' },
]);

const syncFromAccount = () => {
  const settings = currentAccount.value?.settings || {};
  const cfg = settings.smtp_config || {};
  method.value = cfg.address ? 'smtp' : 'sendmail';
  smtp.value = {
    address: cfg.address || '',
    port: cfg.port || 587,
    user_name: cfg.user_name || '',
    password: cfg.password || '',
    authentication: cfg.authentication || 'login',
    domain: cfg.domain || '',
    enable_starttls_auto: cfg.enable_starttls_auto !== false,
    ssl: !!cfg.ssl,
    tls: !!cfg.tls,
    sender_email: cfg.sender_email || '',
    sender_name: cfg.sender_name || '',
  };
  otpViaEmail.value = !!settings.otp_via_email;
  crmModules.value = {
    deals: settings.crm_modules ? settings.crm_modules.deals !== false : true,
    companies: settings.crm_modules ? settings.crm_modules.companies !== false : true,
    tasks: settings.crm_modules ? settings.crm_modules.tasks !== false : true,
    reports: settings.crm_modules ? settings.crm_modules.reports !== false : true,
  };
};

watch(currentAccount, syncFromAccount, { immediate: true, deep: true });

const updateAccountSettings = async payload => {
  try {
    isSubmitting.value = true;
    await updateAccount(payload, { silent: true });
    useAlert(t('EMAIL_WEBMAIL.FORM.API.SUCCESS'));
  } catch (error) {
    useAlert(t('EMAIL_WEBMAIL.FORM.API.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

const handleSubmit = () => {
  const payload = {
    smtp_config: method.value === 'smtp' ? smtp.value : {},
    otp_via_email: otpViaEmail.value,
    crm_modules: crmModules.value,
  };
  return updateAccountSettings(payload);
};

const crmKeys = ['deals', 'companies', 'tasks', 'reports'];
</script>

<template>
  <div class="flex flex-col gap-4 w-full">
    <div class="flex flex-col w-full outline-1 outline outline-n-container rounded-xl bg-n-solid-2 divide-y divide-n-weak">
      <div class="flex flex-col gap-2 items-start px-5 py-4">
        <h3 class="text-heading-2 text-n-slate-12">{{ t('EMAIL_WEBMAIL.TITLE') }}</h3>
        <p class="mb-0 text-body-para text-n-slate-11">{{ t('EMAIL_WEBMAIL.NOTE') }}</p>
      </div>
      <div class="px-5 py-4">
        <form class="grid gap-5" @submit.prevent="handleSubmit">
          <WithLabel :label="t('EMAIL_WEBMAIL.FORM.METHOD.LABEL')">
            <SingleSelect v-model="method" :options="methodOptions" variant="faded" />
          </WithLabel>

          <template v-if="method === 'smtp'">
            <div class="grid grid-cols-2 gap-4">
              <WithLabel :label="t('EMAIL_WEBMAIL.FORM.SMTP.ADDRESS')">
                <input v-model="smtp.address" type="text" class="w-full px-2 py-1.5 rounded-md border border-n-weak bg-n-solid-1" />
              </WithLabel>
              <WithLabel :label="t('EMAIL_WEBMAIL.FORM.SMTP.PORT')">
                <input v-model="smtp.port" type="number" class="w-full px-2 py-1.5 rounded-md border border-n-weak bg-n-solid-1" />
              </WithLabel>
              <WithLabel :label="t('EMAIL_WEBMAIL.FORM.SMTP.USERNAME')">
                <input v-model="smtp.user_name" type="text" class="w-full px-2 py-1.5 rounded-md border border-n-weak bg-n-solid-1" />
              </WithLabel>
              <WithLabel :label="t('EMAIL_WEBMAIL.FORM.SMTP.PASSWORD')">
                <input v-model="smtp.password" type="password" class="w-full px-2 py-1.5 rounded-md border border-n-weak bg-n-solid-1" />
              </WithLabel>
              <WithLabel :label="t('EMAIL_WEBMAIL.FORM.SMTP.AUTH')">
                <SingleSelect v-model="smtp.authentication" :options="authOptions" variant="faded" />
              </WithLabel>
              <WithLabel :label="t('EMAIL_WEBMAIL.FORM.SMTP.DOMAIN')">
                <input v-model="smtp.domain" type="text" class="w-full px-2 py-1.5 rounded-md border border-n-weak bg-n-solid-1" />
              </WithLabel>
              <WithLabel :label="t('EMAIL_WEBMAIL.FORM.SMTP.SENDER_EMAIL')">
                <input v-model="smtp.sender_email" type="text" class="w-full px-2 py-1.5 rounded-md border border-n-weak bg-n-solid-1" />
              </WithLabel>
              <WithLabel :label="t('EMAIL_WEBMAIL.FORM.SMTP.SENDER_NAME')">
                <input v-model="smtp.sender_name" type="text" class="w-full px-2 py-1.5 rounded-md border border-n-weak bg-n-solid-1" />
              </WithLabel>
            </div>
            <div class="rounded-xl border border-n-weak bg-n-solid-1 divide-y divide-n-weak">
              <div class="p-3 h-12 flex items-center justify-between">
                <span>{{ t('EMAIL_WEBMAIL.FORM.SMTP.STARTTLS') }}</span>
                <Switch v-model="smtp.enable_starttls_auto" />
              </div>
              <div class="p-3 h-12 flex items-center justify-between">
                <span>{{ t('EMAIL_WEBMAIL.FORM.SMTP.SSL') }}</span>
                <Switch v-model="smtp.ssl" />
              </div>
              <div class="p-3 h-12 flex items-center justify-between">
                <span>{{ t('EMAIL_WEBMAIL.FORM.SMTP.TLS') }}</span>
                <Switch v-model="smtp.tls" />
              </div>
            </div>
          </template>

          <div class="rounded-xl border border-n-weak bg-n-solid-1 flex items-center justify-between p-3">
            <span>{{ t('EMAIL_WEBMAIL.FORM.OTP.LABEL') }}</span>
            <Switch v-model="otpViaEmail" />
          </div>

          <NextButton blue type="submit" :is-loading="isSubmitting" :label="t('EMAIL_WEBMAIL.FORM.SAVE')" />
        </form>
      </div>
    </div>

    <div class="flex flex-col w-full outline-1 outline outline-n-container rounded-xl bg-n-solid-2 divide-y divide-n-weak">
      <div class="flex flex-col gap-2 items-start px-5 py-4">
        <h3 class="text-heading-2 text-n-slate-12">{{ t('CRM_MODULES.TITLE') }}</h3>
        <p class="mb-0 text-body-para text-n-slate-11">{{ t('CRM_MODULES.NOTE') }}</p>
      </div>
      <div class="p-4 rounded-xl border border-n-weak bg-n-solid-1 divide-y divide-n-weak">
        <div v-for="key in crmKeys" :key="key" class="p-3 h-12 flex items-center justify-between">
          <span>{{ t(`CRM_MODULES.ITEMS.${key.toUpperCase()}`) }}</span>
          <Switch v-model="crmModules[key]" />
        </div>
      </div>
    </div>
  </div>
</template>
