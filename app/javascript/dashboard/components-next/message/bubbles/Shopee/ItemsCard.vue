<script setup>
import { currencyFormatter } from './helper/formatter.js';
</script>

<script>
export default {
  name: 'ItemsCard',
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
  methods: {
    itemImage(item) {
      return item.imageUrl || item.image || item.meta?.imageUrls[0];
    },
    currencyFormat(price) {
      return currencyFormatter(price);
    },
  },
};
</script>

<template>
  <template v-if="items.length">
    <ul class="flex flex-col gap-2 list-none shopee-card mt-4">
      <li v-for="(item, index) in items" :key="index">
        <a
          :href="`https://shopee.vn/product/${item.shopId}/${item.code}`"
          target="_blank"
          rel="noopener noreferrer"
          class="flex items-center gap-2"
        >
          <img class="w-10 h-10 rounded-lg" :src="itemImage(item)" />
          <div class="flex flex-col gap-1 w-full text-xs">
            <p
              class="text-xs mb-0 text-slate-900 dark:text-slate-100 line-clamp-1"
            >
              {{ item.name }}
            </p>
            <p class="flex items-center gap-1 text-xs">
              <span
                class="text-slate-400 dark:text-slate-600 line-through text-end"
              >
                {{ currencyFormat(item.meta.priceInfo[0].originalPrice) }}
              </span>
              <span
                class="flex-1 text-slate-900 dark:text-slate-100 font-semibold text-end me-2"
              >
                {{ currencyFormat(item.meta.priceInfo[0].currentPrice) }}
              </span>
            </p>
          </div>
        </a>
      </li>
    </ul>
  </template>
  <template v-else>
    <div class="shopee-item">
      <a
        :href="`https://shopee.vn/product/${original.shopId}/${original.itemId}`"
        target="_blank"
        rel="noopener noreferrer"
      >
        {{ t('CONVERSATION.SHOPEE.PRODUCTS.LABEL') }}
        {{ original.itemId }}
      </a>
    </div>
  </template>
</template>

<style lang="scss">
.shopee-item {
  @apply bg-white p-4 rounded-lg shadow-lg mb-4;
}
</style>
