<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
</script>

<script>
export default {
  name: 'Voucher',
  props: {
    data: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      cardData: this.data || {},
    };
  },
};
</script>

<template>
  <div class="shopee-voucher">
    <div class="flex items-center bg-n-alpha-3 rounded-lg">
      <span class="voucherLabel">
        {{ t('CONVERSATION.SHOPEE.VOUCHER') }}
      </span>
      <span class="voucherCode">
        {{ cardData.voucherCode }}
      </span>
    </div>
  </div>
</template>

<style lang="scss">
.shopee-voucher {
  @apply bg-white rounded-lg my-4 py-3;
  box-shadow:
    rgba(14, 63, 126, 0.04) 0px 0px 0px 1px,
    rgba(42, 51, 69, 0.04) 0px 1px 1px -0.5px,
    rgba(42, 51, 70, 0.04) 0px 3px 3px -1.5px,
    rgba(42, 51, 70, 0.04) 0px 6px 6px -3px,
    rgba(14, 63, 126, 0.04) 0px 12px 12px -6px,
    rgba(14, 63, 126, 0.04) 0px 24px 24px -12px,
    rgba(0, 0, 0, 0.45) 0px 25px 20px -20px;

  .voucherLabel {
    @apply py-5 px-6 text-center text-n-slate-10 text-sm font-medium text-n-slate-10;
    border-right: 3px dashed #e0e0e0;
  }

  .voucherCode {
    @apply font-semibold text-center text-n-slate-12 text-end px-12 py-5 text-lg;
    letter-spacing: 0.3rem;
  }
}
</style>
