<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
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
const { currentAccount } = useAccount();

const selectedItems = ref([]);
const searchQuery = ref('');

const catalogCurrency = computed(
  () => currentAccount.value?.settings?.catalog_currency
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

const orderItems = computed(() => {
  return selectedItems.value.map(item => {
    const product = products.value.find(p => p.id === item.productId);
    return {
      ...item,
      product,
      totalPrice: product ? product.price * item.quantity : 0,
    };
  });
});

const subtotal = computed(() => {
  return orderItems.value.reduce((sum, item) => sum + item.totalPrice, 0);
});

const total = computed(() => subtotal.value);

const isFormValid = computed(() => {
  return selectedItems.value.length > 0;
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

const addProduct = productId => {
  const existing = selectedItems.value.find(i => i.productId === productId);
  if (existing) {
    existing.quantity += 1;
  } else {
    selectedItems.value.push({ productId, quantity: 1 });
  }
};

const removeProduct = productId => {
  selectedItems.value = selectedItems.value.filter(
    i => i.productId !== productId
  );
};

const updateQuantity = (productId, quantity) => {
  const item = selectedItems.value.find(i => i.productId === productId);
  if (item) {
    if (quantity <= 0) {
      removeProduct(productId);
    } else {
      item.quantity = quantity;
    }
  }
};

const resetForm = () => {
  selectedItems.value = [];
  searchQuery.value = '';
};

const onCancel = () => {
  resetForm();
  emit('cancel');
};

const onSubmit = () => {
  if (!isFormValid.value) return;

  emit('submit', {
    items: selectedItems.value.map(item => ({
      product_id: item.productId,
      quantity: item.quantity,
    })),
  });
};
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="onCancel">
    <div class="flex flex-col h-auto overflow-auto max-h-[80vh]">
      <woot-modal-header
        :header-title="$t('ORDER.TITLE')"
        :header-content="$t('ORDER.DESC')"
      />
      <div class="w-full modal-content pt-2 px-8 pb-8">
        <!-- Search Products -->
        <div class="mb-4">
          <label>
            {{ $t('ORDER.SELECT_PRODUCTS') }}
            <input
              v-model="searchQuery"
              type="text"
              :placeholder="$t('ORDER.SEARCH_PRODUCTS')"
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
            {{ $t('ORDER.LOADING_PRODUCTS') }}
          </div>
          <div
            v-else-if="filteredProducts.length === 0"
            class="text-center py-4 text-n-slate-11"
          >
            {{ $t('ORDER.NO_PRODUCTS') }}
          </div>
          <div v-else class="grid gap-2 max-h-48 overflow-y-auto">
            <div
              v-for="product in filteredProducts"
              :key="product.id"
              class="flex items-center justify-between p-2 border border-n-weak rounded-lg hover:bg-n-alpha-2 cursor-pointer"
              @click="addProduct(product.id)"
            >
              <div class="flex items-center gap-2">
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
              <NextButton icon="i-ph-plus" xs slate faded />
            </div>
          </div>
        </div>

        <!-- Order Items -->
        <div v-if="orderItems.length > 0" class="mb-4">
          <label class="block text-sm font-medium mb-2">
            {{ $t('ORDER.ORDER_ITEMS') }}
          </label>
          <div class="border border-n-weak rounded-lg divide-y divide-n-weak">
            <div
              v-for="item in orderItems"
              :key="item.productId"
              class="flex items-center justify-between p-3"
            >
              <div class="flex-1">
                <div class="font-medium text-sm text-n-slate-12">
                  {{ item.product?.title_en }}
                </div>
                <!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
                <div class="text-xs text-n-slate-11">
                  {{ item.product?.price }} x {{ item.quantity }} =
                  {{ item.totalPrice.toFixed(2) }}
                </div>
                <!-- eslint-enable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
              </div>
              <div class="flex items-center gap-2">
                <input
                  type="number"
                  :value="item.quantity"
                  min="1"
                  class="w-16 text-center border border-n-weak rounded px-2 py-1 text-sm"
                  @input="
                    updateQuantity(
                      item.productId,
                      parseInt($event.target.value) || 0
                    )
                  "
                />
                <NextButton
                  icon="i-ph-trash"
                  xs
                  ruby
                  faded
                  @click="removeProduct(item.productId)"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- Currency Display -->
        <div class="mb-4">
          <label class="block text-sm font-medium mb-1">
            {{ $t('ORDER.CURRENCY') }}
          </label>
          <div
            class="px-3 py-2 text-sm rounded-lg bg-n-alpha-2 text-n-slate-11 w-fit"
          >
            {{ catalogCurrency }}
          </div>
        </div>

        <!-- Totals -->
        <div
          v-if="orderItems.length > 0"
          class="border-t border-n-weak pt-4 mb-4"
        >
          <div
            class="flex justify-between text-lg font-semibold text-n-slate-12"
          >
            <span>{{ $t('ORDER.TOTAL') }}</span>
            <span>{{ total.toFixed(2) }} {{ catalogCurrency }}</span>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <NextButton
            faded
            slate
            type="reset"
            :label="$t('ORDER.CANCEL')"
            :disabled="isSubmitting"
            @click.prevent="onCancel"
          />
          <NextButton
            type="submit"
            :label="$t('ORDER.SUBMIT')"
            :disabled="!isFormValid || isSubmitting"
            :loading="isSubmitting"
            @click.prevent="onSubmit"
          />
        </div>
      </div>
    </div>
  </woot-modal>
</template>
