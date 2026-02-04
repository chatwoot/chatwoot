<template>
  <div
    class="bg-n-alpha-3 backdrop-blur-[100px] rounded-xl border border-n-weak overflow-auto max-h-[calc(100vh-320px)]"
    style="scrollbar-width: thin; scrollbar-color: #6b7280 transparent;"
  >
    <div class="min-w-[900px]">
      <!-- Desktop Table Header (hidden on mobile) -->
      <div class="hidden lg:grid grid-cols-12 gap-4 px-6 py-4 bg-n-slate-2 border-b border-n-weak sticky top-0 z-10">
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
        class="relative w-full text-left transition-colors hover:bg-n-slate-2"
        :class="{
          'bg-n-blue-2': selectedProductId === product.id,
          'opacity-50 bg-n-slate-3': !product.is_visible
        }"
        @click="handleProductClick(product)"
      >
        <!-- Product ID Badge (Desktop only) -->
        <div class="hidden lg:block absolute -top-3 left-4 px-3 py-1 bg-n-blue-9 text-white rounded-t-lg text-xs font-mono font-semibold shadow-sm z-10">
          {{ product.product_id }}
        </div>

        <!-- Mobile Card Layout -->
        <div class="lg:hidden p-4">
          <!-- Product ID Badge for Mobile -->
          <div class="flex items-center gap-2 mb-3">
            <span class="px-2 py-1 bg-n-blue-9 text-white rounded text-xs font-mono font-semibold">
              ID: {{ product.product_id }}
            </span>
            <div v-if="!product.is_visible" class="px-2 py-1 bg-n-slate-6 text-n-slate-11 rounded text-xs">
              {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.TABLE.HIDDEN') }}
            </div>
          </div>
          <div class="flex items-start justify-between gap-3">
            <!-- Checkbox + Content -->
            <div class="flex items-start gap-3 flex-1 min-w-0">
              <div class="pt-1" @click.stop>
                <input
                  type="checkbox"
                  :checked="isProductSelected(product.id)"
                  class="w-4 h-4 rounded border-n-slate-7 text-n-blue-9 focus:ring-n-blue-9 focus:ring-offset-0"
                  @change="toggleProductSelection(product.id)"
                />
              </div>
              <div class="flex-1 min-w-0">
                <div class="text-sm font-medium text-n-slate-12 line-clamp-2">
                  {{ product.productName }}
                </div>
                <div class="flex flex-wrap items-center gap-2 mt-2 text-xs text-n-slate-11">
                  <span class="px-2 py-0.5 bg-n-slate-3 rounded">{{ product.type }}</span>
                  <span class="px-2 py-0.5 bg-n-slate-3 rounded">{{ product.industry }}</span>
                </div>
                <div class="flex items-center justify-between mt-3">
                  <span class="text-sm font-semibold text-n-green-11">
                    {{ formatPrice(product.listPrice) }}
                  </span>
                  <div class="flex items-center gap-2">
                    <span v-if="getMediaCount(product, 'IMAGE') > 0" class="inline-flex items-center gap-1 text-xs text-n-slate-11">
                      <i class="i-lucide-image w-3.5 h-3.5" />
                      {{ getMediaCount(product, 'IMAGE') }}
                    </span>
                    <span v-if="getMediaCount(product, 'VIDEO') > 0" class="inline-flex items-center gap-1 text-xs text-n-slate-11">
                      <i class="i-lucide-video w-3.5 h-3.5" />
                      {{ getMediaCount(product, 'VIDEO') }}
                    </span>
                    <span v-if="getMediaCount(product, 'DOCUMENT') > 0" class="inline-flex items-center gap-1 text-xs text-n-slate-11">
                      <i class="i-lucide-file-text w-3.5 h-3.5" />
                      {{ getMediaCount(product, 'DOCUMENT') }}
                    </span>
                  </div>
                </div>
              </div>
            </div>
            <!-- Actions -->
            <div class="flex flex-col gap-1" @click.stop>
              <button
                class="p-2 text-n-slate-11 hover:text-n-blue-11 hover:bg-n-blue-2 rounded-lg transition-colors"
                :title="product.is_visible ? $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.TABLE.HIDE_PRODUCT') : $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.TABLE.SHOW_PRODUCT')"
                @click="emit('toggle-visibility', product)"
              >
                <i v-if="product.is_visible" class="i-lucide-eye w-4 h-4" />
                <i v-else class="i-lucide-eye-off w-4 h-4" />
              </button>
              <button
                class="p-2 text-n-slate-11 hover:text-n-red-11 hover:bg-n-red-2 rounded-lg transition-colors"
                :title="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.TABLE.DELETE_PRODUCT')"
                @click="emit('delete', product)"
              >
                <i class="i-lucide-trash-2 w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        <!-- Desktop Table Layout -->
        <div class="hidden lg:grid grid-cols-12 gap-4 px-6 py-4">
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
          <div class="col-span-2 text-sm font-medium text-n-green-11">
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
          <div class="col-span-2 flex items-center justify-end gap-1" @click.stop>
            <button
              class="p-2 text-n-slate-11 hover:text-n-blue-11 hover:bg-n-blue-2 rounded-lg transition-colors"
              :title="product.is_visible ? $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.TABLE.HIDE_PRODUCT') : $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.TABLE.SHOW_PRODUCT')"
              @click="emit('toggle-visibility', product)"
            >
              <i v-if="product.is_visible" class="i-lucide-eye w-4 h-4" />
              <i v-else class="i-lucide-eye-off w-4 h-4" />
            </button>
            <button
              class="p-2 text-n-slate-11 hover:text-n-red-11 hover:bg-n-red-2 rounded-lg transition-colors"
              :title="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.TABLE.DELETE_PRODUCT')"
              @click="emit('delete', product)"
            >
              <i class="i-lucide-trash-2 w-4 h-4" />
            </button>
          </div>
        </div>
      </button>
    </div>
    </div>
  </div>
</template>

<script setup>
import { useI18n } from 'vue-i18n';

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

const emit = defineEmits(['delete', 'select', 'update:selected-product-ids', 'toggle-visibility']);

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

const { t } = useI18n();

const formatPrice = (price) => {
  if (price === null || price === undefined || price === '') {
    return t('KNOWLEDGE_BASE.PRODUCT_CATALOG.TABLE.PRICE_UNDEFINED');
  }
  const formatted = new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: 'MXN',
    minimumFractionDigits: 2
  }).format(price);
  return `${formatted} MXN`;
};

const getMediaCount = (product, type) => {
  if (!product.product_media) return 0;
  return product.product_media.filter(media => media.file_type === type.toLowerCase()).length;
};
</script>
