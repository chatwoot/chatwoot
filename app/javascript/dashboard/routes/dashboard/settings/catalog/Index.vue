<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import catalogSettingsAPI from 'dashboard/api/catalogSettings';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SectionLayout from '../account/components/SectionLayout.vue';
import Switch from 'next/switch/Switch.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const store = useStore();

const isLoading = ref(true);
const isSaving = ref(false);
const catalogSettings = ref(null);

const isEnabled = ref(false);
const paymentProvider = ref(null);
const currency = ref('SAR');

const paymentProviders = [
  {
    label: t('CATALOG_SETTINGS.FORM.PAYMENT_PROVIDER.OPTIONS.NONE'),
    value: null,
  },
  { label: 'Tap', value: 'tap' },
  { label: 'Payzah', value: 'payzah' },
];

const availableCurrencies = computed(() => {
  if (paymentProvider.value === 'payzah') {
    return [{ label: 'KWD - Kuwaiti Dinar', value: 'KWD' }];
  }
  if (paymentProvider.value === 'tap') {
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
    const response = await catalogSettingsAPI.get();
    catalogSettings.value = response.data;
    isEnabled.value = response.data.enabled || false;
    paymentProvider.value = response.data.payment_provider || null;
    currency.value = response.data.currency || 'SAR';
  } catch {
    catalogSettings.value = null;
  } finally {
    isLoading.value = false;
  }
};

const saveSettings = async () => {
  try {
    isSaving.value = true;
    const data = {
      enabled: isEnabled.value,
      payment_provider: paymentProvider.value,
      currency: currency.value,
    };

    if (catalogSettings.value?.id) {
      await catalogSettingsAPI.update(data);
    } else {
      await catalogSettingsAPI.create(data);
    }

    useAlert(t('CATALOG_SETTINGS.API.SUCCESS'));
    await loadSettings();
    store.dispatch('accounts/get');
  } catch {
    useAlert(t('CATALOG_SETTINGS.API.ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const toggleEnabled = async () => {
  await saveSettings();
};

watch(paymentProvider, newProvider => {
  if (newProvider === 'payzah') {
    currency.value = 'KWD';
  } else if (!availableCurrencies.value.find(c => c.value === currency.value)) {
    currency.value = 'SAR';
  }
});

onMounted(() => {
  loadSettings();
});
</script>

<template>
  <div class="flex flex-col max-w-2xl mx-auto w-full">
    <BaseSettingsHeader
      :title="t('CATALOG_SETTINGS.TITLE')"
      :description="t('CATALOG_SETTINGS.DESCRIPTION')"
    />

    <div v-if="isLoading" class="flex justify-center py-8">
      <woot-loading-state />
    </div>

    <div v-else class="flex-grow flex-shrink min-w-0 mt-3">
      <SectionLayout
        :title="t('CATALOG_SETTINGS.FORM.ENABLE.TITLE')"
        :description="t('CATALOG_SETTINGS.FORM.ENABLE.DESCRIPTION')"
      >
        <template #headerActions>
          <div class="flex justify-end">
            <Switch v-model="isEnabled" @change="toggleEnabled" />
          </div>
        </template>
      </SectionLayout>

      <SectionLayout
        :title="t('CATALOG_SETTINGS.FORM.PAYMENT_PROVIDER.TITLE')"
        :description="t('CATALOG_SETTINGS.FORM.PAYMENT_PROVIDER.DESCRIPTION')"
        with-border
      >
        <div class="flex flex-col gap-3">
          <select v-model="paymentProvider" class="w-64">
            <option
              v-for="provider in paymentProviders"
              :key="provider.value"
              :value="provider.value"
            >
              {{ provider.label }}
            </option>
          </select>
          <p v-if="paymentProvider === null" class="text-sm text-n-slate-11">
            {{ t('CATALOG_SETTINGS.FORM.PAYMENT_PROVIDER.NO_PROVIDER_NOTE') }}
          </p>
        </div>
      </SectionLayout>

      <SectionLayout
        :title="t('CATALOG_SETTINGS.FORM.CURRENCY.TITLE')"
        :description="t('CATALOG_SETTINGS.FORM.CURRENCY.DESCRIPTION')"
        with-border
      >
        <div class="flex flex-col gap-3">
          <select
            v-model="currency"
            class="w-64"
            :disabled="paymentProvider === 'payzah'"
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
            v-if="paymentProvider === 'payzah'"
            class="text-sm text-n-amber-11"
          >
            {{ t('CATALOG_SETTINGS.FORM.CURRENCY.PAYZAH_NOTE') }}
          </p>
        </div>
      </SectionLayout>

      <div class="pt-6 border-t border-n-weak mt-6">
        <NextButton
          blue
          :is-loading="isSaving"
          :label="t('CATALOG_SETTINGS.FORM.SAVE')"
          @click="saveSettings"
        />
      </div>
    </div>
  </div>
</template>
