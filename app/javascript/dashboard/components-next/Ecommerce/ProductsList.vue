<script setup>
import { ref, watch, onMounted } from 'vue';
import { useAlert } from 'dashboard/composables';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ProductItem from './ProductItem.vue';
import EcommerceAPI from 'dashboard/api/integrations/ecommerce';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const products = ref([]);
const loading = ref(true);
const error = ref('');
const searchQuery = ref('');
const searchTimeout = ref(null);

const fetchProducts = async () => {
  try {
    loading.value = true;
    error.value = '';
    const response = await EcommerceAPI.getProducts({
      page: 1,
      per_page: 20,
      search: searchQuery.value || undefined,
    });
    products.value = response.data.products || [];
  } catch (e) {
    error.value =
      e.response?.data?.error || 'ECOMMERCE.PRODUCTS.ERROR';
  } finally {
    loading.value = false;
  }
};

const handleSearch = () => {
  clearTimeout(searchTimeout.value);
  searchTimeout.value = setTimeout(() => {
    fetchProducts();
  }, 500);
};

const handleProductSent = () => {
  useAlert('Product link sent successfully');
};

const handleProductError = () => {
  useAlert('Failed to send product link. Please try again.');
};

watch(searchQuery, () => {
  handleSearch();
});

onMounted(() => {
  fetchProducts();
});
</script>

<template>
  <div class="flex flex-col h-full">
    <div class="p-4 pb-3 border-b border-n-weak">
      <div class="relative">
        <i
          class="i-ph-magnifying-glass absolute left-3 top-1/2 -translate-y-1/2 text-n-slate-10"
        />
        <input
          v-model="searchQuery"
          type="text"
          :placeholder="$t('ECOMMERCE.PRODUCTS.SEARCH_PLACEHOLDER')"
          class="w-full pl-10 pr-4 py-2 text-sm border border-n-weak rounded-md focus:outline-none focus:ring-2 focus:ring-n-brand focus:border-transparent bg-n-solid-1"
        />
      </div>
    </div>

    <div class="flex-1 overflow-y-auto p-4">
      <div v-if="loading" class="flex justify-center items-center p-8">
        <Spinner size="32" class="text-n-brand" />
      </div>
      <div
        v-else-if="error === 'No active e-commerce integration found'"
        class="text-center text-n-slate-11 p-4"
      >
        <i class="i-ph-storefront text-4xl mb-3 text-n-slate-9" />
        <p class="text-sm">
          {{ $t('ECOMMERCE.PRODUCTS.NO_INTEGRATION') }}
        </p>
      </div>
      <div v-else-if="error" class="text-center text-n-ruby-11 p-4">
        <i class="i-ph-warning-circle text-4xl mb-3" />
        <p class="text-sm">{{ $t('ECOMMERCE.PRODUCTS.ERROR') }}</p>
      </div>
      <div
        v-else-if="!products.length"
        class="text-center text-n-slate-11 p-8"
      >
        <i class="i-ph-package text-4xl mb-3 text-n-slate-9" />
        <p class="text-sm">{{ $t('ECOMMERCE.PRODUCTS.NO_PRODUCTS') }}</p>
      </div>
      <div v-else class="flex flex-col gap-3">
        <ProductItem
          v-for="product in products"
          :key="product.id"
          :product="product"
          :conversation-id="conversationId"
          @sent="handleProductSent"
          @error="handleProductError"
        />
      </div>
    </div>
  </div>
</template>
