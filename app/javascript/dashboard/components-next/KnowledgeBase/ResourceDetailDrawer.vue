<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  resource: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['close', 'edit', 'delete', 'toggle-visibility', 'move']);

const { t } = useI18n();
const router = useRouter();

// Accordion state for associations
const associationsOpen = ref(true);
// Accordion state for products (collapsed by default)
const productsOpen = ref(false);

// Pagination for associated products
const currentProductPage = ref(1);
const productsPerPage = 5;

const totalProductPages = computed(() => {
  if (!props.resource?.product_catalogs?.length) return 1;
  return Math.ceil(props.resource.product_catalogs.length / productsPerPage);
});

const paginatedProducts = computed(() => {
  if (!props.resource?.product_catalogs?.length) return [];
  const start = (currentProductPage.value - 1) * productsPerPage;
  return props.resource.product_catalogs.slice(start, start + productsPerPage);
});

// Reset pagination and accordion states when resource changes
watch(() => props.resource?.id, () => {
  currentProductPage.value = 1;
  associationsOpen.value = (props.resource?.product_catalogs?.length || 0) > 0;
  productsOpen.value = false; // Products section starts collapsed
});

// Format file size
const formatFileSize = (bytes) => {
  if (!bytes) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  let unitIndex = 0;
  let size = bytes;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  return `${size.toFixed(1)} ${units[unitIndex]}`;
};

