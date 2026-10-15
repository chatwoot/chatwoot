<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import BaseBubble from './Base.vue';
import CatalogSheet from 'dashboard/components-next/whatsapp-catalog/CatalogSheet.vue';
import ProductDetail from 'dashboard/components-next/whatsapp-catalog/ProductDetail.vue';
import { useMessageContext } from '../provider.js';

const { content, contentAttributes } = useMessageContext();
const { t } = useI18n();

const detailItem = ref(null);
const listOpen = ref(false);
const openedFromList = ref(false);

const catalog = computed(() => contentAttributes.value?.whatsappCatalog ?? {});
const items = computed(() => catalog.value.items ?? []);
const isCarousel = computed(() => catalog.value.kind === 'carousel');
const isList = computed(() => catalog.value.kind === 'product_list');
const firstItem = computed(() => items.value[0]);
const collectionName = computed(
  () => firstItem.value?.section || t('CATALOG.NO_COLLECTION')
);
const sheetTitle = computed(() =>
  detailItem.value
    ? t('CATALOG.PRODUCT.DETAILS_TITLE')
    : catalog.value.header || collectionName.value
);
const groupedItems = computed(() => {
  const groups = new Map();
  items.value.forEach(item => {
    const title = item.section || '';
    if (!groups.has(title)) groups.set(title, { title, items: [] });
    groups.get(title).items.push(item);
  });
  return [...groups.values()];
});
const showSectionTitles = computed(() => groupedItems.value.length > 1);
const firstImage = item => item?.imageUrls?.[0];

const openFromCard = item => {
  openedFromList.value = false;
  detailItem.value = item;
};

const openFromList = item => {
  openedFromList.value = true;
  detailItem.value = item;
};

// Back arrow, X, handle, Escape and backdrop: a detail opened from the list returns to it.
const onSheetClose = () => {
  if (detailItem.value && openedFromList.value) {
    detailItem.value = null;
    return;
  }
  detailItem.value = null;
  listOpen.value = false;
};
</script>

<template>
  <BaseBubble
    class="p-3 min-w-0 max-w-full"
    :class="isCarousel ? 'sm:max-w-xl' : 'sm:max-w-xs'"
    data-bubble-name="whatsapp-catalog"
  >
    <div class="flex flex-col gap-2 min-w-0">
      <div v-if="catalog.header" class="font-medium break-words">
        {{ catalog.header }}
      </div>
      <button
        v-if="isList"
        type="button"
        class="flex items-center gap-3 p-2 text-start border rounded-lg border-n-weak"
        data-test-id="catalog-list-header"
        @click="listOpen = true"
      >
        <img
          v-if="firstImage(firstItem)"
          :src="firstImage(firstItem)"
          :alt="collectionName"
          loading="lazy"
          class="object-cover rounded-md size-12"
        />
        <span v-else class="rounded-md size-12 bg-n-alpha-2" />
        <span class="flex flex-col min-w-0">
          <span class="font-medium truncate">{{ collectionName }}</span>
          <span class="text-xs text-n-slate-11">
            {{ t('CATALOG.PRODUCT.ITEMS_COUNT', { count: items.length }) }}
          </span>
        </span>
      </button>
      <div v-if="content" class="whitespace-pre-wrap break-words">
        {{ content }}
      </div>

      <div
        v-if="!isList"
        class="flex gap-2 max-w-full pb-1 overflow-x-auto snap-x snap-mandatory"
        data-test-id="catalog-cards"
      >
        <div
          v-for="item in items"
          :key="item.retailerId"
          class="flex flex-col shrink-0 snap-start overflow-hidden border rounded-lg w-60 border-n-weak bg-n-solid-2"
          data-test-id="catalog-card"
        >
          <button
            type="button"
            class="block w-full aspect-square bg-n-alpha-2"
            @click="openFromCard(item)"
          >
            <img
              v-if="firstImage(item)"
              :src="firstImage(item)"
              :alt="item.name"
              loading="lazy"
              class="object-cover w-full aspect-square"
            />
          </button>
          <div class="flex flex-col gap-0.5 p-2 min-w-0">
            <span class="text-sm font-semibold truncate">{{ item.name }}</span>
            <span v-if="item.price" class="text-sm text-n-slate-11">
              {{ item.price }}
            </span>
          </div>
          <button
            type="button"
            class="py-2 text-sm font-medium text-center border-t text-n-brand border-n-weak hover:bg-n-alpha-2"
            @click="openFromCard(item)"
          >
            {{ t('CATALOG.PRODUCT.VIEW') }}
          </button>
        </div>
      </div>

      <button
        v-else
        type="button"
        class="py-2 text-sm font-medium text-center border rounded-lg text-n-brand border-n-weak hover:bg-n-alpha-2"
        @click="listOpen = true"
      >
        {{ t('CATALOG.PRODUCT.VIEW_ITEMS') }}
      </button>

      <div v-if="catalog.footer" class="text-xs break-words text-n-slate-11">
        {{ catalog.footer }}
      </div>
    </div>

    <CatalogSheet
      :show="listOpen || !!detailItem"
      :title="sheetTitle"
      :back-button="!!detailItem && openedFromList"
      size="lg"
      @close="onSheetClose"
    >
      <ProductDetail v-if="detailItem" :item="detailItem" />
      <template v-else>
        <div v-for="group in groupedItems" :key="group.title">
          <div
            v-if="showSectionTitles"
            class="px-3 py-2 text-xs font-medium border-t first:border-t-0 border-n-weak bg-n-alpha-1 text-n-slate-11"
            data-test-id="catalog-list-section"
          >
            {{ group.title || t('CATALOG.NO_COLLECTION') }}
          </div>
          <button
            v-for="item in group.items"
            :key="item.retailerId"
            type="button"
            class="flex items-center w-full gap-3 p-3 text-start border-t border-n-weak first:border-t-0 hover:bg-n-alpha-2"
            data-test-id="catalog-list-row"
            @click="openFromList(item)"
          >
            <img
              v-if="firstImage(item)"
              :src="firstImage(item)"
              :alt="item.name"
              loading="lazy"
              class="object-cover rounded-md size-12"
            />
            <span v-else class="rounded-md size-12 bg-n-alpha-2" />
            <span class="flex flex-col min-w-0">
              <span class="text-sm font-medium truncate">{{ item.name }}</span>
              <span class="text-sm text-n-slate-11">{{ item.price }}</span>
            </span>
          </button>
        </div>
      </template>
    </CatalogSheet>
  </BaseBubble>
</template>
