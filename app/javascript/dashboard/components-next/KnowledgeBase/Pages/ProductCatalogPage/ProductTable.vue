<template>
  <div class="bg-n-alpha-3 backdrop-blur-[100px] rounded-xl border border-n-weak overflow-hidden">
    <!-- Table Header -->
    <div class="grid grid-cols-12 gap-4 px-6 py-4 bg-n-slate-2 border-b border-n-weak">
      <div class="col-span-1"></div>
      <div class="col-span-3 text-xs font-medium text-n-slate-11 uppercase">
        {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.TABLE.PRODUCT') }}
      </div>
      <div class="col-span-2 text-xs font-medium text-n-slate-11 uppercase">
        {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.TABLE.TYPE') }}
      </div>
      <div class="col-span-1 text-xs font-medium text-n-slate-11 uppercase">
        {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.TABLE.INDUSTRY') }}
      </div>
      <div class="col-span-2 text-xs font-medium text-n-slate-11 uppercase">
        {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.TABLE.PRICE') }}
      </div>
      <div class="col-span-1 text-xs font-medium text-n-slate-11 uppercase">
        {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.TABLE.MEDIA') }}
      </div>
      <div class="col-span-2 text-xs font-medium text-n-slate-11 uppercase text-right">
        {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.TABLE.ACTIONS') }}
      </div>
    </div>

    <!-- Table Body -->
    <div class="divide-y divide-n-weak">
      <button
        v-for="product in products"
        :key="product.id"
        class="relative grid grid-cols-12 gap-4 px-6 py-4 hover:bg-n-slate-2 transition-colors w-full text-left"
        :class="{ 'bg-n-blue-2': selectedProductId === product.id }"
        @click="handleProductClick(product)"
      >
        <!-- Product ID Badge as tab on upper left -->
        <div class="absolute -top-3 left-4 px-3 py-1 bg-n-blue-9 text-white rounded-t-lg text-xs font-mono font-semibold shadow-sm">
          {{ product.product_id }}
        </div>

        <div class="col-span-1 flex items-center" @click.stop>
          <input
            type="checkbox"
            :checked="isProductSelected(product.id)"
            class="w-4 h-4 rounded border-n-slate-7 text-n-blue-9 focus:ring-n-blue-9 focus:ring-offset-0"
            @change="toggleProductSelection(product.id)"
          />
        </div>
        <div class="col-span-3">
          <div class="text-sm font-medium text-n-slate-12 truncate">
            {{ product.productName }}
          </div>
          <div v-if="product.description" class="text-xs text-n-slate-11 truncate mt-1">
            {{ product.description }}
          </div>
        </div>
        <div class="col-span-2 text-sm text-n-slate-11 truncate">
          {{ product.type }}
        </div>
        <div class="col-span-1 text-sm text-n-slate-11 truncate">
          {{ product.industry }}
        </div>
        <div class="col-span-2 text-sm text-n-slate-12">
          {{ formatPrice(product.listPrice) }}
        </div>
        <div class="col-span-1 flex items-center gap-1">
          <span v-if="getMediaCount(product, 'IMAGE') > 0" class="inline-flex items-center gap-1 text-xs text-n-slate-11">
            <i class="i-lucide-image w-4 h-4" />
            {{ getMediaCount(product, 'IMAGE') }}
          </span>
          <span v-if="getMediaCount(product, 'VIDEO') > 0" class="inline-flex items-center gap-1 text-xs text-n-slate-11">
            <i class="i-lucide-video w-4 h-4" />
            {{ getMediaCount(product, 'VIDEO') }}
          </span>
          <span v-if="getMediaCount(product, 'DOCUMENT') > 0" class="inline-flex items-center gap-1 text-xs text-n-slate-11">
            <i class="i-lucide-file-text w-4 h-4" />
            {{ getMediaCount(product, 'DOCUMENT') }}
          </span>
        </div>
        <div class="col-span-2 flex items-center justify-end" @click.stop>
          <button
            class="p-2 text-n-slate-11 hover:text-n-red-11 hover:bg-n-red-2 rounded-lg transition-colors"
            @click="emit('delete', product)"
          >
            <i class="i-lucide-trash-2 w-4 h-4" />
          </button>
        </div>
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
  products: {
    type: Array,
    required: true
  },
  selectedProductId: {
    type: Number,
    default: null
  },
  selectedProductIds: {
    type: Array,
    default: () => []
  }
});

const emit = defineEmits(['delete', 'select', 'update:selected-product-ids']);

const handleProductClick = (product) => {
  emit('select', product);
};

const isProductSelected = (productId) => {
  return props.selectedProductIds.includes(productId);
};

const toggleProductSelection = (productId) => {
  const newSelection = isProductSelected(productId)
    ? props.selectedProductIds.filter(id => id !== productId)
    : [...props.selectedProductIds, productId];
  emit('update:selected-product-ids', newSelection);
};

const formatPrice = (price) => {
  if (!price) return '-';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(price);
};

const getMediaCount = (product, type) => {
  if (!product.product_media) return 0;
  return product.product_media.filter(media => media.file_type === type.toLowerCase()).length;
};
</script>
