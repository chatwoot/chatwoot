<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { useDebounceFn, useIntersectionObserver } from '@vueuse/core';

import {
  loadCatalog,
  loadProductsPage,
  peekCatalog,
  peekProductsPage,
} from 'dashboard/helper/whatsappCatalogCache';
import { useAdmin } from 'dashboard/composables/useAdmin';

import Button from 'dashboard/components-next/button/Button.vue';
import CatalogSheet from 'dashboard/components-next/whatsapp-catalog/CatalogSheet.vue';
import ProductDetail from 'dashboard/components-next/whatsapp-catalog/ProductDetail.vue';
import ProductRow from './ProductRow.vue';
import SetupGuide from './SetupGuide.vue';

const props = defineProps({
  show: { type: Boolean, default: false },
  inboxId: { type: Number, default: undefined },
  catalogLink: { type: String, default: '' },
});

const emit = defineEmits(['update:show', 'close', 'insertLink']);

const { isAdmin } = useAdmin();

const SEARCH_DEBOUNCE_MS = 400;

const catalog = ref(null);
const products = ref([]);
const nextCursor = ref(null);
const pageStatus = ref('ok');
const isLoading = ref(false);
const isLoadingPage = ref(false);
const isRefreshing = ref(false);
const loadFailed = ref(false);
const query = ref('');
const collectionId = ref(null);
const detailItem = ref(null);
const listRef = ref(null);
const sentinelRef = ref(null);
let requestId = 0;
let savedScrollTop = 0;

const collections = computed(() => catalog.value?.collections || []);
const guideStatus = computed(() =>
  catalog.value?.status === 'ok' ? pageStatus.value : catalog.value?.status
);
const needsGuide = computed(
  () => !!catalog.value && guideStatus.value !== 'ok'
);

// The list stays mounted (v-show) while the detail replaces it in the same sheet.
const openDetail = product => {
  savedScrollTop = listRef.value?.scrollTop || 0;
  detailItem.value = { ...product, imageUrls: product.image_urls };
};

const closeDetail = async () => {
  detailItem.value = null;
  await nextTick();
  if (listRef.value) listRef.value.scrollTop = savedScrollTop;
};

const applyPage = page => {
  pageStatus.value = page.status;
  products.value = page.products || [];
  nextCursor.value = page.next_cursor ?? null;
};

const loadFirstPage = async ({ force = false } = {}) => {
  requestId += 1;
  const currentRequest = requestId;
  products.value = [];
  nextCursor.value = null;
  pageStatus.value = 'ok';
  loadFailed.value = false;
  isLoadingPage.value = false;
  isLoading.value = true;
  if (listRef.value) listRef.value.scrollTop = 0;
  try {
    const page = await loadProductsPage(props.inboxId, {
      q: query.value,
      collectionId: collectionId.value,
      force,
    });
    if (currentRequest !== requestId) return;
    applyPage(page);
  } catch (error) {
    if (currentRequest !== requestId) return;
    loadFailed.value = true;
  }
  isLoading.value = false;
};

const loadNextPage = async () => {
  if (!nextCursor.value || isLoadingPage.value || isLoading.value) return;
  const currentRequest = requestId;
  isLoadingPage.value = true;
  try {
    const page = await loadProductsPage(props.inboxId, {
      after: nextCursor.value,
      q: query.value,
      collectionId: collectionId.value,
    });
    if (currentRequest !== requestId) return;
    const known = new Set(products.value.map(p => p.retailer_id));
    products.value = [
      ...products.value,
      ...page.products.filter(p => !known.has(p.retailer_id)),
    ];
    nextCursor.value = page.next_cursor ?? null;
  } catch (error) {
    // Keep the cursor: scrolling to the end again retries the page.
  }
  if (currentRequest === requestId) isLoadingPage.value = false;
};

const loadCatalogAndFirstPage = async ({ force = false } = {}) => {
  const catalogRequest = loadCatalog(props.inboxId, { force })
    .then(data => {
      catalog.value = data;
    })
    .catch(() => {
      loadFailed.value = true;
    });
  await Promise.all([catalogRequest, loadFirstPage({ force })]);
};

const refresh = async () => {
  isRefreshing.value = true;
  await loadCatalogAndFirstPage({ force: true });
  isRefreshing.value = false;
};

// Revalidates stale painted data without loading state or scroll changes.
// It yields to any newer request (collection, search, reopen, close).
const refreshInBackground = async () => {
  const currentRequest = requestId;
  try {
    const [freshCatalog, freshPage] = await Promise.all([
      loadCatalog(props.inboxId),
      loadProductsPage(props.inboxId, {}),
    ]);
    if (currentRequest !== requestId || query.value) return;
    if (freshCatalog.status === 'ok' && freshPage.status === 'ok') {
      catalog.value = freshCatalog;
      applyPage(freshPage);
    }
  } catch (error) {
    // Keep showing the cached list.
  }
};

const searchProducts = useDebounceFn(() => loadFirstPage(), SEARCH_DEBOUNCE_MS);

const selectCollection = id => {
  collectionId.value = id;
  loadFirstPage();
};

useIntersectionObserver(
  sentinelRef,
  ([entry]) => {
    if (entry?.isIntersecting) loadNextPage();
  },
  { root: listRef }
);

