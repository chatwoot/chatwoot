<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDebounceFn, useIntersectionObserver } from '@vueuse/core';

import whatsappCatalogMessages from 'dashboard/api/whatsappCatalogMessages';
import {
  loadCatalog,
  loadProductsPage,
  peekCatalog,
  peekProductsPage,
} from 'dashboard/helper/whatsappCatalogCache';
import { useAdmin } from 'dashboard/composables/useAdmin';
import {
  CATALOG_MAX_SELECTION,
  CATALOG_KINDS,
  CATALOG_ERRORS,
  CATALOG_ITEM_LIMITS,
  CATALOG_TEXT_LIMITS,
  validateCatalogForm,
  getAvailableFormats,
} from 'dashboard/helper/whatsappCatalog';

import Button from 'dashboard/components-next/button/Button.vue';
import CatalogSheet from 'dashboard/components-next/whatsapp-catalog/CatalogSheet.vue';
import ProductDetail from 'dashboard/components-next/whatsapp-catalog/ProductDetail.vue';
import ProductRow from './ProductRow.vue';
import SetupGuide from './SetupGuide.vue';

const props = defineProps({
  show: { type: Boolean, default: false },
  inboxId: { type: Number, default: undefined },
  conversationId: { type: Number, default: undefined },
  initialBody: { type: String, default: '' },
  catalogLink: { type: String, default: '' },
});

const emit = defineEmits(['update:show', 'sent', 'close', 'insertLink']);

const { t } = useI18n();
const { isAdmin } = useAdmin();

const SEARCH_DEBOUNCE_MS = 400;

const FIELDS_BY_KIND = {
  [CATALOG_KINDS.CAROUSEL]: [{ name: 'body', required: true }],
  [CATALOG_KINDS.PRODUCT]: [
    { name: 'body', required: false },
    { name: 'footer', required: false },
  ],
  [CATALOG_KINDS.PRODUCT_LIST]: [
    { name: 'header', required: true },
    { name: 'body', required: true },
    { name: 'footer', required: false },
  ],
};

const view = ref('products');
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
const selectionMode = ref(false);
// Full product objects by retailer_id, so the selection survives pages, searches and collections.
const selected = ref({});
const detailItem = ref(null);
const listRef = ref(null);
const sentinelRef = ref(null);
let requestId = 0;
let savedScrollTop = 0;
const kind = ref(null);
const form = ref({ header: '', body: '', footer: '' });
const submitted = ref(false);
const isSending = ref(false);
const sendError = ref('');

const collections = computed(() => catalog.value?.collections || []);
const guideStatus = computed(() =>
  catalog.value?.status === 'ok' ? pageStatus.value : catalog.value?.status
);
const needsGuide = computed(
  () => !!catalog.value && guideStatus.value !== 'ok'
);
const selectedProducts = computed(() => Object.values(selected.value));
const selectedCount = computed(() => selectedProducts.value.length);
const atMax = computed(() => selectedCount.value >= CATALOG_MAX_SELECTION);
const formats = computed(() => getAvailableFormats(selectedCount.value));

const fields = computed(() => FIELDS_BY_KIND[kind.value] || []);
const hasField = name => fields.value.some(f => f.name === name);

// First collection (in catalog order) that holds the product.
const sectionFor = product => {
  const collection = collections.value.find(c =>
    (product.collection_ids || []).includes(c.id)
  );
  return collection?.name || t('CATALOG.NO_COLLECTION');
};

const items = computed(() =>
  selectedProducts.value.map(product => ({
    retailer_id: product.retailer_id,
    name: product.name,
    price: product.price,
    description: product.description,
    url: product.url,
    section:
      kind.value === CATALOG_KINDS.PRODUCT_LIST ? sectionFor(product) : null,
    image_urls: product.image_urls,
  }))
);

const validationPayload = computed(() => ({
  kind: kind.value,
  items: items.value,
  body: form.value.body,
  header: hasField('header') ? form.value.header : '',
  footer: hasField('footer') ? form.value.footer : '',
}));
const errors = computed(() =>
  kind.value ? validateCatalogForm(validationPayload.value) : {}
);
const limits = computed(() => CATALOG_ITEM_LIMITS[kind.value] || {});

const formatTexts = computed(() => ({
  [CATALOG_KINDS.CAROUSEL]: {
    name: t('CATALOG.FORMATS.CAROUSEL.NAME'),
    rule: t('CATALOG.FORMATS.CAROUSEL.RULE'),
  },
  [CATALOG_KINDS.PRODUCT]: {
    name: t('CATALOG.FORMATS.PRODUCT.NAME'),
    rule: t('CATALOG.FORMATS.PRODUCT.RULE'),
  },
  [CATALOG_KINDS.PRODUCT_LIST]: {
    name: t('CATALOG.FORMATS.PRODUCT_LIST.NAME'),
    rule: t('CATALOG.FORMATS.PRODUCT_LIST.RULE'),
  },
}));

const fieldLabels = computed(() => ({
  header: t('CATALOG.FIELDS.HEADER'),
  body: t('CATALOG.FIELDS.BODY'),
  footer: t('CATALOG.FIELDS.FOOTER'),
}));

