<script setup>
import { currencyFormatter } from './helper/formatter.js';
</script>

<script>
export default {
  name: 'ChatProductInfos',
  props: {
    original: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      items: this.original.chatProductInfos || [],
    };
  },
  methods: {
    itemImage(item) {
      return `https://cf.shopee.vn/file/${item.thumbUrl}_tn`;
    },
    currencyFormat(price) {
      return currencyFormatter(price);
    },
  },
};
</script>

<template>
  <ul class="flex flex-col gap-2 list-none shopee-card">
    <li v-for="(item, index) in items" :key="index" class="mb-2">
      <a
        :href="`https://shopee.vn/product/${item.shopId}/${item.itemId}`"
        target="_blank"
        rel="noopener noreferrer"
        class="flex items-center gap-2 w-full"
      >
        <img class="w-10 h-10 rounded-lg" :src="itemImage(item)" />
        <div class="text-xs flex flex-col gap-1 w-full text-ellipsis">
          <p
            class="text-xs mb-0 text-slate-900 dark:text-slate-100 line-clamp-1"
          >
            {{ item.name }}
          </p>
          <p class="flex items-center gap-1 text-xs">
            <span
              class="text-slate-400 dark:text-slate-500 line-through text-end"
            >
              {{ currencyFormat(item.priceBeforeDiscount) }}
            </span>
            <span
              class="flex-1 text-slate-900 dark:text-slate-100 font-semibold text-end me-2"
            >
              {{ currencyFormat(item.price) }}
            </span>
          </p>
        </div>
      </a>
    </li>
  </ul>
</template>

<style lang="scss">
ul.shopee-card {
  @apply p-4 mb-4 rounded-lg bg-white dark:bg-slate-800;

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
