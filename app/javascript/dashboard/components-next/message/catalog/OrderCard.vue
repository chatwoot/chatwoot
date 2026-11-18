<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'next/icon/Icon.vue';
import { formatPrice, toHttpUrl, toImageDataUri } from './catalogHelpers';

// An order placed from a WhatsApp catalog, drawn the way WhatsApp draws it: the
// thumbnail, a cart, "N items", the estimated total and "View order", which lists the
// items. The seller's name (order.title) is not on WhatsApp's card, so it is not here.
const props = defineProps({
  order: { type: Object, required: true },
  note: { type: String, default: '' },
});

const { t, locale } = useI18n();

const expanded = ref(false);
const thumbnail = computed(() => toImageDataUri(props.order.thumbnail));

// WhatsApp counts units, not lines, and the items carry the same count when the
// summary does not.
const units = computed(() => {
  if (typeof props.order.itemCount === 'number') return props.order.itemCount;
  if (!Array.isArray(props.order.items)) return null;
  return props.order.items.reduce(
    (sum, item) => sum + (Number(item?.quantity) || 0),
    0
  );
});
const itemCount = computed(() =>
  units.value === null
    ? null
    : t('CONVERSATION.CATALOG.ITEM_COUNT', { count: units.value })
);
const total = computed(() => {
  const amount = formatPrice(
    props.order.total1000,
    props.order.currency,
    locale.value
  );
  return amount
    ? t('CONVERSATION.CATALOG.ESTIMATED_TOTAL', { total: amount })
    : null;
});

const failedImages = ref(new Set());
const items = computed(() =>
  (Array.isArray(props.order.items) ? props.order.items : [])
    .filter(item => item && typeof item === 'object')
    .map((item, index) => ({
      key: `${item.productId || item.name}-${index}`,
      name: item.name,
      variant: item.variant,
      quantity: item.quantity,
      image: toHttpUrl(item.image),
      price: formatPrice(
        item.price1000,
        item.currency || props.order.currency,
        locale.value
      ),
    }))
);
const showImage = item => item.image && !failedImages.value.has(item.key);
const onImageError = item => {
  failedImages.value = new Set([...failedImages.value, item.key]);
};
</script>

<template>
  <div class="flex flex-col gap-2" data-catalog-card="order">
    <div class="flex items-center gap-3">
      <div
        class="flex items-center justify-center overflow-hidden rounded-lg size-14 shrink-0 bg-n-alpha-black1"
      >
        <img
          v-if="thumbnail"
          :src="thumbnail"
          alt=""
          class="object-cover size-full"
        />
        <Icon
          v-else
          icon="i-lucide-shopping-cart"
          class="size-6 text-n-slate-11"
        />
      </div>
      <div class="flex flex-col min-w-0 gap-0.5">
        <p class="flex items-center gap-1 mb-0 font-medium">
          <Icon icon="i-lucide-shopping-cart" class="size-4 shrink-0" />
          <span>{{ itemCount || t('CONVERSATION.CATALOG.ORDER_LABEL') }}</span>
        </p>
        <p v-if="total" class="mb-0 text-xs text-n-slate-11">{{ total }}</p>
      </div>
    </div>
    <p v-if="note" class="mb-0 whitespace-pre-line">{{ note }}</p>
    <button
      v-if="items.length"
      type="button"
      class="flex items-center justify-center gap-1 px-3 py-1.5 text-sm font-medium rounded-lg bg-n-alpha-black1 hover:bg-n-alpha-black2 text-n-slate-12"
      :aria-expanded="expanded"
      @click="expanded = !expanded"
    >
      {{
        expanded
          ? t('CONVERSATION.CATALOG.HIDE_ORDER')
          : t('CONVERSATION.CATALOG.VIEW_ORDER')
      }}
    </button>
    <ul v-if="expanded" class="flex flex-col gap-2 p-0 m-0 list-none">
      <li
        v-for="item in items"
        :key="item.key"
        class="flex items-center gap-3"
        data-catalog-item
      >
        <div
          class="flex items-center justify-center overflow-hidden rounded-md size-10 shrink-0 bg-n-alpha-black1"
        >
          <img
            v-if="showImage(item)"
            :src="item.image"
            alt=""
            referrerpolicy="no-referrer"
            class="object-cover size-full"
            @error="onImageError(item)"
          />
          <Icon v-else icon="i-lucide-package" class="size-4 text-n-slate-11" />
        </div>
        <div class="flex flex-col min-w-0">
          <span class="font-medium break-words">{{ item.name }}</span>
          <span v-if="item.variant" class="text-xs text-n-slate-11">
            {{ item.variant }}
          </span>
          <span class="text-xs text-n-slate-11">
            {{
              item.price
                ? t('CONVERSATION.CATALOG.QUANTITY_PRICE', {
                    quantity: item.quantity,
                    price: item.price,
                  })
                : t('CONVERSATION.CATALOG.QUANTITY', {
                    quantity: item.quantity,
                  })
            }}
          </span>
        </div>
      </li>
    </ul>
  </div>
</template>
