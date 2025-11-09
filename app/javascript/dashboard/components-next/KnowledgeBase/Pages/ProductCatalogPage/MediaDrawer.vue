<template>
  <div
    v-if="product"
    class="fixed inset-y-0 right-0 z-50 w-full max-w-2xl bg-n-background border-l border-n-weak shadow-2xl flex flex-col"
  >
    <!-- Header -->
    <div class="flex items-start justify-between p-6 border-b border-n-weak">
      <div class="flex-1 min-w-0">
        <h2 class="text-xl font-medium text-n-slate-12 truncate">
          {{ product.productName }}
        </h2>
      </div>
      <button
        class="flex-shrink-0 ml-4 p-2 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-slate-3 rounded-lg transition-colors"
        @click="emit('close')"
      >
        <i class="i-lucide-x w-5 h-5" />
      </button>
    </div>

    <!-- Product Info -->
    <div class="px-6 py-4 bg-n-slate-2 border-b border-n-weak">
      <div class="grid grid-cols-2 gap-4 text-sm mb-4">
        <div>
          <span class="text-n-slate-11">{{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.PRODUCT_ID') }}:</span>
          <span class="text-n-slate-12 ml-2 font-mono">{{ product.product_id }}</span>
        </div>
        <div>
          <span class="text-n-slate-11">{{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.TYPE') }}:</span>
          <span class="text-n-slate-12 ml-2">{{ product.type }}</span>
        </div>
        <div>
          <span class="text-n-slate-11">{{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.INDUSTRY') }}:</span>
          <span class="text-n-slate-12 ml-2">{{ product.industry }}</span>
        </div>
        <div>
          <span class="text-n-slate-11">{{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.PRICE') }}:</span>
          <span class="text-n-slate-12 ml-2">{{ formatPrice(product.listPrice) }}</span>
        </div>
      </div>

      <!-- Description -->
      <div v-if="product.description" class="mt-4 pt-4 border-t border-n-weak">
        <h3 class="text-sm font-medium text-n-slate-12 mb-2">
          {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.DESCRIPTION') }}
        </h3>
        <div class="max-h-32 overflow-y-auto bg-n-slate-3 rounded-lg p-3">
          <p class="text-sm text-n-slate-11 whitespace-pre-wrap">{{ product.description }}</p>
        </div>
      </div>
    </div>

    <!-- Media List -->
    <div class="flex-1 overflow-y-auto p-6">
      <h3 class="text-sm font-medium text-n-slate-12 mb-4">
        {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.TITLE') }}
      </h3>

      <div v-if="!product.product_media || product.product_media.length === 0" class="flex flex-col items-center justify-center h-full text-center">
        <i class="i-lucide-folder-open w-16 h-16 text-n-slate-9 mb-4" />
        <p class="text-sm text-n-slate-11">
          {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.NO_MEDIA') }}
        </p>
      </div>

      <div v-else class="space-y-3">
        <!-- Images Section -->
        <div v-if="imageMedia.length > 0">
          <h3 class="text-sm font-medium text-n-slate-12 mb-3 flex items-center gap-2">
            <i class="i-lucide-image w-4 h-4" />
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.IMAGES') }} ({{ imageMedia.length }})
          </h3>
          <div class="space-y-2">
            <MediaFileCard
              v-for="media in imageMedia"
              :key="media.id"
              :media="media"
              :is-selected="selectedMedia?.id === media.id"
              @click="handleMediaClick(media)"
              @set-primary="handleSetPrimary"
            />
          </div>
        </div>

        <!-- Videos Section -->
        <div v-if="videoMedia.length > 0" class="pt-4">
          <h3 class="text-sm font-medium text-n-slate-12 mb-3 flex items-center gap-2">
            <i class="i-lucide-video w-4 h-4" />
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.VIDEOS') }} ({{ videoMedia.length }})
          </h3>
          <div class="space-y-2">
            <MediaFileCard
              v-for="media in videoMedia"
              :key="media.id"
              :media="media"
              :is-selected="selectedMedia?.id === media.id"
              @click="handleMediaClick(media)"
              @set-primary="handleSetPrimary"
            />
          </div>
        </div>

        <!-- Documents Section -->
        <div v-if="documentMedia.length > 0" class="pt-4">
          <h3 class="text-sm font-medium text-n-slate-12 mb-3 flex items-center gap-2">
            <i class="i-lucide-file-text w-4 h-4" />
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.DOCUMENTS') }} ({{ documentMedia.length }})
          </h3>
          <div class="space-y-2">
            <MediaFileCard
              v-for="media in documentMedia"
              :key="media.id"
              :media="media"
              :is-selected="selectedMedia?.id === media.id"
              @click="handleMediaClick(media)"
              @set-primary="handleSetPrimary"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Media Detail Modal -->
    <Teleport to="body">
      <MediaDetailModal
        v-if="selectedMedia"
        :media="selectedMedia"
        @close="selectedMedia = null"
      />
    </Teleport>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import ProductMediaAPI from 'dashboard/api/productMedia';
import MediaFileCard from './MediaFileCard.vue';
import MediaDetailModal from './MediaDetailModal.vue';

const props = defineProps({
  product: {
    type: Object,
    default: null
  }
});

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();
const selectedMedia = ref(null);

const imageMedia = computed(() => {
  if (!props.product?.product_media) return [];
  return props.product.product_media.filter(m => m.file_type === 'image');
});

const videoMedia = computed(() => {
  if (!props.product?.product_media) return [];
  return props.product.product_media.filter(m => m.file_type === 'video');
});

const documentMedia = computed(() => {
  if (!props.product?.product_media) return [];
  return props.product.product_media.filter(m => m.file_type === 'document');
});

const formatPrice = (price) => {
  if (!price) return '-';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(price);
};

const handleMediaClick = (media) => {
  selectedMedia.value = media;
};

const handleSetPrimary = async (media) => {
  try {
    await ProductMediaAPI.setPrimary(props.product.id, media.id);

    // Update local state - set this media as primary and remove primary from others of same type
    props.product.product_media.forEach(m => {
      if (m.file_type === media.file_type) {
        m.is_primary = m.id === media.id;
      }
    });

    // Refresh product list to update the UI
    await store.dispatch('productCatalogs/get');

    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.PRIMARY_SET'));
  } catch (error) {
    console.error('Error setting primary:', error);
    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.PRIMARY_ERROR'));
  }
};
</script>