const errorMessage = (code, { min, max } = {}) => {
  switch (code) {
    case CATALOG_ERRORS.MIN_ITEMS:
      return t('CATALOG.ERRORS.MIN_ITEMS', { min });
    case CATALOG_ERRORS.MAX_ITEMS:
      return t('CATALOG.ERRORS.MAX_ITEMS', { max, count: max });
    case CATALOG_ERRORS.REQUIRED:
      return t('CATALOG.ERRORS.REQUIRED');
    case CATALOG_ERRORS.TOO_LONG:
      return t('CATALOG.ERRORS.TOO_LONG');
    default:
      return '';
  }
};

const errorText = field =>
  submitted.value && errors.value[field]
    ? errorMessage(errors.value[field], limits.value)
    : '';

const reasonText = reason =>
  reason ? errorMessage(reason.key, reason.params) : '';

const isSelected = product => product.retailer_id in selected.value;

const toggleProduct = product => {
  if (isSelected(product)) {
    const { [product.retailer_id]: removed, ...rest } = selected.value;
    selected.value = rest;
  } else if (!atMax.value) {
    selected.value = { ...selected.value, [product.retailer_id]: product };
  }
};

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
  // loadFirstPage starts a new request id synchronously, so a slow catalog
  // answer from a previous open or inbox is ignored.
  const firstPage = loadFirstPage({ force });
  const currentRequest = requestId;
  const catalogRequest = loadCatalog(props.inboxId, { force })
    .then(data => {
      if (currentRequest === requestId) catalog.value = data;
    })
    .catch(() => {
      if (currentRequest === requestId) loadFailed.value = true;
    });
  await Promise.all([catalogRequest, firstPage]);
};

const refresh = async () => {
  isRefreshing.value = true;
  await loadCatalogAndFirstPage({ force: true });
  isRefreshing.value = false;
};

// Revalidates stale painted data without loading state, scroll or selection
// changes. It yields to any newer request (collection, search, reopen, close).
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
  view.value = 'products';
  catalog.value = null;
  products.value = [];
  loadFailed.value = false;
  query.value = '';
  collectionId.value = null;
  selectionMode.value = false;
  selected.value = {};
  detailItem.value = null;
  kind.value = null;
  form.value = { header: '', body: props.initialBody, footer: '' };
  submitted.value = false;
  sendError.value = '';
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

const exitSelection = () => {
  selectionMode.value = false;
  selected.value = {};
};

const suggestHeader = () => {
  if (form.value.header || kind.value !== CATALOG_KINDS.PRODUCT_LIST) return;
  const first = selectedProducts.value[0];
  if (first) {
    form.value.header = sectionFor(first).slice(0, CATALOG_TEXT_LIMITS.header);
  }
};

const chooseKind = value => {
  kind.value = value;
  sendError.value = '';
  suggestHeader();
};

const goToFormat = () => {
  if (!selectedCount.value) return;
  const current = formats.value.find(f => f.kind === kind.value);
  if (!current?.available) {
    chooseKind(formats.value.find(f => f.available).kind);
  } else {
    suggestHeader();
  }
  submitted.value = false;
  view.value = 'format';
};

const sheetTitle = computed(() =>
  detailItem.value ? t('CATALOG.PRODUCT.DETAILS_TITLE') : t('CATALOG.TITLE')
);

const goBack = () => {
  sendError.value = '';
  view.value = 'products';
};

