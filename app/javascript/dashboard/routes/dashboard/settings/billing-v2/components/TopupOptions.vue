<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store.js';
import { useAlert } from 'dashboard/composables';
import BillingCard from '../../billing/components/BillingCard.vue';
import ButtonV4 from 'next/button/Button.vue';
import TopupModal from './TopupModal.vue';

const props = defineProps({
  options: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  isProcessing: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();

const store = useStore();

const showTopupModal = ref(false);
const selectedOption = ref(null);

const formatPrice = price => {
  if (!price) return '$0';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(price);
};

const formatNumber = num => {
  return new Intl.NumberFormat('en-US').format(num);
};

const openTopupModal = option => {
  selectedOption.value = option;
  showTopupModal.value = true;
};

const handleTopup = async data => {
  const result = await store.dispatch('accounts/v2Topup', data);
  if (result.success) {
    useAlert(t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.TOPUP_SUCCESS'));
    showTopupModal.value = false;
  } else if (result.error) {
    // Display validation error from API
    showTopupModal.value = false;

    // Check if it's a payment method error for custom message
    if (result.error.includes('payment method')) {
      useAlert(
        t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.NO_PAYMENT_METHOD_ERROR'),
        'warning'
      );
    } else {
      // Display the error message from API
      useAlert(result.error, 'warning');
    }
  }
};
</script>

<template>
  <div>
    <BillingCard
      :title="$t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.TITLE')"
      :description="$t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.DESCRIPTION')"
    >
      <div class="px-5 pb-5">
        <div class="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <div
            v-for="option in options"
            :key="option.id"
            class="p-4 border border-n-weak rounded-lg hover:border-b-500 hover:shadow-sm transition-all cursor-pointer"
            @click="openTopupModal(option)"
          >
            <div class="text-center">
              <div class="text-3xl font-bold text-b-800">
                {{ formatNumber(option.credits) }}
              </div>
              <div class="mt-1 text-xs text-n-600 uppercase tracking-wide">
                {{ $t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.CREDITS') }}
              </div>
              <div class="mt-3 text-2xl font-bold text-n-800">
                {{ formatPrice(option.price) }}
              </div>
              <p v-if="option.description" class="mt-2 text-xs text-n-600">
                {{ option.description }}
              </p>
              <ButtonV4
                class="w-full mt-4"
                sm
                solid
                blue
                @click.stop="openTopupModal(option)"
              >
                {{ $t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.BUY_NOW') }}
              </ButtonV4>
            </div>
          </div>
        </div>

        <!-- Empty State -->
        <div v-if="options.length === 0 && !isLoading" class="py-8 text-center">
          <p class="text-sm text-n-600">
            {{ $t('BILLING_SETTINGS_V2.TOPUP_OPTIONS.NO_OPTIONS') }}
          </p>
        </div>
      </div>
    </BillingCard>

    <!-- Topup Modal -->
    <TopupModal
      v-if="showTopupModal"
      :option="selectedOption"
      :is-processing="isProcessing"
      @close="showTopupModal = false"
      @topup="handleTopup"
    />
  </div>
</template>
