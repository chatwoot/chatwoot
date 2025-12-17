<script setup>
import { ref, computed, watch } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minValue, numeric } from '@vuelidate/validators';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { usePaymentProviders } from 'dashboard/composables/usePaymentProviders';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  isSubmitting: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['cancel', 'update:show', 'submit']);

useI18n();
const { providers, isLoading, defaultProvider, hasMultipleProviders } =
  usePaymentProviders();

const amount = ref('');
const currency = ref('KWD');
const selectedProvider = ref('');

const currencies = [
  { value: 'KWD', label: 'KWD - Kuwaiti Dinar' },
  { value: 'USD', label: 'USD - US Dollar' },
  { value: 'SAR', label: 'SAR - Saudi Riyal' },
  { value: 'AED', label: 'AED - UAE Dirham' },
  { value: 'EUR', label: 'EUR - Euro' },
  { value: 'GBP', label: 'GBP - British Pound' },
  { value: 'BHD', label: 'BHD - Bahraini Dinar' },
  { value: 'QAR', label: 'QAR - Qatari Riyal' },
  { value: 'OMR', label: 'OMR - Omani Rial' },
  { value: 'EGP', label: 'EGP - Egyptian Pound' },
  { value: 'JOD', label: 'JOD - Jordanian Dinar' },
];

const rules = {
  amount: { required, numeric, minValue: minValue(0.01) },
  currency: { required },
};

const v$ = useVuelidate(rules, { amount, currency });

// Set default provider when providers are loaded
watch(defaultProvider, newValue => {
  if (newValue && !selectedProvider.value) {
    selectedProvider.value = newValue;
  }
});

const localShow = computed({
  get() {
    return props.show;
  },
  set(value) {
    emit('update:show', value);
  },
});

const isFormValid = computed(() => {
  return (
    !!amount.value &&
    !v$.value.amount.$error &&
    !!currency.value &&
    !v$.value.currency.$error &&
    (providers.value.length === 0 || !!selectedProvider.value)
  );
});

const showProviderSelector = computed(() => {
  return !isLoading.value && hasMultipleProviders();
});

const isPayzahSelected = computed(() => {
  return (
    selectedProvider.value === 'payzah' ||
    (!hasMultipleProviders() && defaultProvider.value === 'payzah')
  );
});

const amountLabel = computed(() => {
  if (isPayzahSelected.value) {
    return 'Amount (KWD)';
  }
  return null;
});

const availableCurrencies = computed(() => {
  if (isPayzahSelected.value) {
    return [{ value: 'KWD', label: 'KWD - Kuwaiti Dinar' }];
  }
  return currencies;
});

// Reset currency to KWD when switching to Payzah
watch(selectedProvider, newProvider => {
  if (newProvider === 'payzah') {
    currency.value = 'KWD';
  }
});

const resetForm = () => {
  amount.value = '';
  currency.value = 'KWD';
  selectedProvider.value = defaultProvider.value || '';
  v$.value.$reset();
};

const onCancel = () => {
  resetForm();
  emit('cancel');
};

const onSubmit = () => {
  v$.value.$touch();
  if (!isFormValid.value) {
    return;
  }

  const paymentData = {
    amount: parseFloat(amount.value),
    currency: currency.value,
  };

  // Only include provider if multiple providers are enabled
  if (hasMultipleProviders()) {
    paymentData.provider = selectedProvider.value;
  }

  emit('submit', paymentData);
};
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="onCancel">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header
        :header-title="$t('PAYMENT_LINK.TITLE')"
        :header-content="$t('PAYMENT_LINK.DESC')"
      />
      <form
        class="w-full modal-content pt-2 px-8 pb-8"
        @submit.prevent="onSubmit"
      >
        <div class="flex items-center mt-4 gap-2">
          <!-- Amount Input -->
          <div class="w-full">
            <label :class="{ error: v$.amount.$error }">
              {{ amountLabel || $t('PAYMENT_LINK.FORM.AMOUNT.LABEL') }}
              <input
                v-model="amount"
                type="number"
                step="0.01"
                min="0.01"
                :placeholder="$t('PAYMENT_LINK.FORM.AMOUNT.PLACEHOLDER')"
                @input="v$.amount.$touch"
              />
              <span v-if="v$.amount.$error" class="message">
                {{ $t('PAYMENT_LINK.FORM.AMOUNT.ERROR') }}
              </span>
            </label>
          </div>

          <!-- Currency Dropdown (hidden for Payzah) -->
          <div v-if="!isPayzahSelected" class="w-full">
            <label :class="{ error: v$.currency.$error }">
              {{ $t('PAYMENT_LINK.FORM.CURRENCY.LABEL') }}
              <select v-model="currency" @change="v$.currency.$touch">
                <option
                  v-for="curr in availableCurrencies"
                  :key="curr.value"
                  :value="curr.value"
                >
                  {{ curr.label }}
                </option>
              </select>
              <span v-if="v$.currency.$error" class="message">
                {{ $t('PAYMENT_LINK.FORM.CURRENCY.ERROR') }}
              </span>
            </label>
          </div>
        </div>

        <!-- Provider Selector (only when multiple providers are enabled) -->
        <div v-if="showProviderSelector" class="mt-4">
          <label>
            {{ $t('PAYMENT_LINK.FORM.PROVIDER.LABEL') }}
            <select v-model="selectedProvider">
              <option
                v-for="provider in providers"
                :key="provider.id"
                :value="provider.id"
              >
                {{ provider.name }}
              </option>
            </select>
          </label>
        </div>

        <!-- Action Buttons -->
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2 mt-6">
          <NextButton
            faded
            slate
            type="reset"
            :label="$t('PAYMENT_LINK.CANCEL')"
            :disabled="isSubmitting"
            @click.prevent="onCancel"
          />
          <NextButton
            type="submit"
            :label="$t('PAYMENT_LINK.SUBMIT')"
            :disabled="!isFormValid || isSubmitting"
            :loading="isSubmitting"
          />
        </div>
      </form>
    </div>
  </woot-modal>
</template>
