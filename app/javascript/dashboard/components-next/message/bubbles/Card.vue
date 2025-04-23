<script setup>
import BaseBubble from 'next/message/bubbles/Base.vue';
import ChatProductInfos from './Shopee/ChatProductInfos.vue';
import AddOnDealItemList from './Shopee/AddOnDealItemList.vue';
import Voucher from './Shopee/Voucher.vue';
import Activity from './Shopee/Activity.vue';
import ItemLink from './Shopee/ItemLink.vue';
import OrderLink from './Shopee/OrderLink.vue';
import { useMessageContext } from '../provider.js';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
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
      if (this.shopeeData?.name) return this.shopeeData?.name;

      const itemLabel = this.shopeeData?.itemLabel;
      if (!itemLabel) return '';
      if (itemLabel === 'custom') return '';
      return itemLabel.replace(/_/g, ' ');
    },
    isChatProductInfos() {
      return this.shopeeData?.chatProductInfos?.length > 0;
    },
    isAddOnDealItemList() {
      return this.shopeeData?.addOnDealItemList?.length > 0;
    },
    isVoucher() {
      return this.shopeeData?.voucherCode?.length > 0;
    },
    isTextMessage() {
      return this.shopeeData?.text?.length > 0;
    },
    isItemLink() {
      return this.shopeeData?.itemId && this.shopeeData?.shopId;
    },
    isOrderLink() {
      return this.shopeeData?.orderSn && this.shopeeData?.shopId;
    },
  },
};
</script>

<template>
  <BaseBubble data-bubble-name="shopee-card">
    <p v-if="cardTitle" class="font-medium text-center capitalize">
      {{ cardTitle }}
    </p>
    <ChatProductInfos v-if="isChatProductInfos" :data="shopeeData" />
    <AddOnDealItemList v-else-if="isAddOnDealItemList" :data="shopeeData" />
    <Voucher v-else-if="isVoucher" :data="shopeeData" />
    <Activity v-else-if="isTextMessage" :data="shopeeData" />
    <ItemLink v-else-if="isItemLink" :data="shopeeData" />
    <OrderLink v-else-if="isOrderLink" :data="shopeeData" />
    <template v-else>
      {{ t('CONVERSATION.SHOPEE.UNSUPPORTED_CARD') }}
    </template>
  </BaseBubble>
</template>