const send = async () => {
  submitted.value = true;
  sendError.value = '';
  if (Object.keys(errors.value).length) return;
  isSending.value = true;
  try {
    await whatsappCatalogMessages.create(props.conversationId, {
      kind: kind.value,
      content: form.value.body.trim(),
      header: validationPayload.value.header.trim(),
      footer: validationPayload.value.footer.trim(),
      catalog_id: catalog.value.catalog_id,
      products: items.value,
    });
    emit('sent');
    close();
  } catch (error) {
    sendError.value =
      error?.response?.data?.error || t('CATALOG.ERRORS.SEND_FAILED');
  } finally {
    isSending.value = false;
  }
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
    :title="sheetTitle"
    :back-button="!!detailItem"
    size="md"
    @close="onClose"
  >
    <ProductDetail v-if="detailItem" :item="detailItem" />
    <div v-show="!detailItem" class="flex flex-col flex-1 min-h-0">
      <div
        v-if="view === 'products' && catalog && !needsGuide"
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
            v-if="!selectionMode"
            type="button"
            variant="faded"
            color="blue"
            :label="$t('CATALOG.ACTIONS.SELECT')"
            data-testid="catalog-select"
            @click="selectionMode = true"
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
        <span
          v-if="selectionMode"
          class="text-sm font-medium text-start text-n-slate-12"
          data-testid="catalog-counter"
        >
          {{
            $t('CATALOG.COUNTER', {
              count: selectedCount,
              max: CATALOG_MAX_SELECTION,
            })
          }}
        </span>
      </div>

      <div ref="listRef" class="flex-1 min-h-0 p-4 overflow-y-auto">
        <template v-if="view === 'products'">
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
              :selectable="selectionMode"
              :checked="isSelected(product)"
              :disabled="!isSelected(product) && atMax"
              @toggle="toggleProduct"
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
        </template>

        <div v-else class="flex flex-col gap-4">
          <div class="flex flex-col gap-2">
            <span class="text-sm font-medium text-n-slate-12">
              {{
                $t('CATALOG.COUNTER', {
                  count: selectedCount,
                  max: CATALOG_MAX_SELECTION,
                })
              }}
            </span>
            <div class="flex gap-1 overflow-x-auto">
              <img
                v-for="product in selectedProducts"
                :key="product.retailer_id"
                :src="product.image_urls?.[0]"
                :alt="product.name"
                loading="lazy"
                decoding="async"
                class="object-cover rounded-md size-8 shrink-0 bg-n-alpha-2"
              />
            </div>
          </div>

          <fieldset class="flex flex-col gap-2 p-0 m-0 border-0">
            <legend class="mb-1 text-sm font-medium text-n-slate-12">
              {{ $t('CATALOG.FORMAT.LABEL') }}
            </legend>
            <label
              v-for="format in formats"
              :key="format.kind"
              class="flex items-start gap-3 p-3 rounded-lg outline outline-1 -outline-offset-1"
              :class="[
                kind === format.kind
                  ? 'outline-n-brand bg-n-alpha-2'
                  : 'outline-n-container',
                format.available
                  ? 'cursor-pointer'
                  : 'opacity-60 cursor-not-allowed',
              ]"
            >
              <input
                type="radio"
                name="catalog-format"
                class="mt-1 mb-0 shrink-0"
                :checked="kind === format.kind"
                :disabled="!format.available"
                :data-testid="`catalog-format-${format.kind}`"
                @change="chooseKind(format.kind)"
              />
              <span class="flex flex-col gap-0.5">
                <span class="text-sm font-medium text-n-slate-12">
                  {{ formatTexts[format.kind].name }}
                </span>
                <span class="text-xs text-n-slate-11">
                  {{ formatTexts[format.kind].rule }}
                </span>
                <span
                  v-if="!format.available"
                  class="text-xs text-n-ruby-11"
                  :data-testid="`catalog-format-reason-${format.kind}`"
                >
                  {{
                    $t('CATALOG.FORMAT.UNAVAILABLE', {
                      reason: reasonText(format.reason),
                    })
                  }}
                </span>
              </span>
            </label>
          </fieldset>

          <div
            v-for="field in fields"
            :key="field.name"
            class="flex flex-col gap-1"
          >
            <label
              class="flex items-center justify-between gap-2 text-sm font-medium text-n-slate-12"
              :for="`catalog-${field.name}`"
            >
              <span>{{ fieldLabels[field.name] }}</span>
              <span class="text-xs font-normal text-n-slate-11">
                {{
                  field.required
                    ? $t('CATALOG.FIELDS.REQUIRED')
                    : $t('CATALOG.FIELDS.OPTIONAL')
                }}
              </span>
            </label>
            <textarea
              :id="`catalog-${field.name}`"
              v-model="form[field.name]"
              :rows="field.name === 'body' ? 4 : 1"
              class="mb-0"
              :data-testid="`catalog-field-${field.name}`"
            />
            <div class="flex justify-between gap-2 text-xs">
              <span class="text-n-ruby-11">{{ errorText(field.name) }}</span>
              <span class="text-n-slate-11">
                {{
                  $t('CATALOG.FIELDS.CHARACTERS', {
                    count: form[field.name].length,
                    max: CATALOG_TEXT_LIMITS[field.name],
                  })
                }}
              </span>
            </div>
          </div>
          <p
            v-if="sendError"
            class="mb-0 text-sm text-n-ruby-11"
            data-testid="catalog-send-error"
          >
            {{ sendError }}
          </p>
        </div>
      </div>
    </div>

    <template
      v-if="
        !detailItem &&
        ((view === 'products' && selectionMode && catalog && !needsGuide) ||
          view === 'format')
      "
      #footer
    >
      <div
        v-if="view === 'products'"
        class="flex items-center justify-between gap-3 p-4"
      >
        <Button
          type="button"
          variant="faded"
          color="slate"
          :label="$t('CATALOG.ACTIONS.CANCEL')"
          data-testid="catalog-cancel-selection"
          @click="exitSelection"
        />
        <Button
          type="button"
          color="blue"
          :label="$t('CATALOG.ACTIONS.NEXT')"
          :disabled="!selectedCount"
          data-testid="catalog-next"
          @click="goToFormat"
        />
      </div>
      <div v-else class="flex items-center justify-between gap-3 p-4">
        <Button
          type="button"
          variant="faded"
          color="slate"
          :label="$t('CATALOG.ACTIONS.BACK')"
          data-testid="catalog-back"
          @click="goBack"
        />
        <Button
          type="button"
          color="blue"
          :label="$t('CATALOG.ACTIONS.SEND')"
          :is-loading="isSending"
          :disabled="isSending"
          data-testid="catalog-send"
          @click="send"
        />
      </div>
    </template>
  </CatalogSheet>
</template>
