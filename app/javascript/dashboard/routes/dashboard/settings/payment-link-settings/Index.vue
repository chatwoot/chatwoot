<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import paymentLinkSettingsAPI from 'dashboard/api/paymentLinkSettings';
import { usePaymentProviders } from 'dashboard/composables/usePaymentProviders';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SectionLayout from '../account/components/SectionLayout.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const store = useStore();
const { providers: enabledProviders } = usePaymentProviders();

const isLoading = ref(true);
const isSaving = ref(false);
const settings = ref(null);

const defaultProvider = ref(null);
const defaultCurrency = ref('KWD');
const notificationEmail = ref('');

const paymentProviders = computed(() => [
  {
    label: t('PAYMENT_LINK_SETTINGS.FORM.DEFAULT_PROVIDER.OPTIONS.NONE'),
    value: null,
  },
  ...enabledProviders.value.map(p => ({
    label: p.name,
    value: p.id,
  })),
]);

const availableCurrencies = computed(() => {
  if (defaultProvider.value === 'payzah') {
    return [{ label: 'KWD - Kuwaiti Dinar', value: 'KWD' }];
  }
  if (defaultProvider.value === 'tap') {
    return [
      { label: 'KWD - Kuwaiti Dinar', value: 'KWD' },
      { label: 'SAR - Saudi Riyal', value: 'SAR' },
      { label: 'USD - US Dollar', value: 'USD' },
      { label: 'AED - UAE Dirham', value: 'AED' },
      { label: 'EUR - Euro', value: 'EUR' },
      { label: 'GBP - British Pound', value: 'GBP' },
      { label: 'BHD - Bahraini Dinar', value: 'BHD' },
      { label: 'QAR - Qatari Riyal', value: 'QAR' },
      { label: 'OMR - Omani Rial', value: 'OMR' },
      { label: 'EGP - Egyptian Pound', value: 'EGP' },
      { label: 'JOD - Jordanian Dinar', value: 'JOD' },
    ];
  }
  return [
    { label: 'KWD - Kuwaiti Dinar', value: 'KWD' },
    { label: 'SAR - Saudi Riyal', value: 'SAR' },
    { label: 'USD - US Dollar', value: 'USD' },
    { label: 'AED - UAE Dirham', value: 'AED' },
    { label: 'EUR - Euro', value: 'EUR' },
    { label: 'GBP - British Pound', value: 'GBP' },
    { label: 'BHD - Bahraini Dinar', value: 'BHD' },
    { label: 'QAR - Qatari Riyal', value: 'QAR' },
    { label: 'OMR - Omani Rial', value: 'OMR' },
    { label: 'EGP - Egyptian Pound', value: 'EGP' },
    { label: 'JOD - Jordanian Dinar', value: 'JOD' },
  ];
});

const loadSettings = async () => {
  try {
    isLoading.value = true;
    const response = await paymentLinkSettingsAPI.get();
    settings.value = response.data;
    defaultProvider.value = response.data.default_provider || null;
    defaultCurrency.value = response.data.default_currency || 'KWD';
    notificationEmail.value = response.data.notification_email || '';
  } catch {
    settings.value = null;
  } finally {
    isLoading.value = false;
  }
};

const saveSettings = async () => {
  try {
    isSaving.value = true;
    const data = {
      default_provider: defaultProvider.value,
      default_currency: defaultCurrency.value,
      notification_email: notificationEmail.value,
    };

    if (settings.value?.id) {
      await paymentLinkSettingsAPI.update(data);
    } else {
      await paymentLinkSettingsAPI.create(data);
    }

    useAlert(t('PAYMENT_LINK_SETTINGS.API.SUCCESS'));
    await loadSettings();
    store.dispatch('accounts/get');
  } catch {
    useAlert(t('PAYMENT_LINK_SETTINGS.API.ERROR'));
  } finally {
    isSaving.value = false;
  }
};

watch(defaultProvider, newProvider => {
  if (newProvider === 'payzah') {
    defaultCurrency.value = 'KWD';
  } else if (
    !availableCurrencies.value.find(c => c.value === defaultCurrency.value)
  ) {
    defaultCurrency.value = 'KWD';
  }
});

onMounted(() => {
  loadSettings();
});
</script>

<template>
  <div class="flex flex-col max-w-2xl mx-auto w-full">
    <BaseSettingsHeader
      :title="t('PAYMENT_LINK_SETTINGS.TITLE')"
      :description="t('PAYMENT_LINK_SETTINGS.DESCRIPTION')"
    />

    <div v-if="isLoading" class="flex justify-center py-8">
      <woot-loading-state />
    </div>

    <div v-else class="flex-grow flex-shrink min-w-0 mt-3">
      <SectionLayout
        :title="t('PAYMENT_LINK_SETTINGS.FORM.DEFAULT_PROVIDER.TITLE')"
        :description="
          t('PAYMENT_LINK_SETTINGS.FORM.DEFAULT_PROVIDER.DESCRIPTION')
        "
      >
        <div class="flex flex-col gap-3">
          <select v-model="defaultProvider" class="w-64">
            <option
              v-for="provider in paymentProviders"
              :key="provider.value"
              :value="provider.value"
            >
              {{ provider.label }}
            </option>
          </select>
          <p v-if="defaultProvider === null" class="text-sm text-n-slate-11">
            {{
              t('PAYMENT_LINK_SETTINGS.FORM.DEFAULT_PROVIDER.NO_PROVIDER_NOTE')
            }}
          </p>
        </div>
      </SectionLayout>

      <SectionLayout
        :title="t('PAYMENT_LINK_SETTINGS.FORM.DEFAULT_CURRENCY.TITLE')"
        :description="
          t('PAYMENT_LINK_SETTINGS.FORM.DEFAULT_CURRENCY.DESCRIPTION')
        "
        with-border
      >
        <div class="flex flex-col gap-3">
          <select
            v-model="defaultCurrency"
            class="w-64"
            :disabled="defaultProvider === 'payzah'"
          >
            <option
              v-for="curr in availableCurrencies"
              :key="curr.value"
              :value="curr.value"
            >
              {{ curr.label }}
            </option>
          </select>
          <p
            v-if="defaultProvider === 'payzah'"
            class="text-sm text-n-amber-11"
          >
            {{ t('PAYMENT_LINK_SETTINGS.FORM.DEFAULT_CURRENCY.PAYZAH_NOTE') }}
          </p>
        </div>
      </SectionLayout>

      <SectionLayout
        :title="t('PAYMENT_LINK_SETTINGS.FORM.NOTIFICATION_EMAIL.TITLE')"
        :description="
          t('PAYMENT_LINK_SETTINGS.FORM.NOTIFICATION_EMAIL.DESCRIPTION')
        "
        with-border
      >
        <div class="flex flex-col gap-3">
          <input
            v-model="notificationEmail"
            type="email"
            class="w-64"
            :placeholder="
              t('PAYMENT_LINK_SETTINGS.FORM.NOTIFICATION_EMAIL.PLACEHOLDER')
            "
          />
        </div>
      </SectionLayout>

      <div class="pt-6 border-t border-n-weak mt-6">
        <NextButton
          blue
          :is-loading="isSaving"
          :label="t('PAYMENT_LINK_SETTINGS.FORM.SAVE')"
          @click="saveSettings"
        />
      </div>
    </div>
  </div>
</template>
