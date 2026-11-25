<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'next/icon/Icon.vue';
import { useMessageContext } from '../provider.js';
import { formatPrice, hasText, toImageDataUri } from './catalogHelpers';

// A question asked from a WhatsApp catalog quotes the product, not a message: WhatsApp
// shows it above the text with the store icon, the name, the price and a miniature.
const { contentAttributes } = useMessageContext();
const { t, locale } = useI18n();

const product = computed(() => contentAttributes.value?.quotedProduct ?? null);
const thumbnail = computed(() => toImageDataUri(product.value?.thumbnail));
const price = computed(() =>
  formatPrice(
    product.value?.salePrice1000 ?? product.value?.price1000,
    product.value?.currency,
    locale.value
  )
);
// Readable when the quote has something to show: the name, else the description.
const label = computed(() =>
  [product.value?.title, product.value?.description].find(hasText)
);
const readable = computed(() => Boolean(label.value || price.value));
</script>

<template>
  <div
    v-if="product"
    class="flex items-center gap-2 p-2 -mx-1 mb-2 overflow-hidden rounded-lg bg-n-alpha-black1"
    data-quoted-product
  >
    <div class="flex flex-col flex-1 min-w-0 gap-0.5">
      <div class="flex items-center gap-1 text-xs text-n-slate-11">
        <Icon icon="i-lucide-store" class="size-3 shrink-0" />
        <span>{{ t('CONVERSATION.CATALOG.PRODUCT_LABEL') }}</span>
      </div>
      <template v-if="readable">
        <span v-if="label" class="font-medium truncate">{{ label }}</span>
        <span v-if="price" class="text-xs text-n-slate-11">{{ price }}</span>
      </template>
      <span v-else class="text-xs text-n-slate-11">
        {{ t('CONVERSATION.CATALOG.PRODUCT_UNREADABLE') }}
      </span>
    </div>
    <img
      v-if="thumbnail"
      :src="thumbnail"
      alt=""
      class="object-cover rounded-md size-12 shrink-0"
    />
  </div>
</template>
