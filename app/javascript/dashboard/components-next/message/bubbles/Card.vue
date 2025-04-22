<script setup>
import BaseBubble from 'next/message/bubbles/Base.vue';
import ChatProductInfos from './Shopee/ChatProductInfos.vue';
import Voucher from './Shopee/Voucher.vue';
import { useMessageContext } from '../provider.js';
</script>

<script>
export default {
  name: 'CardBubble',
  components: {
    BaseBubble,
  },
  data() {
    const { contentAttributes } = useMessageContext();

    console.log('CardBubble', contentAttributes.value?.original);

    return {
      shopeeData: contentAttributes.value?.original || {},
    };
  },
  computed: {
    cardTitle() {
      const itemLabel = this.shopeeData?.itemLabel;
      if (!itemLabel) return '';
      if (itemLabel === 'custom') return '';
      return itemLabel.replace(/_/g, ' ');
    },
    isChatProductInfos() {
      return this.shopeeData?.chatProductInfos?.length > 0;
    },
    isVoucher() {
      return this.shopeeData?.voucherCode?.length > 0;
    },
  },
};
</script>

<template>
  <BaseBubble class="px-4 py-3" data-bubble-name="shopee-card">
    <p v-if="cardTitle" class="font-medium text-center capitalize mb-3">
      {{ cardTitle }}
    </p>
    <template v-if="isChatProductInfos">
      <ChatProductInfos :data="shopeeData" />
    </template>
    <template v-else-if="isVoucher">
      <Voucher :data="shopeeData" />
    </template>
    <template v-else>
      Unsupported card
    </template>
  </BaseBubble>
</template>
