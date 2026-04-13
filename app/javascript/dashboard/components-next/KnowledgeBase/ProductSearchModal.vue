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
  open: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:modelValue', 'update:open', 'preview']);

const { t } = useI18n();

const search = ref('');
const searchDebounceTimer = ref(null);
const debouncedSearch = ref('');

const selectedProducts = computed(() => {
  return props.products.filter(p => props.modelValue.includes(p.id));
});

const filteredProducts = computed(() => {
  if (!debouncedSearch.value) {
    return props.products.slice(0, 100);
  }
  const term = debouncedSearch.value.toLowerCase();
  return props.products
    .filter(p => {
      const productId = p.product_id?.toLowerCase() || '';
      const name = p.productName?.toLowerCase() || '';
      return productId.includes(term) || name.includes(term);
    })
    .slice(0, 100);
});

const isSelected = id => props.modelValue.includes(id);

const toggleProduct = product => {
  const currentIds = [...props.modelValue];
  const index = currentIds.indexOf(product.id);
  if (index > -1) {
    currentIds.splice(index, 1);
  } else {
    currentIds.push(product.id);
  }
  emit('update:modelValue', currentIds);
};

const selectAll = () => {
  const allIds = props.products.map(p => p.id);
  emit('update:modelValue', allIds);
};

const deselectAll = () => {
  emit('update:modelValue', []);
};

const close = () => {
  emit('update:open', false);
};

const handlePreview = product => {
  emit('preview', product);
};

// Debounce search
watch(search, newVal => {
  if (searchDebounceTimer.value) {
    clearTimeout(searchDebounceTimer.value);
  }
  searchDebounceTimer.value = setTimeout(() => {
    debouncedSearch.value = newVal;
  }, 300);
});

// Reset search when modal closes
watch(
  () => props.open,
  val => {
    if (!val) {
      search.value = '';
      debouncedSearch.value = '';
    }
  }
);

onUnmounted(() => {
  if (searchDebounceTimer.value) {
    clearTimeout(searchDebounceTimer.value);
  }
});
</script>

<template>
  <Teleport to="body">
    <Transition name="fade">
      <div
        v-if="open"
        class="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/50"
        @click.self="close"
      >
        <div
          class="w-full max-w-2xl bg-n-background rounded-xl border border-n-weak shadow-xl flex flex-col max-h-[85vh] overflow-hidden"
          @click.stop
        >
          <!-- Header -->
          <div
            class="flex items-center justify-between px-5 py-4 border-b border-n-weak"
          >
            <h3 class="text-base font-medium text-n-slate-12">
              {{ t('KNOWLEDGE_BASE.RESOURCES.PRODUCT_SEARCH.MODAL_TITLE') }}
            </h3>
            <button
              type="button"
              class="p-1 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 rounded-lg"
              @click="close"
            >
              <Icon icon="i-lucide-x" class="w-5 h-5" />
            </button>
          </div>

          <!-- Search bar -->
          <div class="px-5 py-3 border-b border-n-weak">
            <div
              class="flex items-center gap-3 px-3 py-2.5 border border-n-weak rounded-lg bg-n-alpha-1 focus-within:border-n-blue-9 transition-colors"
            >
              <Icon
                icon="i-lucide-search"
                class="w-5 h-5 text-n-slate-10 shrink-0"
              />
              <input
                v-model="search"
                type="text"
                :placeholder="
                  t('KNOWLEDGE_BASE.RESOURCES.PRODUCT_SEARCH.PLACEHOLDER')
                "
                class="flex-1 bg-transparent border-none outline-none text-sm text-n-slate-12 placeholder:text-n-slate-9"
              />
            </div>
            <!-- Quick actions + counter -->
            <div class="flex items-center justify-between mt-2">
              <span class="text-xs text-n-slate-10">
                {{ selectedProducts.length }} / {{ products.length }}
                {{ t('KNOWLEDGE_BASE.RESOURCES.PRODUCT_SEARCH.SELECTED') }}
              </span>
              <div class="flex items-center gap-2">
                <button
                  type="button"
                  class="text-xs text-n-blue-11 hover:text-n-blue-12 font-medium"
                  @click="selectAll"
                >
                  {{
                    t('KNOWLEDGE_BASE.RESOURCES.PRODUCT_SEARCH.SELECT_ALL')
                  }}
                </button>
                <span class="text-n-slate-8">|</span>
                <button
                  type="button"
                  class="text-xs text-n-slate-11 hover:text-n-slate-12 font-medium"
                  @click="deselectAll"
                >
                  {{
                    t('KNOWLEDGE_BASE.RESOURCES.PRODUCT_SEARCH.DESELECT_ALL')
                  }}
                </button>
              </div>
            </div>
          </div>

          <!-- Product list -->
          <div class="flex-1 overflow-y-auto">
            <div
              v-if="filteredProducts.length === 0"
              class="p-8 text-center text-sm text-n-slate-11"
            >
              {{ t('KNOWLEDGE_BASE.RESOURCES.PRODUCT_SEARCH.NO_RESULTS') }}
            </div>

            <div
              v-for="product in filteredProducts"
              :key="product.id"
              class="flex items-center gap-3 px-5 py-3 border-b border-n-weak/50 last:border-b-0 hover:bg-n-alpha-2 transition-colors"
              :class="{ 'bg-n-blue-2': isSelected(product.id) }"
            >
              <!-- Checkbox -->
              <button
                type="button"
                class="shrink-0"
                @click="toggleProduct(product)"
              >
                <div
                  class="w-4 h-4 rounded border flex items-center justify-center transition-colors"
                  :class="
                    isSelected(product.id)
                      ? 'bg-n-blue-9 border-n-blue-9'
                      : 'border-n-slate-8'
                  "
                >
                  <Icon
                    v-if="isSelected(product.id)"
                    icon="i-lucide-check"
                    class="w-3 h-3 text-white"
                  />
                </div>
              </button>

              <!-- Product info (clickable to toggle) -->
              <button
                type="button"
                class="flex-1 min-w-0 text-left"
                @click="toggleProduct(product)"
              >
                <div class="flex items-center gap-2">
                  <span
                    class="font-mono text-xs bg-n-slate-3 px-1.5 py-0.5 rounded text-n-slate-11"
                  >
                    {{ product.product_id }}
                  </span>
                  <span
                    class="text-sm font-medium text-n-slate-12 truncate"
                  >
                    {{ product.productName }}
                  </span>
                </div>
                <div class="text-xs text-n-slate-10 mt-0.5">
                  {{ product.type }}
                  <span v-if="product.industry">
                    · {{ product.industry }}
                  </span>
                </div>
              </button>

              <!-- Eye icon for preview -->
              <button
                type="button"
                class="shrink-0 p-1.5 text-n-slate-10 hover:text-n-blue-11 hover:bg-n-alpha-2 rounded-lg transition-colors"
                :title="
                  t('KNOWLEDGE_BASE.RESOURCES.PRODUCT_SEARCH.VIEW_DETAILS')
                "
                @click.stop="handlePreview(product)"
              >
                <Icon icon="i-lucide-eye" class="w-4 h-4" />
              </button>
            </div>
          </div>

          <!-- Footer -->
          <div
            class="flex items-center justify-end px-5 py-3 border-t border-n-weak"
          >
            <button
              type="button"
              class="px-4 py-2 bg-n-blue-9 hover:bg-n-blue-10 text-white text-sm font-medium rounded-lg transition-colors"
              @click="close"
            >
              {{ t('KNOWLEDGE_BASE.RESOURCES.PRODUCT_SEARCH.DONE') }}
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
