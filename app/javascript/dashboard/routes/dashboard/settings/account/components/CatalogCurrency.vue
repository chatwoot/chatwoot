<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import SectionLayout from './SectionLayout.vue';
import payzahSettingsAPI from 'dashboard/api/payzahSettings';
import tapSettingsAPI from 'dashboard/api/tapSettings';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();

const selectedCurrency = ref('SAR');
const payzahEnabled = ref(false);
const tapEnabled = ref(false);

const currencies = [
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

const showPayzahWarning = computed(() => {
  return (
    selectedCurrency.value !== 'KWD' && payzahEnabled.value && !tapEnabled.value
  );
});

watch(
  currentAccount,
  () => {
    const { catalog_currency } = currentAccount.value?.settings || {};
    selectedCurrency.value = catalog_currency || 'SAR';
  },
  { deep: true, immediate: true }
);

const loadPaymentGatewayStatus = async () => {
  try {
    const payzahResponse = await payzahSettingsAPI.get();
    payzahEnabled.value = !!payzahResponse.data?.enabled;
  } catch {
    payzahEnabled.value = false;
  }

  try {
    const tapResponse = await tapSettingsAPI.get();
    tapEnabled.value = !!tapResponse.data?.enabled;
  } catch {
    tapEnabled.value = false;
  }
};

onMounted(() => {
  loadPaymentGatewayStatus();
});

const updateCurrency = async () => {
  try {
    await updateAccount({ catalog_currency: selectedCurrency.value });
    useAlert(t('GENERAL_SETTINGS.FORM.CATALOG_CURRENCY.API.SUCCESS'));
  } catch {
    useAlert(t('GENERAL_SETTINGS.FORM.CATALOG_CURRENCY.API.ERROR'));
  }
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.CATALOG_CURRENCY.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.CATALOG_CURRENCY.NOTE')"
    with-border
  >
    <div class="flex flex-col gap-3">
      <select v-model="selectedCurrency" class="w-64" @change="updateCurrency">
        <option
          v-for="curr in currencies"
          :key="curr.value"
          :value="curr.value"
        >
          {{ curr.label }}
        </option>
      </select>
      <div
        v-if="showPayzahWarning"
        class="p-3 bg-n-amber-2 border border-n-amber-6 rounded-lg text-n-amber-11 text-sm"
      >
        {{ t('GENERAL_SETTINGS.FORM.CATALOG_CURRENCY.PAYZAH_WARNING') }}
      </div>
    </div>
  </SectionLayout>
</template>
