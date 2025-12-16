<template>
  <CardLayout layout="column">
    <div class="p-4 space-y-3">
      <!-- Header with image -->
      <div class="flex items-start gap-3">
        <div
          v-if="primaryImage"
          class="w-16 h-16 rounded-lg overflow-hidden flex-shrink-0 bg-n-slate-3"
        >
          <img
            :src="primaryImage"
            :alt="product.productName"
            class="w-full h-full object-cover"
          />
        </div>
        <div
          v-else
          class="w-16 h-16 rounded-lg flex items-center justify-center bg-n-slate-3 flex-shrink-0"
        >
          <i class="i-lucide-package w-8 h-8 text-n-slate-9" />
        </div>

        <div class="flex-1 min-w-0">
          <h3 class="text-sm font-semibold text-n-slate-12 truncate">
            {{ product.productName }}
          </h3>
          <p class="text-xs text-n-slate-11 truncate">
            {{ product.industry }} - {{ product.type }}
          </p>
        </div>

        <button
          class="text-n-slate-11 hover:text-n-red-11 transition-colors"
          @click="emit('delete')"
        >
          <i class="i-lucide-trash-2 w-4 h-4" />
        </button>
      </div>

      <!-- Description -->
      <p v-if="product.description" class="text-xs text-n-slate-11 line-clamp-2">
        {{ product.description }}
      </p>

      <!-- Details -->
      <div class="space-y-2">
        <div v-if="product.subcategory" class="flex items-center justify-between text-xs">
          <span class="text-n-slate-11">
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.CARD.SUBCATEGORY') }}:
          </span>
          <span class="font-medium text-n-slate-12">{{ product.subcategory }}</span>
        </div>
      </div>

      <!-- Price -->
      <div v-if="product.listPrice" class="pt-2 border-t border-n-slate-6">
        <div class="flex items-center justify-between">
          <span class="text-xs text-n-slate-11">
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.CARD.PRICE') }}
          </span>
          <span class="text-lg font-semibold text-n-slate-12">
            {{ formatPrice(product.listPrice) }}
          </span>
        </div>
      </div>

      <!-- Payment Options -->
      <div v-if="product.payment_options" class="flex flex-wrap gap-1">
        <span
          v-for="option in parsePaymentOptions(product.payment_options)"
          :key="option"
          class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-n-blue-3 text-n-blue-11"
        >
          {{ option }}
        </span>
      </div>

      <!-- Media Icons -->
      <div class="flex gap-2 text-xs text-n-slate-11">
        <span v-if="hasPhotos" class="flex items-center gap-1">
          <i class="i-lucide-image w-4 h-4" />
          {{ photoCount }}
        </span>
        <span v-if="hasVideos" class="flex items-center gap-1">
          <i class="i-lucide-video w-4 h-4" />
          {{ videoCount }}
        </span>
        <span v-if="hasPDFs" class="flex items-center gap-1">
          <i class="i-lucide-file-text w-4 h-4" />
          {{ pdfCount }}
        </span>
        <span v-if="hasLinks" class="flex items-center gap-1">
          <i class="i-lucide-external-link w-4 h-4" />
          {{ linkCount }}
        </span>
      </div>
    </div>
  </CardLayout>
</template>

<script setup>
import { computed } from 'vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';

const props = defineProps({
  product: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['delete']);

const primaryImage = computed(() => {
  const primaryMedia = props.product.product_media?.find(m => m.is_primary && m.file_type === 'IMAGE');
  if (primaryMedia) return primaryMedia.file_url;

  const firstImage = props.product.product_media?.find(m => m.file_type === 'IMAGE');
  return firstImage?.file_url || null;
});

const formatPrice = (price) => {
  return new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: 'MXN',
  }).format(price);
};

const parsePaymentOptions = options => {
  if (!options) return [];
  return options.split(';').map(o => o.trim());
};

const photoCount = computed(() => {
  return props.product.product_media?.filter(m => m.file_type === 'IMAGE').length || 0;
});

const videoCount = computed(() => {
  return props.product.product_media?.filter(m => m.file_type === 'VIDEO').length || 0;
});

const pdfCount = computed(() => {
  return props.product.product_media?.filter(m => m.file_type === 'DOCUMENT').length || 0;
});

const linkCount = computed(() => {
  if (!props.product.link) return 0;
  return props.product.link.split(';').filter(l => l.trim()).length;
});

const hasPhotos = computed(() => photoCount.value > 0);
const hasVideos = computed(() => videoCount.value > 0);
const hasPDFs = computed(() => pdfCount.value > 0);
const hasLinks = computed(() => linkCount.value > 0);
</script>
