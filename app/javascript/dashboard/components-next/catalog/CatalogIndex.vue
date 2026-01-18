<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'shared/components/Spinner.vue';
import ProductDialog from './ProductDialog.vue';
import ConfirmDeleteProductDialog from './ConfirmDeleteProductDialog.vue';

const { t } = useI18n();
const store = useStore();
const { currentAccount } = useAccount();

const products = useMapGetter('products/getProducts');
const uiFlags = useMapGetter('products/getUIFlags');

const catalogCurrency = computed(
  () => currentAccount.value?.settings?.catalog_currency
);

const showAddDialog = ref(false);
const showEditDialog = ref(false);
const showDeleteDialog = ref(false);
const selectedProduct = ref(null);
const searchValue = ref('');

const isLoading = computed(() => uiFlags.value.isFetching);

const filteredProducts = computed(() => {
  if (!searchValue.value) return products.value;
  const query = searchValue.value.toLowerCase();
  return products.value.filter(
    product =>
      product.title_en?.toLowerCase().includes(query) ||
      product.title_ar?.toLowerCase().includes(query) ||
      product.description_en?.toLowerCase().includes(query) ||
      product.description_ar?.toLowerCase().includes(query)
  );
});

const noRecords = computed(() => filteredProducts.value.length === 0);
const hasSearchQuery = computed(() => searchValue.value.length > 0);

const openAddDialog = () => {
  selectedProduct.value = null;
  showAddDialog.value = true;
};

const openEditDialog = product => {
  selectedProduct.value = product;
  showEditDialog.value = true;
};

const openDeleteDialog = product => {
  selectedProduct.value = product;
  showDeleteDialog.value = true;
};

const closeAddDialog = () => {
  showAddDialog.value = false;
};

const closeEditDialog = () => {
  showEditDialog.value = false;
};

const closeDeleteDialog = () => {
  showDeleteDialog.value = false;
};

const handleCreate = async ({ product, blobId }) => {
  try {
    await store.dispatch('products/create', { ...product, blob_id: blobId });
    useAlert(t('CATALOG.SUCCESS.CREATE'));
    closeAddDialog();
  } catch (error) {
    useAlert(error.message || t('CATALOG.ERROR.CREATE'));
  }
};

const handleUpdate = async ({ product, blobId }) => {
  try {
    await store.dispatch('products/update', {
      id: selectedProduct.value.id,
      ...product,
      blob_id: blobId,
    });
    useAlert(t('CATALOG.SUCCESS.UPDATE'));
    closeEditDialog();
  } catch (error) {
    useAlert(error.message || t('CATALOG.ERROR.UPDATE'));
  }
};

const handleDelete = async () => {
  try {
    await store.dispatch('products/delete', selectedProduct.value.id);
    useAlert(t('CATALOG.SUCCESS.DELETE'));
    closeDeleteDialog();
  } catch (error) {
    useAlert(error.message || t('CATALOG.ERROR.DELETE'));
  }
};

const onSearch = event => {
  searchValue.value = event.target.value;
};

const formatPrice = price => {
  return `${Number(price).toFixed(2)} ${catalogCurrency.value}`;
};

onMounted(() => {
  store.dispatch('products/get');
});
</script>

