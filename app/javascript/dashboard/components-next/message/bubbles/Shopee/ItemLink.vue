<script>
export default {
  name: 'ItemLink',
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
      :href="`https://shopee.vn/product/${cardData.shopId}/${cardData.itemId}`"
      target="_blank"
      rel="noopener noreferrer"
    >
      Item Link
    </a>
  </div>
</template>

<style lang="scss">
.shopee-item {
  @apply bg-white p-4 rounded-lg shadow-lg mb-4;
}
</style>
