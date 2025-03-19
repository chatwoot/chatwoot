<template>
  <div class="carousel-container">
    <h1>{{ message }}</h1>
    <div
      class="carousel"
      :style="{ transform: `translateX(-${currentSlide * 100}%)` }"
    >
      <div v-for="(item, index) in items" :key="index" class="carousel-item">
        <div class="card" @click="onProductClick(item)">
          <img
            :src="item.image || '~dashboard/assets/product-image-fallback.svg'"
            alt="item.title"
            class="card-image"
          />
          <h3 class="card-title">{{ item.title }}</h3>
          <p class="card-price">₹{{ item.price }}</p>
          <div class="card-buttons">
            <button
              v-if="!isProductInSelectedProducts(item)"
              class="add-to-cart-button"
              @click="
                updateSelectedProducts(
                  item.id,
                  1,
                  item.currency,
                  item.price,
                  item.shopUrl,
                  $event
                )
              "
            >
              <img
                width="17"
                height="17"
                src="~dashboard/assets/add-to-cart.svg"
                alt="Add to Cart"
              />
            </button>
            <div v-else class="quantity-container">
              <button
                class="quantity-button"
                @click="decreaseQuantity(item.id, $event)"
              >
                -
              </button>
              <span class="quantity-text">{{ getQuantity(item.id) }}</span>
              <button
                class="quantity-button"
                @click="increaseQuantity(item.id, $event)"
              >
                +
              </button>
            </div>
            <button
              v-if="!isProductInSelectedProducts(item)"
              class="buy-now-button"
              @click="onBuyNow(item, $event)"
            >
              Buy now
            </button>
            <button
              v-else
              class="clear-button"
              @click="
                updateSelectedProducts(
                  item.id,
                  0,
                  item.currency,
                  item.price,
                  item.shopUrl,
                  $event
                )
              "
            >
              <img
                width="17"
                height="17"
                src="~dashboard/assets/delete.svg"
                alt="Clear"
              />
            </button>
          </div>
        </div>
        <div class="more-variants">
          More variants
          <div class="more-variants-icon">
            <fluent-icon icon="chevron-right" size="14" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';

export default {
  components: {
    FluentIcon,
  },
  props: {
    message: {
      type: Object,
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
    openCheckoutPage: {
      type: Function,
      default: () => {},
    },
    items: {
      type: Array,
      default: () => [],
    },
  },
  methods: {
    onProductClick(item) {
      window.open(
        `https://${item.shopUrl}/products/${item.productHandle}`,
        '_blank'
      );
    },
    isProductInSelectedProducts(product) {
      return this.selectedProducts.some(
        selectedProduct => selectedProduct.id === product.id
      );
    },
    increaseQuantity(productId, event) {
      const product = this.selectedProducts.find(
        selectedProduct => selectedProduct.id === productId
      );
      this.updateSelectedProducts(
        productId,
        product.quantity + 1,
        product.currency,
        product.price,
        product.shopUrl,
        event
      );
    },
    onBuyNow(item, event) {
      event.stopPropagation();
      const selectedProduct = [
        {
          id: item.id,
          quantity: 1,
          currency: item.currency,
          price: item.price,
          shopUrl: item.shopUrl,
        },
      ];
      this.openCheckoutPage(selectedProduct);
    },
    decreaseQuantity(productId, event) {
      const product = this.selectedProducts.find(
        selectedProduct => selectedProduct.id === productId
      );
      this.updateSelectedProducts(
        productId,
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
      alert(`Added ${item.title} to cart.`);
    },
  },
};
</script>

<style scoped>
h1 {
  font-size: 13px;
  font-weight: 500;
  line-height: 11px;
  color: #8c8c8c;
  margin-bottom: 10px;
}
.carousel-container {
  width: 500px;
  position: relative;
  overflow-x: hidden;
  margin-top: 20px;
}

.carousel {
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
  width: 150px;
}

.card {
  border: 1px solid #f0f0f0;
  padding: 10px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  width: 150px;
}

.card-image {
  width: 100%;
  height: 108px;
  border-radius: 1px;
}

.card-title {
  font-size: 11px;
  color: #1c1c1c;
  font-weight: 600;
}

.card-price {
  font-size: 11px;
  color: #1c1c1c;
  margin-bottom: 15px;
}

.quantity-container {
  display: flex;
  width: 70%;
  align-items: center;
}

.quantity-button {
  background: #f0f0f0;
  width: 28px;
  height: 28px;
  border-radius: 4px;
  display: grid;
  place-items: center;
  width: 33%;
}

.quantity-text {
  font-size: 12px;
  font-weight: 500;
  color: #fff;
  width: 34%;
  background: #1f93ff;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.clear-button {
  background: #f0f0f0;
  width: 20%;
  height: 28px;
  border-radius: 4px;
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  display: grid;
  place-items: center;
}

.card-buttons {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}

.add-to-cart-button {
  background: #f0f0f0;
  width: 28px;
  height: 28px;
  border-radius: 4px;
  display: grid;
  place-items: center;
}

.buy-now-button {
  background: #1f93ff;
  width: 85px;
  height: 28px;
  border-radius: 4px;
  color: #fff;
  font-size: 12px;
  font-weight: 500;
}

.more-variants {
  display: flex;
  width: 150px;
  justify-content: center;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  font-weight: 500;
  color: #8c8c8c;
  cursor: pointer;
  margin-top: 5px;
}

.more-variants-icon {
  display: grid;
  place-items: center;
  transform: rotate(90deg);
}

.carousel-controls {
  display: flex;
  justify-content: center;
  gap: 10px;
  margin-top: 10px;
}

.carousel-controls button {
  padding: 10px 15px;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  background-color: #007bff;
  color: #fff;
  font-size: 14px;
}

.carousel-controls button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}
</style>
