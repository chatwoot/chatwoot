<script setup>
import { ref } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import EcommerceAPI from 'dashboard/api/integrations/ecommerce';

const props = defineProps({
  product: {
    type: Object,
    required: true,
  },
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const emit = defineEmits(['sent']);

const sending = ref(false);

const sendProductLink = async () => {
  sending.value = true;
  try {
    await EcommerceAPI.sendProduct(props.conversationId, props.product.id);
    emit('sent');
  } catch (error) {
    console.error('Failed to send product link:', error);
    emit('error');
  } finally {
    sending.value = false;
  }
};

const formatPrice = price => {
  if (!price) return '-';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(price);
};
</script>

<template>
  <div
    class="flex gap-3 p-3 border border-n-weak rounded-md hover:bg-n-alpha-2 transition-colors"
  >
    <div
      v-if="product.thumbnail_url"
      class="flex-shrink-0 w-16 h-16 bg-n-solid-3 rounded-md overflow-hidden"
    >
      <img
        :src="product.thumbnail_url"
        :alt="product.name"
        class="w-full h-full object-cover"
      />
    </div>
    <div
      v-else
      class="flex-shrink-0 w-16 h-16 bg-n-solid-3 rounded-md flex items-center justify-center"
    >
      <i class="i-ph-package text-2xl text-n-slate-9" />
    </div>

    <div class="flex-1 min-w-0">
      <h3 class="text-sm font-medium text-n-slate-12 truncate mb-1">
        {{ product.name }}
      </h3>
      <div class="flex items-center gap-2 text-xs text-n-slate-11 mb-2">
        <span class="font-semibold">{{ formatPrice(product.price) }}</span>
        <span v-if="product.sku" class="text-n-slate-10">•</span>
        <span v-if="product.sku">{{ product.sku }}</span>
      </div>
      <div class="flex items-center justify-between gap-2">
        <span
          class="text-xs px-2 py-0.5 rounded-full"
          :class="
            product.stock_status === 'in_stock'
              ? 'bg-n-jade-3 text-n-jade-11'
              : 'bg-n-ruby-3 text-n-ruby-11'
          "
        >
          {{
            product.stock_status === 'in_stock'
              ? $t('ECOMMERCE.PRODUCTS.IN_STOCK')
              : $t('ECOMMERCE.PRODUCTS.OUT_OF_STOCK')
          }}
        </span>
        <Button
          :disabled="sending"
          :loading="sending"
          sm
          @click="sendProductLink"
        >
          {{ $t('ECOMMERCE.PRODUCTS.SEND_LINK') }}
        </Button>
      </div>
    </div>
  </div>
</template>
