<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'next/icon/Icon.vue';
import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from '../provider.js';
import {
  formatPrice,
  hasText,
  toHttpUrl,
  toImageDataUri,
} from './catalogHelpers';

// A product sent from a WhatsApp catalog, drawn the way WhatsApp draws it: the photo on
// top, then the name, the price and the description. The photo is the message's image
// attachment when the connector delivered it, and opens in the gallery like any other
// image. Until then it is the inline thumbnail.
const props = defineProps({
  product: { type: Object, required: true },
  attachment: { type: Object, default: null },
});

const { t, locale } = useI18n();
const { filteredCurrentChatAttachments } = useMessageContext();

const showGallery = ref(false);
// Failures are kept per source: a thumbnail that does not decode must not hide the
// photo that is delivered after it.
const failedSources = ref([]);
const usable = src => Boolean(src) && !failedSources.value.includes(src);
const thumbnail = computed(() => toImageDataUri(props.product.thumbnail));
const photo = computed(() =>
  usable(props.attachment?.dataUrl) ? props.attachment : null
);
const imageSrc = computed(
  () =>
    photo.value?.dataUrl ?? (usable(thumbnail.value) ? thumbnail.value : null)
);
const onImageError = () => {
  failedSources.value = [...failedSources.value, imageSrc.value];
};

const currentPrice = computed(() =>
  formatPrice(
    props.product.salePrice1000 ?? props.product.price1000,
    props.product.currency,
    locale.value
  )
);
const originalPrice = computed(() =>
  typeof props.product.salePrice1000 === 'number'
    ? formatPrice(props.product.price1000, props.product.currency, locale.value)
    : null
);
const productUrl = computed(() => toHttpUrl(props.product.url));
// Every field travels on its own: the card is readable when it has something to show.
const readable = computed(
  () =>
    hasText(props.product.title) ||
    hasText(props.product.description) ||
    Boolean(currentPrice.value)
);
</script>

<template>
  <div class="flex flex-col gap-2" data-catalog-card="product">
    <img
      v-if="imageSrc"
      :src="imageSrc"
      :alt="product.title || ''"
      class="object-cover w-full rounded-lg max-h-72 bg-n-alpha-black1"
      :class="{ 'cursor-pointer skip-context-menu': photo }"
      @click="showGallery = !!photo"
      @error="onImageError"
    />
    <GalleryView
      v-if="showGallery && photo"
      v-model:show="showGallery"
      :attachment="useSnakeCase(photo)"
      :all-attachments="filteredCurrentChatAttachments"
      @close="showGallery = false"
    />
    <div class="flex items-center gap-1 text-xs text-n-slate-11">
      <Icon icon="i-lucide-store" class="size-3 shrink-0" />
      <span>{{ t('CONVERSATION.CATALOG.PRODUCT_LABEL') }}</span>
    </div>
    <template v-if="readable">
      <p v-if="product.title" class="mb-0 font-medium">{{ product.title }}</p>
      <p v-if="currentPrice" class="flex flex-wrap items-baseline gap-2 mb-0">
        <span class="font-medium">{{ currentPrice }}</span>
        <s v-if="originalPrice" class="text-xs text-n-slate-11">
          {{ originalPrice }}
        </s>
      </p>
      <p
        v-if="product.description"
        class="mb-0 text-n-slate-11 whitespace-pre-line"
      >
        {{ product.description }}
      </p>
    </template>
    <p v-else class="mb-0 text-n-slate-11">
      {{ t('CONVERSATION.CATALOG.PRODUCT_UNREADABLE') }}
    </p>
    <a
      v-if="productUrl"
      :href="productUrl"
      target="_blank"
      rel="noopener noreferrer"
      class="flex items-center justify-center gap-1 px-3 py-1.5 text-sm font-medium no-underline rounded-lg bg-n-alpha-black1 hover:bg-n-alpha-black2 text-n-slate-12"
    >
      <Icon icon="i-lucide-external-link" class="size-3 shrink-0" />
      <span>{{ t('CONVERSATION.CATALOG.VIEW') }}</span>
    </a>
  </div>
</template>
