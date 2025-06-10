<script setup>
import BaseBubble from 'next/message/bubbles/Base.vue';
import ChatProductInfos from './Shopee/ChatProductInfos.vue';
import AddOnDealItemList from './Shopee/AddOnDealItemList.vue';
import VoucherCard from './Shopee/VoucherCard.vue';
import Activity from './Shopee/Activity.vue';
import ItemsCard from './Shopee/ItemsCard.vue';
import OrderCard from './Shopee/OrderCard.vue';
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

    return {
      original: contentAttributes.value?.original || {},
      cached: contentAttributes.value?.loadedData || {},
    };
  },
  computed: {
    cardTitle() {
      if (this.original?.name) return this.original?.name;

      const itemLabel = this.original?.itemLabel;
      if (!itemLabel) return '';
      if (itemLabel === 'custom') return '';
      return itemLabel.replace(/_/g, ' ');
    },
    isChatProductInfos() {
      return this.original?.chatProductInfos?.length > 0;
    },
    isAddOnDealItemList() {
      return this.original?.addOnDealItemList?.length > 0;
    },
    isVoucher() {
      return this.original?.voucherCode?.length > 0;
    },
    isTextMessage() {
      return this.original?.text?.length > 0;
    },
    isItems() {
      const itemIds = this.original?.itemIds || this.original?.itemId;
      return !!(itemIds && this.original?.shopId);
    },
    isOrderCard() {
      return this.original?.orderSn && this.original?.shopId;
    },
  },
};
</script>

<template>
  <BaseBubble data-bubble-name="shopee-card">
    <p v-if="cardTitle" class="font-medium text-center capitalize">
      {{ cardTitle }}
    </p>
    <ChatProductInfos
      v-if="isChatProductInfos"
      :original="original"
      :cached="cached"
    />
    <AddOnDealItemList
      v-else-if="isAddOnDealItemList"
      :original="original"
      :cached="cached"
    />
    <VoucherCard v-else-if="isVoucher" :original="original" :cached="cached" />
    <Activity v-else-if="isTextMessage" :original="original" :cached="cached" />
    <ItemsCard v-else-if="isItems" :original="original" :cached="cached" />
    <OrderCard v-else-if="isOrderCard" :original="original" :cached="cached" />
    <template v-else>
      {{ t('CONVERSATION.SHOPEE.UNSUPPORTED_CARD') }}
    </template>
  </BaseBubble>
</template>
