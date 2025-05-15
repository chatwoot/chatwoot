<template>
  <div class="carousel-container">
    <!-- <h1 v-if="message">{{ message }}</h1> -->
    <div class="carousel">
      <div v-for="(item, index) in items" :key="index" class="carousel-item">
        <div class="product-card" @click="onProductClick(item)">
          <div class="product-image-container">
            <img
              :src="
                item.image || '~dashboard/assets/product-image-fallback.svg'
              "
              :alt="item.title"
              class="product-image"
            />
            <div
              style="backdrop-filter: blur(4px)"
              class="absolute bottom-0 w-full h-8 py-1 px-3 flex bg-[#D9D9D9B2]"
              :class="{
                'justify-end': !item.showMoreVariantsButton,
                'justify-between': item.showMoreVariantsButton,
              }"
            >
              <div
                v-if="item.showMoreVariantsButton"
                class="flex justify-center items-center rounded-2xl px-3 py-1.5 bg-white font-medium text-xs leading-4 shadow-[0px_1.25px_0px_0px_#0000000d] hover:shadow-md hover:scale-105 transition-all duration-200 cursor-pointer"
                @click.stop="onViewMoreVariants(item)"
              >
                More variants
              </div>
              <div class="flex gap-3">
                <!-- <button
                  class="tooltip-container bg-white rounded-full h-6 w-6 flex justify-center items-center cursor-pointer relative"
                  @click.stop="() => {}"
                >
                  <div
                    class="tooltip absolute right-0 bottom-full mb-1 py-0.5 px-2 bg-black-900 text-white text-xs rounded-md opacity-0 pointer-events-none whitespace-nowrap transition-opacity duration-200"
                  >
                    Show similar products
                  </div>
                  <img
                    class="h-4"
                    src="~dashboard/assets/images/StackPlus.svg"
                    alt="Stack Plus"
                  />
                </button> -->
                <button
                  class="tooltip-container bg-white rounded-full h-6 w-6 flex justify-center items-center cursor-pointer relative"
                  @click.stop="askMoreAboutProduct(item)"
                >
                  <div
                    class="tooltip absolute right-0 bottom-full mb-1 py-0.5 px-2 bg-black-900 text-white text-xs rounded-md opacity-0 pointer-events-none whitespace-nowrap transition-opacity duration-200"
                  >
                    Ask about this product
                  </div>
                  <img
                    class="h-4"
                    src="~dashboard/assets/images/ChatText.svg"
                    alt="Chat Text"
                  />
                </button>
              </div>
            </div>
          </div>
          <div class="product-details">
            <h3 class="product-title">{{ item.title }}</h3>
            <p class="product-price">
              {{
                item.shopUrl === 'hlfashions-78ce.myshopify.com'
                  ? '£'
                  : item.currency
              }}
              {{ item.price }}
            </p>
          </div>
          <div class="product-actions">
            <div
              v-if="!isProductInSelectedProducts(item)"
              class="w-full flex relative"
            >
              <div
                v-if="isCheckoutLoading"
                style="backdrop-filter: blur(2px)"
                class="absolute w-full h-full flex justify-center items-center"
              >
                <spinner size="medium" :color-scheme="'primary'" />
              </div>
              <button
                class="w-[50%] p-3 border-r border-[#E6E6E6] text-[13px] font-bold text-[#2E52E5] leading-5"
                :disabled="isCheckoutLoading"
                @click.stop="
                  updateSelectedProducts(
                    item.variant_id,
                    1,
                    item.currency,
                    item.price,
                    item.shopUrl,
                    $event
                  )
                "
              >
                Add to cart
              </button>
              <button
                class="w-[50%] p-3 text-[13px] font-bold text-[#2E52E5] leading-5"
                :disabled="isCheckoutLoading"
                @click.stop="onBuyNow(item, $event)"
              >
                Buy now
              </button>
            </div>
            <div v-else class="w-full flex relative">
              <div
                v-if="isCheckoutLoading"
                style="backdrop-filter: blur(2px)"
                class="absolute w-full h-full flex justify-center items-center"
              >
                <spinner size="medium" :color-scheme="'primary'" />
              </div>
              <div
                class="flex p-3 gap-3 items-center border-r border-solid border-[#E6E6E6]"
              >
                <button
                  class="quantity-button"
                  :disabled="isCheckoutLoading"
                  @click.stop="decreaseQuantity(item.variant_id, $event)"
                >
                  -
                </button>
                <span
                  class="flex justify-center items-center w-11 py-0.5 rounded-2xl border border-solid text-[13px] leading-4 font-semibold border-[#2E52E5] text-[#2E52E5]"
                >
                  {{ getQuantity(item.variant_id) }}
                </span>
                <button
                  :disabled="isCheckoutLoading"
                  class="quantity-button"
                  @click.stop="increaseQuantity(item.variant_id, $event)"
                >
                  +
                </button>
              </div>
              <button
                class="w-[50%] p-3 text-[13px] font-bold text-[#2E52E5] leading-5"
                @click.stop="openCheckoutPage(selectedProducts)"
              >
                Go to cart
              </button>
            </div>
          </div>
          <!-- <div
            v-if="item.showMoreVariantsButton"
            class="more-variants"
            @click="onViewMoreVariants(item)"
          >
            More variants
            <div class="more-variants-icon">
              <fluent-icon icon="chevron-right" size="14" />
            </div>
            <div
              v-if="item.showMoreVariantsButton"
              class="more-variants"
              @click="onViewMoreVariants(item)"
            >
              More variants
              <div class="more-variants-icon">
                <fluent-icon icon="chevron-right" size="14" />
              </div>
            </div>
          </div> -->
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapActions } from 'vuex';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import ContactsAPI from '../../widget/api/contacts';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    Spinner,
  },
  props: {
    message: {
      type: [String, Object],
      default: () => {},
    },
    selectedProducts: {
      type: Array,
      default: () => [],
    },
    updateSelectedProducts: {
      type: Function,
      default: () => {},
    },
    items: {
      type: Array,
      default: () => [],
    },
    messageId: { type: Number, default: null },
  },
  data() {
    return {
      isCheckoutLoading: true,
    };
  },
  methods: {
    ...mapActions('conversation', ['sendMessage']),
    onProductClick(item) {
      let productUrl = `https://${item.shopUrl}/products/${item.productHandle}`;
      if (item.variant_id) {
        productUrl += `?variant=${item.variant_id}`;
      }
      window.open(productUrl, '_blank');
    },
    async openCheckoutPage(selectedProducts) {
      this.isCheckoutLoading = true;
      const shopUrl = selectedProducts[0].shopUrl;
      const lineItems = selectedProducts.map(product => ({
        variant_id: product.id,
        quantity: product.quantity,
        price: product.price,
        currency: product.currency,
      }));
      try {
        const data = await ContactsAPI.getCheckoutRedirectURL(
          shopUrl,
          lineItems
        );
        if (data.data?.checkoutUrl) {
          window.open(data.data?.checkoutUrl, '_blank');
        }
      } catch (error) {
        // eslint-disable-next-line no-console
        console.log('error', error);
      } finally {
        this.isCheckoutLoading = false;
      }
    },
    isProductInSelectedProducts(product) {
      return this.selectedProducts.some(
        selectedProduct => selectedProduct.id === product.variant_id
      );
    },
    async increaseQuantity(productId, event) {
      event.stopPropagation();
      const product = this.selectedProducts.find(
        selectedProduct => selectedProduct.id === productId
      );
      await fetch(`https://${product.shopUrl}/cart.js`)
        .then(res => res.json())
        .catch(() => {});
      await fetch(`https://${product.shopUrl}/cart.js`)
        .then(res => res.json())
        .catch(() => {});
      this.updateSelectedProducts(
        product.id,
        product.quantity + 1,
        product.currency,
        product.price,
        product.shopUrl,
        event
      );
    },
    onViewMoreVariants(item) {
      this.sendMessage({
        content: 'More variants',
        productId: item.id,
        replyTo: this.message.id,
      });
    },
    onBuyNow(item, event) {
      event.stopPropagation();
      const selectedProduct = [
        {
          id: item.variant_id,
          quantity: 1,
          currency: item.currency,
          price: item.price,
          shopUrl: item.shopUrl,
        },
      ];
      this.openCheckoutPage(selectedProduct);
    },
    decreaseQuantity(productId, event) {
      event.stopPropagation();
      event.stopPropagation();
      const product = this.selectedProducts.find(
        selectedProduct => selectedProduct.id === productId
      );
      this.updateSelectedProducts(
        product.id,
        product.quantity - 1,
        product.currency,
        product.price,
        product.shopUrl,
        event
      );
    },
    getQuantity(productId) {
      const product = this.selectedProducts.find(
        selectedProduct => selectedProduct.id === productId
      );
      return product ? +product.quantity : 0;
    },
    onAddToCart(item) {
      // eslint-disable-next-line no-alert
      alert(`Added ${item.title} to cart.`);
    },
    askMoreAboutProduct(productData) {
      emitter.emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, {
        content:
          productData?.productHandle ?? this.message ?? 'Product carousel',
        id: this.messageId,
      });
      emitter.emit(BUS_EVENTS.ASK_FOR_PRODUCT, productData);
    },
  },
};
</script>

