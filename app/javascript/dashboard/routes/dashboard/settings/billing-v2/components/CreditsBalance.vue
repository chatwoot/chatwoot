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
  return props.balanceData?.current_available || 0;
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
  <div class="rounded-xl mx-5 mt-5">
    <div
      class="flex gap-6 mb-4 items-center justify-evenly rounded-xl dark:bg-n-solid-1 bg-n-slate-2 px-4 py-3"
    >
      <div>
        <p class="text-xs text-n-slate-11 mb-1">
          {{ t('BILLING_SETTINGS_V2.CREDITS_BALANCE.MONTHLY_CREDITS') }}
        </p>
        <div class="flex items-center gap-1.5">
          <p class="text-lg font-semibold text-n-slate-12 mb-0">
            {{ formatAmount(monthlyCredits) }}
          </p>
        </div>
      </div>

      <div
        class="bg-n-background rounded-lg grid place-content-center h-5 w-6 shadow-sm outline outline-1 outline-n-weak"
      >
        <Icon icon="i-lucide-plus" class="size-4 text-n-blue-8" />
      </div>

      <div>
        <p class="text-xs text-n-slate-11 mb-1">
          {{ t('BILLING_SETTINGS_V2.CREDITS_BALANCE.TOPUP_CREDITS') }}
        </p>
        <div class="flex items-center gap-1.5">
          <p class="text-lg font-semibold text-n-slate-12 mb-0">
            {{ formatAmount(topupCredits) }}
          </p>
        </div>
      </div>

      <div
        class="bg-n-background rounded-lg grid place-content-center h-5 w-6 shadow-sm outline outline-1 outline-n-weak"
      >
        <Icon icon="i-lucide-minus" class="size-4 text-n-ruby-8" />
      </div>

      <div>
        <p class="text-xs text-n-slate-11 mb-1">
          {{ t('BILLING_SETTINGS_V2.CREDITS_BALANCE.USED_THIS_MONTH') }}
        </p>
        <div class="flex items-center gap-1.5">
          <p class="text-lg font-semibold text-n-slate-12 mb-0">
            {{ formatAmount(usageThisMonth) }}
          </p>
        </div>
      </div>

      <div
        class="bg-n-background rounded-lg grid place-content-center h-5 w-6 shadow-sm outline outline-1 outline-n-weak"
      >
        <Icon icon="i-lucide-equal" class="size-4 text-n-teal-8" />
      </div>

      <div>
        <span class="flex items-center gap-2 mb-1">
          <div class="text-xs text-n-slate-11">
            {{ t('BILLING_SETTINGS_V2.CREDITS_BALANCE.CURRENT_BALANCE') }}
          </div>
          <Icon
            v-tooltip="
              t('BILLING_SETTINGS_V2.CREDITS_BALANCE.USAGE_BASED_INFO')
            "
            icon="i-lucide-circle-question-mark"
            class="size-3 text-n-slate-10"
          />
        </span>
        <div class="text-lg font-semibold text-n-slate-12">
          {{ formatAmount(currentBalance) }}
        </div>
      </div>

      <div class="hidden">
        <p class="text-xs text-n-slate-11 mb-1">
          {{ t('BILLING_SETTINGS_V2.CREDITS_BALANCE.TOTAL_USED') }}
        </p>
        <div class="flex items-center gap-1.5">
          <p class="text-lg font-semibold text-n-slate-12 mb-0">
            {{ formatAmount(usageTotal) }}
          </p>
        </div>
      </div>
    </div>

    <div class="flex items-center justify-between gap-2">
      <div class="space-x-2">
        <Button
          variant="faded"
          color="slate"
          size="sm"
          icon="i-lucide-refresh-cw"
          :is-loading="isLoading"
          @click="emit('refresh')"
        >
          {{ t('BILLING_SETTINGS_V2.CREDITS_BALANCE.REFRESH') }}
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
      <Button
        color="teal"
        size="sm"
        icon="i-lucide-plus"
        @click="emit('viewTopup')"
      >
        {{ t('BILLING_SETTINGS_V2.CREDITS_BALANCE.BUY_CREDITS') }}
      </Button>
    </div>
  </div>
</template>
