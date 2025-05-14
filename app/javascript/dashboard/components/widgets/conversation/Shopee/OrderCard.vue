<script setup>
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import Icon from 'next/icon/Icon.vue';
import {
  timeFormatter,
  currencyFormatter,
} from 'next/message/bubbles/Shopee/helper/formatter.js';

const { t } = useI18n();
</script>

<script>
export default {
  name: 'OrderCard',
  components: {
    Icon,
  },
  props: {
    order: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      currentOrder: this.order,
      itemsCollapsed: true,
      items: this.order?.order_items || [],
    };
  },
  computed: {
    displayedItems() {
      if (this.itemsCollapsed) {
        return this.items.slice(0, 2) || [];
      }
      return this.items || [];
    },
    statusText() {
      if (!this.currentOrder.status) {
        return '';
      }
      return this.currentOrder.status.replace(/_/g, ' ').toLowerCase();
    },
    statusColor() {
      const statusColors = {
        UNPAID: 'text-red-700',
        COMPLETED: 'text-green-700',
        READY_TO_SHIP: 'text-woot-700',
        PROCESSED: 'text-woot-700',
        SHIPPED: 'text-woot-700',
        CANCELLED: 'text-red-700',
      };
      return statusColors[this.currentOrder.status] || 'text-orange-700';
    },
    statusIconCode() {
      const statusIcons = {
        UNPAID: 'i-lucide-shopping-bag',
        COMPLETED: 'i-lucide-check-circle',
        READY_TO_SHIP: 'i-inbox-unarchive-line',
        PROCESSED: 'i-inbox-unarchive-line',
        SHIPPED: 'i-lucide-truck',
        CANCELLED: 'i-ri-alert-line',
      };
      return statusIcons[this.currentOrder.status] || 'i-lucide-shopping-cart';
    },
    cancelledByText() {
      switch (this.currentOrder.meta?.cancel_by) {
        case 'buyer':
          return this.$t('CONVERSATION.SHOPEE.ORDER.CANCEL_BY.BUYER');
        case 'seller':
          return this.$t('CONVERSATION.SHOPEE.ORDER.CANCEL_BY.SELLER');
        case 'system':
          return this.$t('CONVERSATION.SHOPEE.ORDER.CANCEL_BY.SYSTEM');
        default:
          return '';
      }
    },
  },
  methods: {
    productLink(itemCode) {
      return `https://shopee.vn/product/${this.currentOrder.shopId}/${itemCode}`;
    },
    onCopyToClipboard(attributeValue) {
      if (!attributeValue) {
        return;
      }
      copyTextToClipboard(attributeValue);
      useAlert(this.$t('GENERAL.COPY_SUCCESSFUL'));
    },
    sendOrder() {
      console.log("Send order action triggered", this.currentOrder.number);
    },
  },
};
</script>

