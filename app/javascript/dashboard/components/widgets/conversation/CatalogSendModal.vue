<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  isSubmitting: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['cancel', 'update:show', 'submit']);
const store = useStore();
useI18n();

const selectedProductIds = ref([]);
const searchQuery = ref('');

const currentAccount = computed(() => store.getters.getCurrentAccount);
const catalogCurrency = computed(
  () => currentAccount.value?.settings?.catalog_currency || 'SAR'
);

const products = computed(() => store.getters['products/getProducts']);
const isLoadingProducts = computed(
  () => store.getters['products/getUIFlags'].isFetching
);

const filteredProducts = computed(() => {
  if (!searchQuery.value) return products.value;
  const query = searchQuery.value.toLowerCase();
  return products.value.filter(
    p =>
      p.title_en?.toLowerCase().includes(query) ||
      p.title_ar?.toLowerCase().includes(query)
  );
});

const selectedProducts = computed(() => {
  return products.value.filter(p => selectedProductIds.value.includes(p.id));
});

const isFormValid = computed(() => {
  return selectedProductIds.value.length > 0;
});

const localShow = computed({
  get() {
    return props.show;
  },
  set(value) {
    emit('update:show', value);
  },
});

onMounted(() => {
  store.dispatch('products/get');
});

watch(
  () => props.show,
  newVal => {
    if (newVal) {
      store.dispatch('products/get');
    }
  }
);

const toggleProduct = productId => {
  const index = selectedProductIds.value.indexOf(productId);
  if (index === -1) {
    selectedProductIds.value.push(productId);
  } else {
    selectedProductIds.value.splice(index, 1);
  }
};

const isProductSelected = productId => {
  return selectedProductIds.value.includes(productId);
};

const resetForm = () => {
  selectedProductIds.value = [];
  searchQuery.value = '';
};

const onCancel = () => {
  resetForm();
  emit('cancel');
};

const onSubmit = () => {
  if (!isFormValid.value) return;

  emit('submit', {
    productIds: selectedProductIds.value,
  });
};
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="onCancel">
    <div class="flex flex-col h-auto overflow-auto max-h-[80vh]">
      <woot-modal-header
        :header-title="$t('CATALOG_SEND.TITLE')"
        :header-content="$t('CATALOG_SEND.DESC')"
      />
      <div class="w-full modal-content pt-2 px-8 pb-8">
        <!-- Search Products -->
        <div class="mb-4">
          <label>
            {{ $t('CATALOG_SEND.SELECT_PRODUCTS') }}
            <input
              v-model="searchQuery"
              type="text"
              :placeholder="$t('CATALOG_SEND.SEARCH_PRODUCTS')"
              class="mt-1"
            />
          </label>
        </div>

        <!-- Product Selection -->
        <div class="mb-4">
          <div
            v-if="isLoadingProducts"
            class="text-center py-4 text-n-slate-11"
          >
            {{ $t('CATALOG_SEND.LOADING_PRODUCTS') }}
          </div>
          <div
            v-else-if="filteredProducts.length === 0"
            class="text-center py-4 text-n-slate-11"
          >
            {{ $t('CATALOG_SEND.NO_PRODUCTS') }}
          </div>
          <div v-else class="grid gap-2 max-h-48 overflow-y-auto">
            <div
              v-for="product in filteredProducts"
              :key="product.id"
              class="flex items-center justify-between p-2 border rounded-lg cursor-pointer"
              :class="
                isProductSelected(product.id)
                  ? 'border-n-brand bg-n-alpha-2'
                  : 'border-n-weak hover:bg-n-alpha-2'
              "
              @click="toggleProduct(product.id)"
            >
              <div class="flex items-center gap-2">
                <div
                  class="w-5 h-5 rounded border flex items-center justify-center"
                  :class="
                    isProductSelected(product.id)
                      ? 'bg-n-brand border-n-brand'
                      : 'border-n-weak'
                  "
                >
                  <span
                    v-if="isProductSelected(product.id)"
                    class="i-ph-check text-white text-sm"
                  />
                </div>
                <img
                  v-if="product.image_url"
                  :src="product.image_url"
                  class="w-10 h-10 object-cover rounded"
                />
                <div
                  v-else
                  class="w-10 h-10 bg-n-alpha-2 rounded flex items-center justify-center"
                >
                  <span class="i-ph-image text-n-slate-9 text-lg" />
                </div>
                <div>
                  <div class="font-medium text-sm text-n-slate-12">
                    {{ product.title_en }}
                  </div>
                  <div class="text-xs text-n-slate-11">
                    {{ product.price }} {{ catalogCurrency }}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Selected Products Summary -->
        <div v-if="selectedProducts.length > 0" class="mb-4">
          <label class="block text-sm font-medium mb-2">
            {{ $t('CATALOG_SEND.SELECTED_PRODUCTS') }} ({{
              selectedProducts.length
            }})
          </label>
          <div class="flex flex-wrap gap-2">
            <div
              v-for="product in selectedProducts"
              :key="product.id"
              class="flex items-center gap-1 px-2 py-1 bg-n-alpha-2 rounded text-sm"
            >
              <span>{{ product.title_en }}</span>
              <button
                type="button"
                class="text-n-slate-11 hover:text-n-slate-12"
                @click.stop="toggleProduct(product.id)"
              >
                <span class="i-ph-x text-xs" />
              </button>
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <NextButton
            faded
            slate
            type="reset"
            :label="$t('CATALOG_SEND.CANCEL')"
            :disabled="isSubmitting"
            @click.prevent="onCancel"
          />
          <NextButton
            type="submit"
            :label="$t('CATALOG_SEND.SUBMIT')"
            :disabled="!isFormValid || isSubmitting"
            :loading="isSubmitting"
            @click.prevent="onSubmit"
          />
        </div>
      </div>
    </div>
  </woot-modal>
</template>
