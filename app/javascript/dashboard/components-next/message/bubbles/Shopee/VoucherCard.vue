<script setup>
import { useI18n } from 'vue-i18n';
import {
  currencyFormatter,
  percentageFormatter,
  timeFormatter,
} from 'next/message/bubbles/Shopee/helper/formatter.js';
const { t } = useI18n();
</script>

<script>
export default {
  name: 'VoucherCard',
  props: {
    original: {
      type: Object,
      default: () => ({}),
    },
    cached: {
      type: Object,
      default: () => ({}),
    },
  },
};
</script>

<template>
  <div class="shopee-voucher">
    <template v-if="cached.code">
      <div class="flex items-center rounded-lg min-w-[350px]">
        <div
          class="py-5 px-3 text-center text-n-slate-10 text-sm font-medium border-dashed border-r border-r-2 border-r-slate-200 dark:border-r-slate-600"
        >
          {{ cached.code }}
        </div>
        <div class="px-5 py-3 flex flex-col flex-auto">
          <div
            v-if="cached.meta.discountAmount"
            class="text-lg text-slate-900 dark:text-slate-100 font-semibold"
          >
            {{ currencyFormatter(cached.meta.discountAmount) }}
          </div>
          <div
            v-if="cached.meta.percentage"
            class="flex flex-row justify-between items-center text-slate-900 dark:text-slate-100 font-semibold"
          >
            <span class="text-lg">
              {{ percentageFormatter(cached.meta.percentage) }}
            </span>
            <span
              v-if="cached.meta.maxPrice"
              class="text-sm text-slate-500 dark:text-slate-400"
            >
              {{
                t('CONVERSATION.SHOPEE.VOUCHERS.MAX_DISCOUNT', {
                  value: currencyFormatter(cached.meta.maxPrice),
                })
              }}
            </span>
          </div>
          <div class="text-xs text-slate-500 dark:text-slate-400">
            {{ cached.name }}
          </div>
          <div class="text-xs text-slate-500 dark:text-slate-400">
            {{ t('CONVERSATION.SHOPEE.VOUCHERS.MIN_BASKET') }}
            {{ currencyFormatter(cached.meta.minBasketPrice) }}
          </div>
          <div class="text-xs text-slate-500 dark:text-slate-400">
            {{ t('CONVERSATION.SHOPEE.VOUCHERS.VALID_UNTIL') }}
            {{ timeFormatter(cached.endTime) }}
          </div>
        </div>
      </div>
    </template>
    <template v-else>
      <div class="flex items-center rounded-lg py-3">
        <span
          class="py-5 px-3 text-center text-n-slate-10 text-sm font-medium border-dashed border-r border-r-2 border-r-slate-200 dark:border-r-slate-600"
        >
          {{ t('CONVERSATION.SHOPEE.VOUCHER') }}
        </span>
        <span
          class="font-semibold text-center text-n-slate-12 text-end px-5 py-3 text-base tracking-[0.2rem]"
        >
          {{ original.voucherCode }}
        </span>
      </div>
    </template>
  </div>
</template>

<style lang="scss">
.shopee-voucher {
  @apply rounded-lg my-4 max-w-full bg-white dark:bg-slate-800;

  box-shadow:
    rgba(14, 63, 126, 0.04) 0px 0px 0px 1px,
    rgba(42, 51, 69, 0.04) 0px 1px 1px -0.5px,
    rgba(42, 51, 70, 0.04) 0px 3px 3px -1.5px,
    rgba(42, 51, 70, 0.04) 0px 6px 6px -3px,
    rgba(14, 63, 126, 0.04) 0px 12px 12px -6px,
    rgba(14, 63, 126, 0.04) 0px 24px 24px -12px,
    rgba(0, 0, 0, 0.45) 0px 25px 20px -20px;
}
</style>