<template>
  <div
    class="header flex flex-col text-xs border-b border-slate-200 dark:border-slate-700 pb-1"
  >
    <div class="flex justify-between items-center">
      <span class="flex-none">
        <Icon class="text-lg" :class="statusColor" :icon="statusIconCode" />
      </span>
      <span class="flex-auto ms-1 font-bold capitalize">
        {{ statusText }}
      </span>
      <span class="flex-none">
        <span v-if="currentOrder.meta?.create_time">
          {{ timeFormatter(currentOrder.meta?.create_time * 1000) }}
        </span>
      </span>
    </div>
    <div class="flex justify-between items-center">
      <span class="flex-none">
        {{ currentOrder.number }}
        <button
          class="p-0"
          @click="() => onCopyToClipboard(currentOrder.number)"
        >
          <Icon icon="i-lucide-copy" class="text-woot-500" />
        </button>
      </span>
      <span>{{ currentOrder.meta?.payment_method }}</span>
    </div>
  </div>
  <div
    class="content flex-none flex-col border-b border-dashed border-slate-200 dark:border-slate-700 py-2"
  >
    <ul class="flex-none">
      <li
        v-for="item in displayedItems"
        :key="item.item_id"
        class="flex flex-row items-center justify-between py-2"
      >
        <div class="flex-none w-10 h-10">
          <a
            :href="productLink(item.itemCode)"
            target="_blank"
            rel="noopener noreferrer"
          >
            <img
              v-if="item.meta?.image_url"
              :src="item.meta?.image_url"
              :alt="item.itemName"
              class="rounded-lg object-cover"
            />
          </a>
        </div>
        <div class="flex-auto flex-col ps-2 overflow-hidden">
          <div class="flex flex-row justify-between">
            <a
              v-tooltip.top="item.itemName"
              :href="productLink(item.itemCode)"
              target="_blank"
              rel="noopener noreferrer"
              class="line-clamp-1 text-xs mb-0 text-slate-900 dark:text-slate-100"
            >
              {{ item.itemName }}
            </a>
            <span class="text-slate-500 dark:text-slate-300 text-xs ms-3">
              {{ `x${item.meta?.quantity || 1}` }}
            </span>
          </div>
          <div class="flex flex-row justify-between">
            <span class="text-slate-500 dark:text-slate-300 text-xs">
              {{ item.itemSku }}
              <button
                class="p-0 text-xs"
                @click="() => onCopyToClipboard(item.itemSku)"
              >
                <Icon icon="i-lucide-copy" class="text-slate-500" />
              </button>
            </span>
            <span
              v-if="item.price === 0"
              class="text-xs text-slate-500 dark:text-slate-300"
            >
              {{ t('CONVERSATION.SHOPEE.ORDER.GIFT') }}
            </span>
            <span v-else class="text-xs text-slate-900 dark:text-slate-100">
              {{ currencyFormatter(item.price) }}
            </span>
          </div>
          <div class="flex flex-row justify-between">
            <span class="text-slate-500 dark:text-slate-300 text-xs">
              {{ item.meta?.model_name }}
            </span>
          </div>
        </div>
      </li>
    </ul>
    <a
      v-if="items.length > 2"
      class="text-xs text-woot-500 hover:underline cursor-pointer flex justify-center mt-2"
      @click="itemsCollapsed = !itemsCollapsed"
    >
      {{
        itemsCollapsed
          ? t('CONVERSATION.SHOPEE.SHOW_MORE')
          : t('CONVERSATION.SHOPEE.SHOW_LESS')
      }}
      <Icon
        :icon="itemsCollapsed ? 'i-lucide-chevron-down' : 'i-lucide-chevron-up'"
        class="text-woot-500 ms-1"
      />
    </a>
  </div>
  <div
    class="summary flex-none flex-col border-b border-dashed border-slate-200 dark:border-slate-700 py-2"
  >
    <div
      v-if="currentOrder.meta?.message_to_seller"
      class="flex flex-row justify-between py-2"
    >
      <span class="text-slate-500 dark:text-slate-300 text-xs">
        <Icon
          icon="i-lucide-message-square"
          class="text-slate-500 dark:text-slate-300"
        />
      </span>
      <span
        class="text-xs text-slate-500 dark:text-slate-300 text-end line-clamp-2"
      >
        {{ currentOrder.meta?.message_to_seller }}
      </span>
    </div>
    <div
      v-if="currentOrder.meta?.note"
      class="flex flex-row justify-between py-2"
    >
      <span class="text-slate-500 dark:text-slate-300 text-xs">
        <Icon
          icon="i-lucide-message-square"
          class="text-slate-500 dark:text-slate-300"
        />
      </span>
      <span
        class="text-xs text-slate-500 dark:text-slate-300 text-end line-clamp-2"
      >
        {{ currentOrder.meta?.note }}
      </span>
    </div>
    <div
      v-if="currentOrder.meta?.pay_time"
      class="flex flex-row justify-between"
    >
      <span class="text-slate-500 dark:text-slate-300 text-xs">
        {{ t('CONVERSATION.SHOPEE.ORDER.PAID_AT') }}
      </span>
      <span class="text-xs text-slate-500 dark:text-slate-300">
        {{ timeFormatter(currentOrder.meta?.pay_time * 1000) }}
      </span>
    </div>
    <div
      v-if="currentOrder.meta?.pickup_done_time"
      class="flex flex-row justify-between"
    >
      <span class="text-slate-500 dark:text-slate-300 text-xs">
        {{ t('CONVERSATION.SHOPEE.ORDER.SHIPPING_AT') }}
      </span>
      <span class="text-xs text-slate-500 dark:text-slate-300">
        {{ timeFormatter(currentOrder.meta?.pickup_done_time * 1000) }}
      </span>
    </div>
    <div
      v-if="currentOrder.meta?.actual_shipping_fee"
      class="flex flex-row justify-between"
    >
      <span class="text-slate-500 dark:text-slate-300 text-xs">
        {{ t('CONVERSATION.SHOPEE.ORDER.SHIPPING_FEE') }}
      </span>
      <span class="text-xs text-slate-500 dark:text-slate-300">
        {{ currencyFormatter(currentOrder.meta?.actual_shipping_fee) }}
      </span>
    </div>
    <div class="flex flex-row justify-between">
      <span class="text-slate-500 dark:text-slate-300 text-xs">
        {{ t('CONVERSATION.SHOPEE.ORDER.TOTAL') }}
      </span>
      <span class="text-xs text-slate-900 dark:text-slate-100">
        {{ currencyFormatter(currentOrder.totalAmount) }}
      </span>
    </div>
    <div
      v-if="currentOrder.meta?.cancel_by"
      class="flex flex-row justify-between"
    >
      <span class="text-slate-500 dark:text-slate-300 text-xs">
        {{ t('CONVERSATION.SHOPEE.ORDER.CANCEL_BY.LABEL') }}
      </span>
      <span class="text-xs text-slate-700 dark:text-slate-300">
        {{ cancelledByText }}
      </span>
    </div>
    <div
      v-if="currentOrder.meta?.cancel_reason"
      class="flex flex-row justify-between"
    >
      <span class="text-slate-500 dark:text-slate-300 text-xs">
        {{ t('CONVERSATION.SHOPEE.ORDER.CANCEL_BY.REASON') }}
      </span>
      <span
        class="text-xs text-orange-700 dark:text-orange-300 line-clamp-2 text-end"
      >
        {{ currentOrder.meta?.cancel_reason }}
      </span>
    </div>
  </div>
  <div class="footer flex flex-none pt-1">
    <div class="flex-1 flex-row justify-between">
      <span
        v-if="currentOrder.meta?.shipping_carrier"
        class="border border-orange-700 text-orange-700 dark:text-slate-300 dark:border-slate-300 rounded-full px-2 py-0.25 text-xs me-1"
      >
        {{ currentOrder.meta?.shipping_carrier }}
      </span>
      <span
        v-if="currentOrder.cod"
        class="border border-iris-700 text-iris-700 dark:text-slate-300 dark:border-slate-300 rounded-full px-2 py-0.25 text-xs me-1"
      >
        {{ t('CONVERSATION.SHOPEE.ORDER.COD') }}
      </span>
    </div>
    <div class="flex-none">
      <button
        class="text-orange-700 border border-orange-700 border-solid rounded-md py-1 px-5 text-xs hover:bg-orange-700 hover:text-white cursor-pointer"
        @click="sendOrder"
      >
        {{ t('CONVERSATION.SHOPEE.SEND') }}
      </button>
    </div>
  </div>
</template>
