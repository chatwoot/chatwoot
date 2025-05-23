<script setup>
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { currencyFormatter, timeFormatter } from './helper/formatter.js';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import Icon from 'next/icon/Icon.vue';
const { t } = useI18n();
</script>

<script>
export default {
  name: 'OrderCard',
  components: {
    Icon,
  },
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
  data() {
    return {
      items: this.cached?.items || [],
    };
  },
  computed: {
    statusText() {
      if (!this.cached.status) {
        return '';
      }
      return this.cached.status.replace(/_/g, ' ').toLowerCase();
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
      return statusColors[this.cached.status] || 'text-orange-700';
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
      return statusIcons[this.cached.status] || 'i-lucide-shopping-cart';
    },
  },
  methods: {
    onCopyToClipboard(text) {
      copyTextToClipboard(text);
      useAlert(this.$t('GENERAL.COPY_SUCCESSFUL'));
    },
  },
};
</script>

<template>
  <div class="shopee-order">
    <div v-if="cached.number" class="flex flex-col">
      <p class="flex flex-row justify-between mb-0">
        <span>
          {{ cached.number }}
          <button class="p-0" @click="() => onCopyToClipboard(cached.number)">
            <Icon icon="i-lucide-copy" class="text-woot-500" />
          </button>
        </span>
        <span class="capitalize text-sm flex items-center" :class="statusColor">
          <Icon :icon="statusIconCode" class="text-sm me-1" />
          {{ statusText }}
        </span>
      </p>
      <p class="flex flex-row justify-between mt-0">
        <span class="text-sm text-slate-500">
          {{ cached.meta.paymentMethod }}
        </span>
      </p>
      <div class="flex border-t border-slate-200 border-dashed pt-2">
        <ul class="list-none">
          <li v-for="item in items" :key="item.code" class="mb-1">
            <a
              :href="`https://shopee.vn/product/${item.shopId}/${item.itemCode}`"
              target="_blank"
              rel="noopener noreferrer"
              class="flex items-center gap-2"
            >
              <img
                class="w-10 h-10 rounded-lg"
                :src="`https://cf.shopee.vn/file/${item.meta.imageUrl}`"
                alt="Item Image"
              />

              <div class="w-full">
                <p
                  v-tooltip:top="item.itemName"
                  class="flex flex-row text-sm mb-0"
                >
                  <span class="flex-auto line-clamp-1 text-xs">
                    {{ item.itemName }}
                  </span>
                  <span
                    class="flex-1 ms-3 text-xs text-slate-800 dark:text-slate-200 text-end"
                  >
                    {{ `x${item.meta.quantity}` }}
                  </span>
                </p>
                <p class="flex flex-row justify-between">
                  <span class="text-xs line-clamp-1 text-slate-500">
                    {{ item.itemSku }}
                  </span>
                  <span
                    class="text-xs line-clamp-1 text-slate-800 dark:text-slate-200"
                  >
                    {{ currencyFormatter(item.price) }}
                  </span>
                </p>
              </div>
            </a>
          </li>
        </ul>
      </div>
      <ul
        class="flex flex-col mt-2 pt-2 border-t border-slate-200 border-dashed text-xs"
      >
        <li
          v-if="cached.meta.createTime"
          class="w-full flex flex-row justify-between"
        >
          <span class="flex-1">
            {{ t('CONVERSATION.SHOPEE.ORDER.CHECKOUT_AT') }}
          </span>
          <span class="flex-auto text-end text-slate-500">
            {{ timeFormatter(cached.meta.createTime * 1000) }}
          </span>
        </li>
        <li
          v-if="cached.meta.payTime"
          class="w-full flex flex-row justify-between"
        >
          <span class="flex-1">
            {{ t('CONVERSATION.SHOPEE.ORDER.PAID_AT') }}
          </span>
          <span class="flex-auto text-end text-slate-500">
            {{ timeFormatter(cached.meta.payTime * 1000) }}
          </span>
        </li>
        <li
          v-if="cached.meta.shipByDate"
          class="w-full flex flex-row justify-between"
        >
          <span class="flex-1">
            {{ t('CONVERSATION.SHOPEE.ORDER.SHIPPING_AT') }}
          </span>
          <span class="flex-auto text-end text-slate-500">
            {{ timeFormatter(cached.meta.shipByDate * 1000) }}
          </span>
        </li>
        <li
          v-if="cached.meta.shippingCarrier"
          class="w-full flex flex-row justify-between"
        >
          <span class="flex-1">
            {{ t('CONVERSATION.SHOPEE.ORDER.SHIPPING_SERVICE') }}
          </span>
          <span class="flex-auto text-end">
            {{ cached.meta.shippingCarrier }}
          </span>
        </li>
        <li
          v-if="cached.meta.actualShippingFee"
          class="w-full flex flex-row justify-between"
        >
          <span class="flex-1">
            {{ t('CONVERSATION.SHOPEE.ORDER.SHIPPING_FEE') }}
          </span>
          <span class="flex-auto text-end">
            {{ currencyFormatter(cached.meta.actualShippingFee) }}
          </span>
        </li>
        <li class="w-full flex flex-row justify-between">
          <span class="flex-1">
            {{ t('CONVERSATION.SHOPEE.ORDER.TOTAL') }}
          </span>
          <span class="flex-auto text-end font-semibold">
            {{ currencyFormatter(cached.totalAmount) }}
          </span>
        </li>
      </ul>
    </div>
    <div v-else>
      <span class="text-sm text-slate-500 pe-2 border-e border-slate-500">
        {{ t('CONVERSATION.SHOPEE.ORDER.LABEL') }}
      </span>
      <span class="text-sm text-slate-500 ps-2">
        {{ original.orderSn }}
      </span>
    </div>
  </div>
</template>

<style lang="scss">
.shopee-order {
  @apply p-4 my-4 rounded-lg shadow-lg bg-white dark:bg-slate-800 min-w-[400px];
}
</style>
