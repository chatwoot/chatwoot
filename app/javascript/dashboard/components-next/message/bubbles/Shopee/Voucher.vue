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
  <p class="shopee-voucher">
    <span class="font-medium text-n-slate-11">
      MESSAGE.SHOPEE.VOUCHER
    </span>
    <span class="voucherCode">{{ cardData.voucherCode }}</span>
  </p>
</template>

<style lang="scss">
.shopee-voucher {
  @apply bg-white p-5 drop-shadow-md mb-4 min-h-[4rem] inline-flex items-center min-w-[22rem] py-3 px-4 border-l-4 border-dotted;

  .voucherCode {
    @apply font-bold text-center text-n-slate-11;
  }
}
</style>