const reset = () => {
  requestId += 1;
  isLoading.value = false;
  isLoadingPage.value = false;
  catalog.value = null;
  products.value = [];
  loadFailed.value = false;
  query.value = '';
  collectionId.value = null;
  detailItem.value = null;
  // Prefetched data paints at once, with no loading state; stale data is revalidated in the background.
  const cachedCatalog = peekCatalog(props.inboxId);
  const cachedPage = peekProductsPage(props.inboxId);
  if (cachedCatalog && cachedPage) {
    catalog.value = cachedCatalog.data;
    applyPage(cachedPage.data);
    if (cachedCatalog.isStale || cachedPage.isStale) refreshInBackground();
  } else {
    loadCatalogAndFirstPage();
  }
};

const close = () => {
  emit('update:show', false);
  emit('close');
};

// X, handle drag, Escape and backdrop: the detail goes back to the list, otherwise the modal closes.
const onClose = () => (detailItem.value ? closeDetail() : close());

const insertLink = () => {
  emit('insertLink', props.catalogLink);
  close();
};

watch(
  () => props.show,
  value => {
    if (value) reset();
    else requestId += 1;
  },
  { immediate: true }
);
</script>

<template>
  <CatalogSheet
    :show="show"
    :title="
      detailItem ? $t('CATALOG.PRODUCT.DETAILS_TITLE') : $t('CATALOG.TITLE')
    "
    :back-button="!!detailItem"
    size="md"
    @close="onClose"
  >
    <ProductDetail v-if="detailItem" :item="detailItem" />
    <div v-show="!detailItem" class="flex flex-col flex-1 min-h-0">
      <div
        v-if="catalog && !needsGuide"
        class="flex flex-col gap-3 px-4 py-3 border-b border-n-weak shrink-0"
      >
        <div class="flex items-center gap-2">
          <input
            v-model="query"
            type="search"
            class="flex-1 h-10 min-w-0 !mb-0 rounded-lg"
            :placeholder="$t('CATALOG.SEARCH.PLACEHOLDER')"
            data-testid="catalog-search"
            @input="searchProducts"
          />
          <Button
            type="button"
            variant="faded"
            color="slate"
            icon="i-lucide-refresh-cw"
            :aria-label="$t('CATALOG.ACTIONS.REFRESH')"
            :is-loading="isRefreshing"
            :disabled="isRefreshing"
            data-testid="catalog-refresh"
            @click="refresh"
          />
          <Button
            v-if="catalogLink"
            type="button"
            variant="faded"
            color="slate"
            icon="i-lucide-link"
            :aria-label="$t('CATALOG.ACTIONS.INSERT_LINK')"
            data-testid="catalog-insert-link"
            @click="insertLink"
          />
        </div>
        <div
          class="flex gap-2 pb-1 overflow-x-auto"
          data-testid="catalog-chips"
        >
          <button
            type="button"
            class="px-3 py-1 text-xs whitespace-nowrap rounded-full shrink-0 outline outline-1 -outline-offset-1"
            :class="
              collectionId === null
                ? 'outline-n-brand bg-n-alpha-2 text-n-slate-12'
                : 'outline-n-container text-n-slate-11'
            "
            data-testid="catalog-chip-all"
            @click="selectCollection(null)"
          >
            {{ $t('CATALOG.FILTERS.ALL') }}
          </button>
          <button
            v-for="collection in collections"
            :key="collection.id"
            type="button"
            class="px-3 py-1 text-xs whitespace-nowrap rounded-full shrink-0 outline outline-1 -outline-offset-1"
            :class="
              collectionId === collection.id
                ? 'outline-n-brand bg-n-alpha-2 text-n-slate-12'
                : 'outline-n-container text-n-slate-11'
            "
            :data-testid="`catalog-chip-${collection.id}`"
            @click="selectCollection(collection.id)"
          >
            {{ `${collection.name} (${collection.count})` }}
          </button>
        </div>
      </div>

      <div ref="listRef" class="flex-1 min-h-0 p-4 overflow-y-auto">
        <p v-if="isLoading" class="mb-0 text-sm text-n-slate-11">
          {{ $t('CATALOG.STATES.LOADING') }}
        </p>
        <div v-else-if="loadFailed" class="flex flex-col gap-3">
          <p class="mb-0 text-sm text-n-ruby-11">
            {{ $t('CATALOG.STATES.ERROR') }}
          </p>
          <div>
            <Button
              type="button"
              variant="faded"
              color="slate"
              :label="$t('CATALOG.ACTIONS.REFRESH')"
              data-testid="catalog-retry"
              @click="refresh"
            />
          </div>
        </div>
        <SetupGuide
          v-else-if="needsGuide"
          :status="guideStatus"
          :is-admin="isAdmin"
          :inbox-id="inboxId"
          @close="close"
        />
        <p
          v-else-if="!products.length"
          class="mb-0 text-sm text-n-slate-11"
          data-testid="catalog-empty"
        >
          {{
            query || collectionId !== null
              ? $t('CATALOG.SEARCH.NO_RESULTS')
              : $t('CATALOG.STATES.EMPTY')
          }}
        </p>
        <div v-else class="flex flex-col gap-2">
          <ProductRow
            v-for="product in products"
            :key="product.retailer_id"
            :product="product"
            @view="openDetail"
          />
          <p
            v-if="isLoadingPage"
            class="mb-0 text-sm text-center text-n-slate-11"
            data-testid="catalog-loading-more"
          >
            {{ $t('CATALOG.STATES.LOADING') }}
          </p>
          <div ref="sentinelRef" class="h-px" />
        </div>
      </div>
    </div>
  </CatalogSheet>
</template>
