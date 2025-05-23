<script setup>
import { useI18n } from 'vue-i18n';
import Icon from 'next/icon/Icon.vue';
import { useMapGetter } from 'dashboard/composables/store';
import { currencyFormatter } from 'next/message/bubbles/Shopee/helper/formatter.js';
import LoadingState from 'components/widgets/LoadingState.vue';
import EmptyMessage from 'components/widgets/EmptyMessage.vue';

const { t } = useI18n();
const products = useMapGetter('shopee/searchProducts');
</script>

<script>
export default {
  name: 'Products',
  components: {
    LoadingState,
    EmptyMessage,
    Icon,
  },
  props: {
    currentChat: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      keyword: '',
      selectLimit: 4,
      selectedProductCodes: [],
      uiFlags: useMapGetter('shopee/getUIFlags'),
    };
  },
  computed: {
    limitationTooltip() {
      return this.selectedProductCodes.length >= this.selectLimit
        ? this.$t('CONVERSATION.SHOPEE.PRODUCTS.LIMITATION', {
            limit: this.selectLimit,
          })
        : '';
    },
  },
  mounted() {
    this.searchProducts();
  },
  methods: {
    isDisabled(product) {
      if (this.selectedProductCodes.length < this.selectLimit) return false;
      if (this.selectedProductCodes.includes(product.code)) return false;
      return true;
    },
    productLink(product) {
      return `https://shopee.vn/product/${product.shopId}/${product.code}`;
    },
    productImage(product) {
      if (!product.meta?.image_urls) {
        return null;
      }
      return product.meta?.image_urls[0];
    },
    originalPrice(product) {
      const priceInfo = product.meta?.price_info?.last() || [];
      if (priceInfo?.current_price === priceInfo?.original_price) {
        return null;
      }
      if (priceInfo?.original_price) {
        return currencyFormatter(priceInfo.original_price);
      }
      return null;
    },
    productPrice(product) {
      const priceInfo = product.meta?.price_info?.last() || [];
      if (priceInfo?.current_price) {
        return currencyFormatter(priceInfo.current_price);
      }
      return useI18n().t('CONVERSATION.SHOPEE.PRODUCTS.NO_PRICE');
    },
    isPreOrder(product) {
      const preOrder = product.meta?.pre_order || {};
      if (!preOrder.is_pre_order) return false;
      return preOrder.is_pre_order;
    },
    searchProducts() {
      this.keyword = this.$refs.searchInput.value;
      this.$store.dispatch('shopee/searchProducts', {
        conversationID: this.currentChat.id,
        keyword: this.keyword,
      });
    },
    sendProduct(product) {
      this.$store.dispatch('shopee/sendProductMessage', {
        conversationId: this.currentChat.id,
        productCodes: [product.code],
      });
    },
    sendProducts() {
      this.$store.dispatch('shopee/sendProductMessage', {
        conversationId: this.currentChat.id,
        productCodes: this.selectedProductCodes,
      });
    },
    onCheckboxChange(product) {
      const productCode = product.code;
      const isChecked = this.selectedProductCodes.includes(productCode);
      if (isChecked) {
        this.selectedProductCodes = this.selectedProductCodes.filter(
          code => code !== productCode
        );
      } else {
        this.selectedProductCodes.push(productCode);
      }
    },
    onClearSelectedProducts() {
      this.selectedProductCodes = [];
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-full bg-slate-50 dark:bg-slate-800">
    <div id="search-product">
      <input
        ref="searchInput"
        type="text"
        :placeholder="t('CONVERSATION.SHOPEE.PRODUCTS.SEARCH')"
        @keyup.enter="searchProducts"
      />
      <Icon
        class="absolute top-3 right-5 text-slate-500 dark:text-slate-500"
        icon="i-lucide-search"
      />
    </div>
    <div class="flex-1 overflow-y-auto">
      <LoadingState v-if="uiFlags.isSearchingProducts" />
      <EmptyMessage
        v-else-if="!products.length"
        :message="t('CONVERSATION.SHOPEE.PRODUCTS.EMPTY_MESSAGE')"
      />
      <ul v-else class="p-2">
        <li v-for="product in products" :key="product.code" class="product">
          <div class="flex flex-row pb-2">
            <div class="flex-none w-12 h-12">
              <a
                :href="productLink(product)"
                target="_blank"
                rel="noopener noreferrer"
              >
                <img
                  v-if="productImage(product)"
                  :src="productImage(product)"
                  :alt="product.name"
                  class="rounded-lg object-cover"
                />
              </a>
            </div>
            <div class="flex-auto ps-2 flex-col overflow-hidden">
              <a
                v-tooltip.top="product.name"
                :href="productLink(product)"
                target="_blank"
                rel="noopener noreferrer"
                class="line-clamp-1 w-full text-xs mb-0"
              >
                {{ product.name }}
              </a>
              <div class="flex flex-row">
                <span class="flex-1 text-slate-500 text-xs">
                  {{ product.sku }}
                </span>
                <span
                  v-if="product.meta?.available_stock > 0"
                  class="flex-1 text-slate-500 text-xs"
                >
                  {{ t('CONVERSATION.SHOPEE.PRODUCTS.STOCK') }}
                  {{ product.meta?.available_stock }}
                </span>
              </div>
              <div class="flex-row text-end">
                <span
                  v-if="originalPrice(product)"
                  class="line-through text-slate-500 flex-1 text-xs"
                >
                  {{ originalPrice(product) }}
                </span>
                <span
                  v-if="productPrice(product)"
                  class="font-semibold flex-1 items-center text-orange-700 font-bold ms-2"
                >
                  {{ productPrice(product) }}
                </span>
              </div>
            </div>
          </div>
          <div
            class="flex flex-row border-t border-slate-200 dark:border-slate-600 border-dashed pt-2"
          >
            <div class="flex items-center">
              <input
                v-tooltip.top="limitationTooltip"
                type="checkbox"
                class="flex-none w-5 h-5 cursor-pointer border-current rounded-full me-2"
                :disabled="isDisabled(product)"
                :checked="selectedProductCodes.includes(product.code)"
                @change="onCheckboxChange(product)"
              />
              <small
                class="border bg-white px-2 py-0.5 rounded-full text-xs me-1 border-orange-700 text-orange-700 dark:bg-slate-900 dark:text-slate-300 dark:border-slate-300"
              >
                {{ product.meta?.brand_name }}
              </small>
              <small
                v-if="isPreOrder(product)"
                class="border bg-white px-2 py-0.5 rounded-full text-xs me-1 border-violet-700 text-violet-700 dark:bg-slate-900 dark:text-slate-300 dark:border-slate-300"
              >
                {{ t('CONVERSATION.SHOPEE.PRODUCTS.PRE_ORDER') }}
              </small>
            </div>
            <div class="flex-auto text-end">
              <a
                class="ms-2 text-orange-700 border border-orange-700 rounded-md py-1 px-5 text-xs hover:bg-orange-700 hover:text-white cursor-pointer"
                @click="sendProduct(product)"
              >
                {{ t('CONVERSATION.SHOPEE.SEND') }}
              </a>
            </div>
          </div>
        </li>
      </ul>
    </div>
    <div
      v-if="selectedProductCodes.length"
      class="flex p-3 text-slate-500 items-center border-t border-slate-100 dark:border-slate-800"
    >
      <div class="flex-1 text-xs">
        {{
          t('CONVERSATION.SHOPEE.PRODUCTS.SELECTED_MSG', {
            selected: selectedProductCodes.length,
            limit: selectLimit,
          })
        }}
      </div>
      <div class="flex-1 text-end">
        <button
          class="py-1 px-5 text-xs cursor-pointer"
          @click="onClearSelectedProducts"
        >
          {{ t('CONVERSATION.SHOPEE.PRODUCTS.CLEAR') }}
        </button>
        <button
          class="bg-orange-700 text-white py-1 px-5 cursor-pointer rounded-md"
          @click="sendProducts()"
        >
          {{ t('CONVERSATION.SHOPEE.SEND') }}
        </button>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
#search-product {
  @apply bg-white dark:bg-slate-900 px-2 py-1 relative border-b border-slate-100 dark:border-slate-800;

  input {
    @apply border-none rounded-3xl text-xs mb-0 outline-none pe-9 ps-5 py-0 h-8 dark:bg-slate-800;
  }
}

.product {
  @apply w-full mb-2 relative bg-white dark:bg-slate-900 rounded-md shadow-sm p-2;

  button {
    @apply hidden;
    @apply text-sm text-white bg-orange-600 rounded-md py-1 px-2 hover:bg-orange-700;
  }

  &:hover {
    button {
      @apply block;
    }
    .product-icon {
      @apply hidden;
    }
  }
}
</style>
