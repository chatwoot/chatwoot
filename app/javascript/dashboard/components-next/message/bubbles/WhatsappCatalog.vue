<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import BaseBubble from './Base.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import WhatsappCatalogProductDetail from './WhatsappCatalogProductDetail.vue';
import { useMessageContext } from '../provider.js';

const { content, contentAttributes } = useMessageContext();
const { t } = useI18n();

const dialogRef = ref(null);
const detailItem = ref(null);
const showList = ref(false);
const openedFromList = ref(false);

const catalog = computed(() => contentAttributes.value?.whatsappCatalog ?? {});
const items = computed(() => catalog.value.items ?? []);
const isCarousel = computed(() => catalog.value.kind === 'carousel');
const isList = computed(() => catalog.value.kind === 'product_list');
const firstItem = computed(() => items.value[0]);
const collectionName = computed(
  () => firstItem.value?.section || catalog.value.header || ''
);
const dialogTitle = computed(() =>
  detailItem.value
    ? t('CONVERSATION.WHATSAPP_CATALOG.DETAILS')
    : catalog.value.header || firstItem.value?.section || ''
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
const showBack = computed(() => !!detailItem.value && openedFromList.value);

const firstImage = item => item?.imageUrls?.[0];

const openDetail = item => {
  openedFromList.value = false;
  showList.value = false;
  detailItem.value = item;
  dialogRef.value?.open();
};

const openList = () => {
  openedFromList.value = false;
  detailItem.value = null;
  showList.value = true;
  dialogRef.value?.open();
};

const openDetailFromList = item => {
  openedFromList.value = true;
  detailItem.value = item;
};

const backToList = () => {
  openedFromList.value = false;
  detailItem.value = null;
};

const onDialogClose = () => {
  detailItem.value = null;
  showList.value = false;
  openedFromList.value = false;
};
</script>

<template>
  <BaseBubble
    class="p-3 min-w-0 max-w-full"
    :class="isCarousel ? 'sm:max-w-xl' : 'sm:max-w-xs'"
    data-bubble-name="whatsapp-catalog"
  >
    <div class="flex flex-col gap-2 min-w-0 max-w-full">
      <div v-if="catalog.header" class="font-medium break-words">
        {{ catalog.header }}
      </div>
      <div v-if="content" class="whitespace-pre-wrap break-words">
        {{ content }}
      </div>

      <button
        v-if="isList"
        type="button"
        class="flex items-center gap-3 p-2 text-start border rounded-lg border-n-weak"
        data-test-id="catalog-list-header"
        @click="openList"
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
            {{
              t('CONVERSATION.WHATSAPP_CATALOG.ITEMS_COUNT', {
                count: items.length,
              })
            }}
          </span>
        </span>
      </button>

      <div
        v-if="!isList"
        class="flex gap-2 min-w-0 max-w-full pb-1 overflow-x-auto snap-x snap-mandatory"
        data-test-id="catalog-cards"
      >
        <div
          v-for="item in items"
          :key="item.retailerId"
          class="flex flex-col overflow-hidden border rounded-lg shrink-0 snap-start w-60 border-n-weak bg-n-solid-2"
          data-test-id="catalog-card"
        >
          <button
            type="button"
            class="block w-full aspect-square bg-n-alpha-2"
            data-test-id="catalog-card-image"
            @click="openDetail(item)"
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
            data-test-id="catalog-card-view"
            @click="openDetail(item)"
          >
            {{ t('CONVERSATION.WHATSAPP_CATALOG.VIEW') }}
          </button>
        </div>
      </div>

      <button
        v-else
        type="button"
        class="py-2 text-sm font-medium text-center border rounded-lg text-n-brand border-n-weak hover:bg-n-alpha-2"
        data-test-id="catalog-view-items"
        @click="openList"
      >
        {{ t('CONVERSATION.WHATSAPP_CATALOG.VIEW_ITEMS') }}
      </button>

      <div v-if="catalog.footer" class="text-xs break-words text-n-slate-11">
        {{ catalog.footer }}
      </div>
    </div>

    <Dialog
      ref="dialogRef"
      :title="dialogTitle"
      width="md"
      overflow-y-auto
      :show-cancel-button="false"
      :show-confirm-button="false"
      @close="onDialogClose"
    >
      <template v-if="detailItem">
        <NextButton
          v-if="showBack"
          icon="i-lucide-chevron-left"
          slate
          ghost
          sm
          type="button"
          class="self-start"
          :label="t('CONVERSATION.WHATSAPP_CATALOG.BACK')"
          data-test-id="catalog-back"
          @click="backToList"
        />
        <WhatsappCatalogProductDetail :item="detailItem" />
      </template>
      <div v-else-if="showList" class="flex flex-col">
        <div
          v-for="group in groupedItems"
          :key="group.title"
          class="flex flex-col"
          data-test-id="catalog-list-section"
        >
          <div
            v-if="showSectionTitles && group.title"
            class="px-3 pt-3 pb-1 text-xs font-medium text-n-slate-11"
            data-test-id="catalog-section-title"
          >
            {{ group.title }}
          </div>
          <button
            v-for="item in group.items"
            :key="item.retailerId"
            type="button"
            class="flex items-center gap-3 p-3 border-t text-start border-n-weak first:border-t-0 hover:bg-n-alpha-2"
            data-test-id="catalog-list-row"
            @click="openDetailFromList(item)"
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
      </div>
    </Dialog>
  </BaseBubble>
</template>
