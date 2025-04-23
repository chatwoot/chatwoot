<script>
export default {
  name: 'OrderLink',
  props: {
    data: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      cardData: this.data || {},
    };
  },
};
</script>

<template>
  <div class="shopee-item">
    <a
      :href="`https://shopee.vn/product/${cardData.shopId}/${cardData.orderSn}`"
      target="_blank"
      rel="noopener noreferrer"
    >
      Order Link
    </a>
  </div>
</template>

<style lang="scss">
.shopee-item {
  @apply bg-white p-4 rounded-lg shadow-lg mb-4;
}
</style>