<template>
  <section
    class="flex w-full h-full gap-4 overflow-hidden justify-evenly bg-n-background"
  >
    <div class="flex flex-col w-full h-full">
      <!-- Header -->
      <header class="sticky top-0 z-10">
        <div
          class="flex flex-col sm:flex-row items-start sm:items-center justify-between w-full gap-4 py-6 px-6 mx-auto max-w-[60rem]"
        >
          <span class="text-xl font-medium truncate text-n-slate-12">
            {{ t('CATALOG.HEADER.TITLE') }}
          </span>
          <div class="flex items-center gap-4 w-full sm:w-auto">
            <div class="relative flex-1 sm:flex-none sm:w-64">
              <Input
                :model-value="searchValue"
                type="search"
                :placeholder="t('CATALOG.HEADER.SEARCH_PLACEHOLDER')"
                :custom-input-class="[
                  'h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8',
                ]"
                class="w-full"
                @input="onSearch"
              >
                <template #prefix>
                  <Icon
                    icon="i-lucide-search"
                    class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2 rtl:right-2"
                  />
                </template>
              </Input>
            </div>
            <Button
              icon="i-lucide-plus"
              :label="t('CATALOG.ADD_PRODUCT')"
              sm
              @click="openAddDialog"
            />
          </div>
        </div>
      </header>

      <!-- Content -->
      <main class="flex-1 overflow-y-auto">
        <div class="w-full px-6 pb-6 mx-auto max-w-[60rem]">
          <!-- Loading State -->
          <div v-if="isLoading" class="flex items-center justify-center h-64">
            <Spinner size="large" />
          </div>

          <!-- Empty State - No products at all -->
          <div
            v-else-if="noRecords && !hasSearchQuery"
            class="flex flex-col items-center justify-center h-64 gap-4"
          >
            <div
              class="size-16 flex items-center justify-center rounded-full bg-n-alpha-2"
            >
              <span class="text-4xl i-lucide-package text-n-slate-10" />
            </div>
            <div class="text-center">
              <h3 class="text-lg font-medium text-n-slate-12">
                {{ t('CATALOG.EMPTY_STATE.TITLE') }}
              </h3>
              <p class="mt-1 text-sm text-n-slate-11">
                {{ t('CATALOG.EMPTY_STATE.SUBTITLE') }}
              </p>
            </div>
            <Button
              icon="i-lucide-plus"
              :label="t('CATALOG.ADD_PRODUCT')"
              @click="openAddDialog"
            />
          </div>

          <!-- Empty State - No search results -->
          <div
            v-else-if="noRecords && hasSearchQuery"
            class="flex flex-col items-center justify-center h-64 gap-4"
          >
            <div
              class="size-16 rounded-full flex items-center justify-center bg-n-alpha-2"
            >
              <span class="text-4xl i-lucide-search-x text-n-slate-10" />
            </div>
            <div class="text-center">
              <h3 class="text-lg font-medium text-n-slate-12">
                {{ t('CATALOG.EMPTY_STATE.NO_RESULTS') }}
              </h3>
              <p class="mt-1 text-sm text-n-slate-11">
                {{ t('CATALOG.EMPTY_STATE.NO_RESULTS_SUBTITLE') }}
              </p>
            </div>
          </div>

          <!-- Products Table -->
          <div v-else>
            <table class="min-w-full divide-y divide-n-weak">
              <thead>
                <tr>
                  <th
                    class="w-px py-3 text-xs font-semibold tracking-wide text-left uppercase ltr:pr-4 rtl:pl-4 text-n-slate-11"
                  >
                    {{ t('CATALOG.TABLE.IMAGE') }}
                  </th>
                  <th
                    class="py-3 text-xs font-semibold tracking-wide text-left uppercase ltr:pr-4 rtl:pl-4 text-n-slate-11"
                  >
                    {{ t('CATALOG.TABLE.TITLE') }}
                  </th>
                  <th
                    class="w-px py-3 text-xs font-semibold tracking-wide text-left uppercase ltr:pr-4 rtl:pl-4 text-n-slate-11"
                  >
                    {{ t('CATALOG.TABLE.PRICE') }}
                  </th>
                  <th
                    class="w-px py-3 text-xs font-semibold tracking-wide text-right uppercase text-n-slate-11"
                  >
                    {{ t('CATALOG.TABLE.ACTIONS') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-n-weak">
                <tr v-for="product in filteredProducts" :key="product.id">
                  <td class="py-4 ltr:pr-4 rtl:pl-4">
                    <div
                      class="flex items-center justify-center w-12 h-12 overflow-hidden rounded-lg bg-n-alpha-2"
                    >
                      <img
                        v-if="product.image_url"
                        :src="product.image_url"
                        :alt="product.title_en"
                        class="object-cover w-full h-full"
                      />
                      <span
                        v-else
                        class="text-xl i-lucide-image text-n-slate-10"
                      />
                    </div>
                  </td>
                  <td class="py-4 ltr:pr-4 rtl:pl-4">
                    <span class="font-medium text-n-slate-12">
                      {{ product.title_en }}
                    </span>
                  </td>
                  <td class="py-4 ltr:pr-4 rtl:pl-4 whitespace-nowrap">
                    <span class="font-medium text-n-slate-12">
                      {{ formatPrice(product.price) }}
                    </span>
                  </td>
                  <td class="py-4">
                    <div class="flex items-center justify-end gap-2">
                      <Button
                        v-tooltip.top="t('CATALOG.ACTIONS.EDIT')"
                        icon="i-lucide-pen"
                        slate
                        xs
                        faded
                        @click="openEditDialog(product)"
                      />
                      <Button
                        v-tooltip.top="t('CATALOG.ACTIONS.DELETE')"
                        icon="i-lucide-trash-2"
                        xs
                        ruby
                        faded
                        @click="openDeleteDialog(product)"
                      />
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>

    <!-- Add Product Dialog -->
    <ProductDialog
      :show="showAddDialog"
      :is-loading="uiFlags.isCreating"
      @close="closeAddDialog"
      @submit="handleCreate"
    />

    <!-- Edit Product Dialog -->
    <ProductDialog
      :show="showEditDialog"
      :product="selectedProduct"
      :is-loading="uiFlags.isUpdating"
      @close="closeEditDialog"
      @submit="handleUpdate"
    />

    <!-- Delete Confirmation Dialog -->
    <ConfirmDeleteProductDialog
      :show="showDeleteDialog"
      :product="selectedProduct"
      :is-loading="uiFlags.isDeleting"
      @close="closeDeleteDialog"
      @confirm="handleDelete"
    />
  </section>
</template>
