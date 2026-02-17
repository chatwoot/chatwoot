<script setup>
import { ref, computed, watch, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  modelValue: {
    type: Array,
    default: () => [],
  },
  products: {
    type: Array,
    default: () => [],
  },
  placeholder: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();

const search = ref('');
const searchDebounceTimer = ref(null);
const debouncedSearch = ref('');

// Selected products based on modelValue
const selectedProducts = computed(() => {
  return props.products.filter(p => props.modelValue.includes(p.id));
});

// Filter products by search term (ID or name)
const filteredProducts = computed(() => {
  if (!debouncedSearch.value) {
    return props.products.slice(0, 100);
  }
  const term = debouncedSearch.value.toLowerCase();
  return props.products.filter(p => {
    const productId = p.product_id?.toLowerCase() || '';
    const name = p.productName?.toLowerCase() || '';
    return productId.includes(term) || name.includes(term);
  }).slice(0, 100);
});

const isSelected = (id) => props.modelValue.includes(id);

const toggleProduct = (product) => {
  const currentIds = [...props.modelValue];
  const index = currentIds.indexOf(product.id);
  if (index > -1) {
    currentIds.splice(index, 1);
  } else {
    currentIds.push(product.id);
  }
  emit('update:modelValue', currentIds);
};

const removeProduct = (id) => {
  const currentIds = props.modelValue.filter(pid => pid !== id);
  emit('update:modelValue', currentIds);
};

const selectAll = () => {
  const allIds = props.products.map(p => p.id);
  emit('update:modelValue', allIds);
};

const deselectAll = () => {
  emit('update:modelValue', []);
};

// Debounce search
watch(search, (newVal) => {
  if (searchDebounceTimer.value) {
    clearTimeout(searchDebounceTimer.value);
  }
  searchDebounceTimer.value = setTimeout(() => {
    debouncedSearch.value = newVal;
  }, 300);
});

onUnmounted(() => {
  if (searchDebounceTimer.value) {
    clearTimeout(searchDebounceTimer.value);
  }
});
</script>

<template>
  <div class="w-full border border-n-weak rounded-lg overflow-hidden bg-n-alpha-1">
    <!-- Selected product chips -->
    <div
      v-if="selectedProducts.length > 0"
      class="flex flex-wrap gap-2 p-2 border-b border-n-weak bg-n-solid-1 max-h-24 overflow-y-auto"
    >
      <div
        v-for="product in selectedProducts"
        :key="product.id"
        class="flex items-center gap-1 px-2 py-0.5 rounded-md bg-n-blue-3 text-n-blue-11 text-sm"
      >
        <span class="font-mono text-xs bg-n-blue-4 px-1 rounded">{{ product.product_id }}</span>
        <span class="truncate max-w-32">{{ product.productName }}</span>
        <button
          type="button"
          class="hover:bg-n-blue-4 rounded p-0.5"
          @click.stop="removeProduct(product.id)"
        >
          <Icon icon="i-lucide-x" class="w-3 h-3" />
        </button>
      </div>
    </div>

    <!-- Search and quick actions header -->
    <div class="flex items-center gap-2 px-3 py-2 border-b border-n-weak bg-n-alpha-1">
      <!-- Search input -->
      <div class="flex-1 flex items-center gap-2">
        <Icon icon="i-lucide-search" class="w-4 h-4 text-n-slate-10 shrink-0" />
        <input
          v-model="search"
          type="text"
          :placeholder="placeholder || t('KNOWLEDGE_BASE.RESOURCES.PRODUCT_SEARCH.PLACEHOLDER')"
          class="flex-1 bg-transparent border-none outline-none text-sm text-n-slate-12 placeholder:text-n-slate-9"
        />
      </div>

      <!-- Quick actions -->
      <div class="flex items-center gap-2 shrink-0">
        <button
          type="button"
          class="text-xs text-n-blue-11 hover:text-n-blue-12 font-medium whitespace-nowrap"
          @click="selectAll"
        >
          {{ t('KNOWLEDGE_BASE.RESOURCES.PRODUCT_SEARCH.SELECT_ALL') }}
        </button>
        <span class="text-n-slate-8">|</span>
        <button
          type="button"
          class="text-xs text-n-slate-11 hover:text-n-slate-12 font-medium whitespace-nowrap"
          @click="deselectAll"
        >
          {{ t('KNOWLEDGE_BASE.RESOURCES.PRODUCT_SEARCH.DESELECT_ALL') }}
        </button>
      </div>
    </div>

    <!-- Product list (always visible) -->
    <div class="max-h-48 overflow-auto">
      <div v-if="filteredProducts.length === 0" class="p-4 text-center text-sm text-n-slate-11">
        {{ t('KNOWLEDGE_BASE.RESOURCES.PRODUCT_SEARCH.NO_RESULTS') }}
      </div>

      <button
        v-for="product in filteredProducts"
        :key="product.id"
        type="button"
        class="w-full flex items-center gap-3 px-3 py-2 text-left hover:bg-n-alpha-2 transition-colors border-b border-n-weak/50 last:border-b-0"
        :class="{ 'bg-n-blue-2': isSelected(product.id) }"
        @click="toggleProduct(product)"
      >
        <!-- Checkbox indicator -->
        <div
          class="w-4 h-4 rounded border flex items-center justify-center shrink-0 transition-colors"
          :class="isSelected(product.id) ? 'bg-n-blue-9 border-n-blue-9' : 'border-n-slate-8'"
        >
          <Icon
            v-if="isSelected(product.id)"
            icon="i-lucide-check"
            class="w-3 h-3 text-white"
          />
        </div>

        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2">
            <span class="font-mono text-xs bg-n-slate-3 px-1.5 py-0.5 rounded text-n-slate-11">
              {{ product.product_id }}
            </span>
            <span class="text-sm font-medium text-n-slate-12 truncate">
              {{ product.productName }}
            </span>
          </div>
          <div class="text-xs text-n-slate-10 mt-0.5">
            {{ product.type }} <span v-if="product.industry">· {{ product.industry }}</span>
          </div>
        </div>
      </button>
    </div>

    <!-- Footer with count -->
    <div class="px-3 py-1.5 border-t border-n-weak bg-n-alpha-1 text-xs text-n-slate-10">
      {{ selectedProducts.length }} / {{ products.length }} {{ t('KNOWLEDGE_BASE.RESOURCES.PRODUCT_SEARCH.SELECTED') }}
    </div>
  </div>
</template>
