<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';

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

const emit = defineEmits(['refresh', 'viewTopup', 'viewHistory']);

const { t } = useI18n();

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

const formatAmount = amount => {
  if (!amount) return '0';
  return new Intl.NumberFormat('en-US').format(amount);
};
</script>

<template>
  <div
    class="p-5 rounded-xl outline outline-1 outline-n-weak bg-n-solid-1 mx-5 mt-5"
  >
    <div class="p-4 rounded-lg bg-n-slate-2 dark:bg-n-solid-2 mb-4">
      <div class="flex items-baseline gap-2 mb-1">
        <span class="text-4xl font-bold text-n-slate-12">
          {{ formatAmount(currentBalance) }}
        </span>
        <span class="text-base text-n-slate-11">
          {{ t('BILLING_SETTINGS_V2.CREDITS_BALANCE.CREDITS') }}
        </span>
      </div>
      <p class="text-xs text-n-slate-11 mb-0">
        {{ t('BILLING_SETTINGS_V2.CREDITS_BALANCE.USAGE_BASED_INFO') }}
      </p>
    </div>

    <div class="grid grid-cols-2 gap-6 mb-4">
      <div>
        <p class="text-xs text-n-slate-11 mb-1">
          {{ t('BILLING_SETTINGS_V2.CREDITS_BALANCE.MONTHLY_CREDITS') }}
        </p>
        <div class="flex items-center gap-1.5">
          <Icon icon="i-lucide-calendar-check" class="text-n-blue-9" />
          <p class="text-lg font-semibold text-n-slate-12 mb-0">
            {{ formatAmount(monthlyCredits) }}
          </p>
        </div>
      </div>

      <div>
        <p class="text-xs text-n-slate-11 mb-1">
          {{ t('BILLING_SETTINGS_V2.CREDITS_BALANCE.TOPUP_CREDITS') }}
        </p>
        <div class="flex items-center gap-1.5">
          <Icon icon="i-lucide-plus-circle" class="text-n-teal-9" />
          <p class="text-lg font-semibold text-n-slate-12 mb-0">
            {{ formatAmount(topupCredits) }}
          </p>
        </div>
      </div>

      <div>
        <p class="text-xs text-n-slate-11 mb-1">
          {{ t('BILLING_SETTINGS_V2.CREDITS_BALANCE.USED_THIS_MONTH') }}
        </p>
        <div class="flex items-center gap-1.5">
          <Icon icon="i-lucide-trending-down" class="text-n-amber-9" />
          <p class="text-lg font-semibold text-n-slate-12 mb-0">
            {{ formatAmount(usageThisMonth) }}
          </p>
        </div>
      </div>

      <div>
        <p class="text-xs text-n-slate-11 mb-1">
          {{ t('BILLING_SETTINGS_V2.CREDITS_BALANCE.TOTAL_USED') }}
        </p>
        <div class="flex items-center gap-1.5">
          <Icon icon="i-lucide-bar-chart-3" class="text-n-slate-9" />
          <p class="text-lg font-semibold text-n-slate-12 mb-0">
            {{ formatAmount(usageTotal) }}
          </p>
        </div>
      </div>
    </div>

    <div
      class="flex items-center justify-end gap-2 pt-4 border-t border-n-weak"
    >
      <Button
        variant="faded"
        color="blue"
        size="sm"
        icon="i-lucide-refresh-cw"
        :is-loading="isLoading"
        @click="emit('refresh')"
      >
        {{ t('BILLING_SETTINGS_V2.CREDITS_BALANCE.REFRESH') }}
      </Button>
      <Button
        variant="faded"
        color="teal"
        size="sm"
        icon="i-lucide-plus-circle"
        @click="emit('viewTopup')"
      >
        {{ t('BILLING_SETTINGS_V2.CREDITS_BALANCE.BUY_CREDITS') }}
      </Button>
      <Button
        variant="faded"
        color="slate"
        size="sm"
        icon="i-lucide-history"
        @click="emit('viewHistory')"
      >
        {{ t('BILLING_SETTINGS_V2.CREDITS_BALANCE.VIEW_HISTORY') }}
      </Button>
    </div>
  </div>
</template>