// Format date
const formatDate = (dateStr) => {
  if (!dateStr) return '-';
  const date = new Date(dateStr);
  return date.toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

// Get file type icon
const getFileIcon = (contentType) => {
  if (!contentType) return 'i-lucide-file';
  if (contentType.includes('pdf')) return 'i-lucide-file-text';
  if (contentType.includes('word') || contentType.includes('document')) return 'i-lucide-file-text';
  if (contentType.includes('excel') || contentType.includes('spreadsheet')) return 'i-lucide-file-spreadsheet';
  if (contentType.includes('csv')) return 'i-lucide-file-spreadsheet';
  if (contentType.includes('json')) return 'i-lucide-file-json';
  if (contentType.includes('text')) return 'i-lucide-file-text';
  if (contentType.includes('image')) return 'i-lucide-image';
  if (contentType.includes('audio')) return 'i-lucide-music';
  if (contentType.includes('video')) return 'i-lucide-video';
  return 'i-lucide-file';
};

// Open file in new tab
const openFile = () => {
  if (props.resource?.s3_url) {
    window.open(props.resource.s3_url, '_blank');
  }
};

// Navigate to product detail
const navigateToProduct = (product) => {
  router.push({
    name: 'knowledge_base_product_catalog',
    query: { product_id: product.product_id },
  });
  emit('close');
};

// Handle backdrop click
const handleBackdropClick = () => {
  emit('close');
};

// Handle escape key
const handleKeydown = (event) => {
  if (event.key === 'Escape') {
    emit('close');
  }
};
</script>

<template>
  <Teleport to="body">
    <!-- Backdrop -->
    <Transition name="fade">
      <div
        v-if="resource"
        class="fixed inset-0 z-40 bg-black/50"
        @click="handleBackdropClick"
        @keydown="handleKeydown"
      />
    </Transition>

    <!-- Drawer -->
    <Transition name="slide-right">
      <div
        v-if="resource"
        class="fixed inset-y-0 right-0 z-50 w-full max-w-xl bg-n-background border-l border-n-weak shadow-2xl flex flex-col"
        @keydown="handleKeydown"
      >
        <!-- Header -->
        <div class="flex items-start justify-between p-6 border-b border-n-weak">
          <div class="flex items-start gap-4 min-w-0">
            <div class="flex-shrink-0 w-12 h-12 rounded-lg bg-n-alpha-2 flex items-center justify-center">
              <i :class="[getFileIcon(resource.content_type), 'w-6 h-6 text-n-slate-11']" />
            </div>
            <div class="min-w-0">
              <h2 class="text-xl font-medium text-n-slate-12 truncate">{{ resource.name }}</h2>
              <p class="text-sm text-n-slate-11 truncate">{{ resource.file_name }}</p>
            </div>
          </div>
          <button
            type="button"
            class="p-2 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 rounded-lg transition-colors"
            @click="emit('close')"
          >
            <i class="i-lucide-x w-5 h-5" />
          </button>
        </div>

        <!-- Resource Info -->
        <div class="px-6 py-4 bg-n-slate-2 border-b border-n-weak">
          <div class="grid grid-cols-2 gap-4 text-sm">
            <div>
              <span class="text-n-slate-11">{{ t('KNOWLEDGE_BASE.RESOURCES.DRAWER.FILE_TYPE') }}:</span>
              <span class="ml-2 text-n-slate-12">{{ resource.content_type || '-' }}</span>
            </div>
            <div>
              <span class="text-n-slate-11">{{ t('KNOWLEDGE_BASE.RESOURCES.DRAWER.FILE_SIZE') }}:</span>
              <span class="ml-2 text-n-slate-12">{{ formatFileSize(resource.file_size) }}</span>
            </div>
            <div>
              <span class="text-n-slate-11">{{ t('KNOWLEDGE_BASE.RESOURCES.DRAWER.CREATED_AT') }}:</span>
              <span class="ml-2 text-n-slate-12">{{ formatDate(resource.created_at) }}</span>
            </div>
            <div>
              <span class="text-n-slate-11">{{ t('KNOWLEDGE_BASE.RESOURCES.DRAWER.VISIBILITY') }}:</span>
              <span
                class="ml-2"
                :class="resource.is_visible ? 'text-n-green-11' : 'text-n-amber-11'"
              >
                {{ resource.is_visible ? t('KNOWLEDGE_BASE.RESOURCES.DRAWER.VISIBLE') : t('KNOWLEDGE_BASE.RESOURCES.DRAWER.HIDDEN') }}
              </span>
            </div>
          </div>

          <div v-if="resource.description" class="mt-4 pt-4 border-t border-n-weak">
            <h3 class="text-sm font-medium text-n-slate-12 mb-2">
              {{ t('KNOWLEDGE_BASE.RESOURCES.DRAWER.DESCRIPTION') }}
            </h3>
            <p class="text-sm text-n-slate-11">{{ resource.description }}</p>
          </div>
        </div>

        <!-- Associations Accordion -->
        <div class="flex-1 overflow-y-auto">
          <div class="border-b border-n-weak">
            <!-- Accordion Header -->
            <button
              type="button"
              class="w-full flex items-center justify-between px-6 py-4 hover:bg-n-alpha-1 transition-colors"
              @click="associationsOpen = !associationsOpen"
            >
              <span class="text-sm font-medium text-n-slate-12 flex items-center gap-2">
                <i class="i-lucide-link w-4 h-4 text-n-slate-10" />
                {{ t('KNOWLEDGE_BASE.RESOURCES.FORM.ASSOCIATIONS') }}
                <span class="text-xs text-n-slate-10 font-normal">
                  ({{ resource.product_catalogs?.length || 0 }})
                </span>
              </span>
              <i
                :class="associationsOpen ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
                class="w-4 h-4 text-n-slate-10 transition-transform"
              />
            </button>

            <!-- Accordion Content -->
            <div v-if="associationsOpen" class="px-6 pb-4">
              <!-- Products Section (collapsible) -->
              <div class="border border-n-weak rounded-lg overflow-hidden">
                <!-- Products Header (clickable to toggle) -->
                <button
                  type="button"
                  class="w-full flex items-center justify-between px-3 py-2 bg-n-alpha-1 hover:bg-n-alpha-2 transition-colors"
                  @click="productsOpen = !productsOpen"
                >
                  <span class="flex items-center gap-2">
                    <i class="i-lucide-package w-4 h-4 text-n-slate-10" />
                    <span class="text-xs font-medium text-n-slate-11">
                      {{ t('KNOWLEDGE_BASE.RESOURCES.FORM.PRODUCT_CATALOGS') }}
                    </span>
                    <span class="text-xs text-n-slate-10">
                      ({{ resource.product_catalogs?.length || 0 }})
                    </span>
                  </span>
                  <i
                    :class="productsOpen ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
                    class="w-4 h-4 text-n-slate-10 transition-transform"
                  />
                </button>

                <!-- Products Content (collapsible) -->
                <div v-if="productsOpen" class="border-t border-n-weak">
                  <!-- Empty state -->
                  <div
                    v-if="!resource.product_catalogs?.length"
                    class="flex flex-col items-center justify-center py-6 text-center"
                  >
                    <i class="i-lucide-package-open w-10 h-10 text-n-slate-9 mb-2" />
                    <p class="text-sm text-n-slate-11">
                      {{ t('KNOWLEDGE_BASE.RESOURCES.DRAWER.NO_PRODUCTS') }}
                    </p>
                  </div>

                  <!-- Products list -->
                  <div v-else>
                    <button
                      v-for="product in paginatedProducts"
                      :key="product.id"
                      type="button"
                      class="w-full flex items-center gap-3 px-3 py-2.5 hover:bg-n-alpha-2 transition-colors text-left border-b border-n-weak/50 last:border-b-0"
                      @click="navigateToProduct(product)"
                    >
                      <div class="flex-1 min-w-0">
                        <div class="flex items-center gap-2">
                          <span class="font-mono text-xs bg-n-blue-3 text-n-blue-11 px-1.5 py-0.5 rounded">
                            {{ product.product_id }}
                          </span>
                          <span class="font-medium text-sm text-n-slate-12 truncate">
                            {{ product.productName }}
                          </span>
                        </div>
                        <div class="text-xs text-n-slate-10 mt-0.5">
                          {{ product.type }} <span v-if="product.industry">· {{ product.industry }}</span>
                        </div>
                      </div>
                      <i class="i-lucide-external-link w-4 h-4 text-n-slate-10 flex-shrink-0" />
                    </button>

                    <!-- Pagination -->
                    <div
                      v-if="totalProductPages > 1"
                      class="flex items-center justify-center gap-2 py-2 border-t border-n-weak"
                    >
                      <button
                        type="button"
                        class="p-1 rounded hover:bg-n-alpha-2 disabled:opacity-50 disabled:cursor-not-allowed"
                        :disabled="currentProductPage === 1"
                        @click="currentProductPage--"
                      >
                        <i class="i-lucide-chevron-left w-4 h-4" />
                      </button>
                      <span class="text-xs text-n-slate-11">
                        {{ currentProductPage }} / {{ totalProductPages }}
                      </span>
                      <button
                        type="button"
                        class="p-1 rounded hover:bg-n-alpha-2 disabled:opacity-50 disabled:cursor-not-allowed"
                        :disabled="currentProductPage === totalProductPages"
                        @click="currentProductPage++"
                      >
                        <i class="i-lucide-chevron-right w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Actions Footer -->
        <div class="flex items-center gap-3 p-4 border-t border-n-weak bg-n-solid-1">
          <Button
            icon="i-lucide-external-link"
            :label="t('KNOWLEDGE_BASE.RESOURCES.DRAWER.OPEN_FILE')"
            @click="openFile"
          />
          <Button
            variant="faded"
            color="slate"
            icon="i-lucide-folder-input"
            :label="t('KNOWLEDGE_BASE.RESOURCES.DRAWER.MOVE')"
            @click="emit('move', resource)"
          />
          <Button
            variant="faded"
            color="slate"
            :icon="resource.is_visible ? 'i-lucide-eye' : 'i-lucide-eye-off'"
            @click="emit('toggle-visibility', resource)"
          />
          <Button
            variant="faded"
            color="slate"
            icon="i-lucide-pencil"
            :label="t('KNOWLEDGE_BASE.RESOURCES.DRAWER.EDIT')"
            @click="emit('edit', resource)"
          />
          <Button
            variant="faded"
            color="ruby"
            icon="i-lucide-trash"
            :label="t('KNOWLEDGE_BASE.RESOURCES.DRAWER.DELETE')"
            @click="emit('delete', resource)"
          />
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

.slide-right-enter-active,
.slide-right-leave-active {
  transition: transform 0.3s ease;
}

.slide-right-enter-from,
.slide-right-leave-to {
  transform: translateX(100%);
}
</style>
