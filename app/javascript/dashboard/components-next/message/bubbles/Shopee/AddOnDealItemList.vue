<script setup>
import { useI18n } from 'vue-i18n';
import { currencyFormatter } from './helper/formatter.js';

const { t } = useI18n();
</script>

<script>
export default {
  name: 'AddOnDealItemList',
  props: {
    data: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      cardData: this.data,
      items: this.data.addOnDealItemList || [],
    };
  },
  methods: {
    currencyFormat(price) {
      return currencyFormatter(price);
    },
  },
};
</script>

<template>
  <ul class="flex flex-col gap-2 list-none shopee-card">
    <li v-for="(item, index) in items" :key="index">
      <a
        :href="`https://shopee.vn/product/${cardData.shopId}/${item.itemId}`"
        target="_blank"
        rel="noopener noreferrer"
        class="flex items-center gap-2"
      >
        <img class="itemImage" :src="item.image" />
        <div class="itemInfo">
          <p class="itemName">{{ item.name }}</p>
          <p class="itemPrices">
            <span>
              {{ t('CONVERSATION.SHOPEE.STOCK') }}
              {{ item.stock }}
            </span>
            <span class="itemCurrentPrice">
              {{ currencyFormat(item.price) }}
            </span>
            <span class="itemOriginalPrice">
              {{ currencyFormat(item.priceBeforeDiscount) }}
            </span>
          </p>
        </div>
      </a>
    </li>
  </ul>
</template>

<style lang="scss">
ul.shopee-card {
  @apply bg-white p-4 rounded-lg shadow-lg mb-4;
  box-shadow:
    rgba(14, 63, 126, 0.04) 0px 0px 0px 1px,
    rgba(42, 51, 69, 0.04) 0px 1px 1px -0.5px,
    rgba(42, 51, 70, 0.04) 0px 3px 3px -1.5px,
    rgba(42, 51, 70, 0.04) 0px 6px 6px -3px,
    rgba(14, 63, 126, 0.04) 0px 12px 12px -6px,
    rgba(14, 63, 126, 0.04) 0px 24px 24px -12px,
    rgba(0, 0, 0, 0.45) 0px 25px 20px -20px;

  li {
    @apply mb-2;

    a {
      @apply w-full;
    }

    img.itemImage {
      @apply w-16 h-16 rounded-lg;
    }

    .itemInfo {
      @apply flex flex-col gap-1 w-full;
    }

    p {
      @apply text-xs;

      &.itemName {
        @apply text-slate-900 dark:text-slate-900;
      }

      &.itemPrices {
        @apply flex items-center gap-1;

        span.itemCurrentPrice {
          @apply flex-1 text-slate-900 dark:text-slate-900 font-semibold text-end me-2;
        }
        span.itemOriginalPrice {
          @apply text-slate-400 dark:text-slate-400 line-through text-end;
        }
      }
    }
  }
}
</style>
