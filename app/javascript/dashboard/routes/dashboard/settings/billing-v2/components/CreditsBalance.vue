<script setup>
import { computed } from 'vue';
import BillingCard from '../../billing/components/BillingCard.vue';
import ButtonV4 from 'next/button/Button.vue';

const props = defineProps({
  balanceData: {
    type: Object,
    default: () => null,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['refresh']);

const currentBalance = computed(() => {
  return props.balanceData?.total_credits || 0;
});

const monthlyCredits = computed(() => {
  return props.balanceData?.monthly_credits || 0;
});

const topupCredits = computed(() => {
  return props.balanceData?.topup_credits || 0;
});

const usageThisMonth = computed(() => {
  return props.balanceData?.usage_this_month || 0;
});

const usageTotal = computed(() => {
  return props.balanceData?.usage_total || 0;
});

const currency = computed(() => {
  return props.balanceData?.currency || 'USD';
});

const ledger = computed(() => {
  return props.balanceData?.ledger || [];
});

const hasLedger = computed(() => {
  return ledger.value.length > 0;
});

const formatDate = timestamp => {
  if (!timestamp) return '';
  const date = new Date(timestamp);
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const formatAmount = amount => {
  if (!amount) return '0';
  return new Intl.NumberFormat('en-US').format(amount);
};

const formatMoney = amount => {
  if (!amount) return '$0.00';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currency.value,
  }).format(amount);
};

const getTransactionTypeColor = type => {
  const colorMap = {
    topup: 'text-g-800',
    subscription: 'text-b-800',
    usage: 'text-y-800',
    refund: 'text-p-800',
  };
  return colorMap[type?.toLowerCase()] || 'text-n-800';
};

const getTransactionTypeLabel = type => {
  if (!type) return '';
  return type.charAt(0).toUpperCase() + type.slice(1).toLowerCase();
};
</script>

<template>
  <BillingCard
    :title="$t('BILLING_SETTINGS_V2.CREDITS_BALANCE.TITLE')"
    :description="$t('BILLING_SETTINGS_V2.CREDITS_BALANCE.DESCRIPTION')"
  >
    <template #action>
      <ButtonV4
        sm
        faded
        slate
        icon="i-lucide-refresh-cw"
        :loading="isLoading"
        @click="emit('refresh')"
      >
        {{ $t('BILLING_SETTINGS_V2.CREDITS_BALANCE.REFRESH') }}
      </ButtonV4>
    </template>

    <!-- Current Balance -->
    <div class="px-5 pb-4">
      <div class="flex items-baseline gap-2">
        <span class="text-4xl font-bold text-n-800">
          {{ formatAmount(currentBalance) }}
        </span>
        <span class="text-base text-n-600">
          {{ $t('BILLING_SETTINGS_V2.CREDITS_BALANCE.CREDITS') }}
        </span>
      </div>
      <div class="mt-3 grid grid-cols-2 gap-4">
        <div>
          <p class="text-xs text-n-600 uppercase">Monthly Credits</p>
          <p class="text-lg font-semibold text-b-800">
            {{ formatAmount(monthlyCredits) }}
          </p>
        </div>
        <div>
          <p class="text-xs text-n-600 uppercase">Top-up Credits</p>
          <p class="text-lg font-semibold text-g-800">
            {{ formatAmount(topupCredits) }}
          </p>
        </div>
        <div>
          <p class="text-xs text-n-600 uppercase">Used This Month</p>
          <p class="text-lg font-semibold text-y-800">
            {{ formatAmount(usageThisMonth) }}
          </p>
        </div>
        <div>
          <p class="text-xs text-n-600 uppercase">Total Used</p>
          <p class="text-lg font-semibold text-n-700">
            {{ formatAmount(usageTotal) }}
          </p>
        </div>
      </div>
      <p class="mt-3 text-sm text-n-600">
        {{ $t('BILLING_SETTINGS_V2.CREDITS_BALANCE.USAGE_BASED_INFO') }}
      </p>
    </div>

    <!-- Credit Ledger -->
    <div v-if="hasLedger" class="border-t border-n-weak">
      <div class="px-5 py-3">
        <h4 class="text-sm font-semibold text-n-800">
          {{ $t('BILLING_SETTINGS_V2.CREDITS_BALANCE.LEDGER_TITLE') }}
        </h4>
      </div>
      <div class="px-5 pb-4">
        <div class="space-y-2">
          <div
            v-for="transaction in ledger.slice(0, 10)"
            :key="transaction.id"
            class="flex items-center justify-between py-2 border-b border-n-weak last:border-0"
          >
            <div class="flex-1">
              <div class="flex items-center gap-2">
                <span
                  class="text-sm font-medium"
                  :class="getTransactionTypeColor(transaction.type)"
                >
                  {{ getTransactionTypeLabel(transaction.type) }}
                </span>
                <span v-if="transaction.note" class="text-xs text-n-600">
                  - {{ transaction.note }}
                </span>
              </div>
              <div class="text-xs text-n-600 mt-0.5">
                {{ formatDate(transaction.ts) }}
              </div>
            </div>
            <div class="text-right">
              <div
                class="text-sm font-semibold"
                :class="
                  transaction.amount_credits > 0 ? 'text-g-800' : 'text-r-800'
                "
              >
                {{ transaction.amount_credits > 0 ? '+' : ''
                }}{{ formatAmount(transaction.amount_credits) }}
                {{ $t('BILLING_SETTINGS_V2.CREDITS_BALANCE.CREDITS_SHORT') }}
              </div>
              <div
                v-if="transaction.amount_money"
                class="text-xs text-n-600 mt-0.5"
              >
                {{ formatMoney(transaction.amount_money) }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </BillingCard>
</template>
