<template>
  <div
    class="mb-5 dark:bg-slate-900 dark:text-slate-100 text-sm text-slate-700 pt-1 flex items-center gap-4"
  >
    <div class="product-image-container">
      <img
        :src="
          productData.image || '~dashboard/assets/product-image-fallback.svg'
        "
        :alt="productData.title"
        class="product-image"
      />
    </div>
    <div
      class="flex items-center flex-grow truncate text-sm leading-5 font-semibold"
    >
      <img
        class="h-4 mr-2"
        src="~dashboard/assets/images/ChatText.svg"
        alt="Chat Text"
      />
      Need more info? Just ask
    </div>
    <button
      class="items-end flex-shrink-0 p-1 rounded-md hover:bg-slate-200 dark:hover:bg-slate-800"
      @click="$emit('dismiss')"
    >
      <fluent-icon icon="dismiss" size="16" />
    </button>
  </div>
</template>

<script>
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

export default {
  name: 'FooterAskAboutProduct',
  components: { FluentIcon },
  props: {
    productData: {
      type: Object,
      default: () => {},
    },
  },
};
</script>

<style scoped>
.product-image-container {
  position: relative;
  width: 100%;
  overflow: hidden;
  width: 46px;
  height: 46px;
  border-radius: 4px;
}

.product-image {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
</style>
