<script setup>
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';

defineProps({
  title: {
    type: String,
    default: '',
  },
  subtitle: {
    type: String,
    default: '',
  },
});

// Sample product data for empty state
const sampleProducts = [
  {
    id: 1,
    product_id: 'PROD-001',
    productName: 'Premium Laptop',
    type: 'Electronics',
    subcategory: 'Computers',
    industry: 'Technology',
    listPrice: 1299.99,
    description: 'High-performance laptop with latest processor',
    product_media: [
      { file_type: 'IMAGE' },
      { file_type: 'IMAGE' },
    ]
  },
  {
    id: 2,
    product_id: 'PROD-002',
    productName: 'Wireless Headphones',
    type: 'Electronics',
    subcategory: 'Audio',
    industry: 'Technology',
    listPrice: 199.99,
    description: 'Noise-canceling wireless headphones',
    product_media: [
      { file_type: 'IMAGE' },
      { file_type: 'VIDEO' },
    ]
  },
  {
    id: 3,
    product_id: 'PROD-003',
    productName: 'Smart Watch',
    type: 'Electronics',
    subcategory: 'Wearables',
    industry: 'Technology',
    listPrice: 349.99,
    description: 'Fitness tracking smart watch',
    product_media: [
      { file_type: 'IMAGE' },
      { file_type: 'DOCUMENT' },
    ]
  },
];

const formatPrice = (price) => {
  return new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: 'MXN',
  }).format(price);
};

const getMediaCount = (product, type) => {
  if (!product.product_media) return 0;
  return product.product_media.filter(media => media.file_type === type).length;
};
</script>

<template>
  <EmptyStateLayout :title="title" :subtitle="subtitle">
    <template #empty-state-item>
      <div class="flex flex-col gap-4 p-px opacity-50 pointer-events-none">
        <div
          v-for="product in sampleProducts"
          :key="product.id"
          class="relative bg-n-alpha-3 backdrop-blur-[100px] rounded-xl border border-n-weak overflow-hidden"
        >
          <div class="grid grid-cols-12 gap-4 px-6 py-4">
            <!-- Product ID Badge in upper right -->
            <div class="absolute top-2 right-14 px-2 py-0.5 bg-n-slate-3 rounded text-xs text-n-slate-11 font-mono">
              #{{ product.product_id || product.id }}
            </div>

            <div class="col-span-1 flex items-center">
              <div class="w-4 h-4 rounded border-n-slate-7 bg-n-slate-3"></div>
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
            <div class="col-span-2 flex items-center justify-end">
              <div class="p-2 text-n-slate-9 rounded-lg">
                <i class="i-lucide-trash-2 w-4 h-4" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </EmptyStateLayout>
</template>