<style scoped>
h1 {
  font-size: 12px;
  font-weight: 500;
  line-height: 11px;
  color: #8c8c8c;
  margin-bottom: 10px;
}
.carousel-container {
  width: 600px;
  position: relative;
  overflow-x: hidden;
}

.carousel {
  @apply py-3 pl-3 bg-[#F2F2F2] rounded-lg;
  display: flex;
  transition: transform 0.5s ease-in-out;
  overflow-x: auto;
  width: 60%;
  gap: 10px;
  scrollbar-width: none;
  scroll-behavior: smooth;
}

.carousel::-webkit-scrollbar {
  display: none;
}

.carousel-item {
  flex: 0 0 auto;
  min-width: 150px;
  max-width: 248px;
  width: 100%;
}

.product-card {
  display: flex;
  flex-direction: column;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid #f0f0f0;
  height: 100%;
  transition:
    transform 0.2s,
    box-shadow 0.2s;
}

.product-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.product-image-container {
  position: relative;
  padding-top: 75%; /* 4:3 Aspect Ratio */
  width: 100%;
  overflow: hidden;
  width: 248px;
  height: 248px;
}

.product-image {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.product-details {
  min-height: 70px;
  padding: 12px;
  flex-grow: 1;
}

.product-title {
  font-size: 14px;
  font-weight: 700;
  color: #1a1a1a;
  margin: 0;
  line-height: 20px;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.product-price {
  font-size: 14px;
  color: #1a1a1a;
  line-height: 20px;
  font-weight: 400;
  margin: 4px 0 0;
}

.product-actions {
  display: flex;
  border-top: 1px solid #e6e6e6;
}

.buy-now-button:hover {
  background: #1a84e8;
}

.quantity-actions {
  display: flex;
  justify-content: space-between;
  gap: 8px;
}

.quantity-container {
  display: flex;
  flex: 1;
}

.quantity-button {
  width: 20px;
  height: 20px;
  border-radius: 100%;
  background: #2e52e5;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: white;
  padding-bottom: 3px;
}

.quantity-button:hover {
  background: #4c6ff7;
}

.more-variants {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 8px;
  font-size: 12px;
  color: #8c8c8c;
  gap: 4px;
  border-top: 1px solid #f0f0f0;
}

.more-variants-icon {
  display: flex;
  align-items: center;
  transform: rotate(90deg);
}

@media (max-width: 576px) {
  .carousel-item {
    min-width: 130px;
  }
}

.tooltip-container:hover .tooltip {
  opacity: 1;
}
</style>
