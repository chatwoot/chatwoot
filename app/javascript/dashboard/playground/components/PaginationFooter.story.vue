<script setup>
import PaginationFooter from './PaginationFooter.vue';
import { ref } from 'vue';

const defaultCurrentPage = ref(1);
const defaultTotalItems = ref(267);

const interactiveCurrentPage = ref(1);
const interactiveTotalItems = ref(267);
const interactiveItemsPerPage = ref(16);

const createUpdateFunctions = (initialPage = 1, initialItemsPerPage = 16) => {
  const currentPage = ref(initialPage);
  const itemsPerPage = ref(initialItemsPerPage);

  return {
    currentPage,
    itemsPerPage,
    updateCurrentPage: newPage => {
      currentPage.value = newPage;
    },
    updateItemsPerPage: newItemsPerPage => {
      itemsPerPage.value = newItemsPerPage;
    },
  };
};

const defaultVariant = createUpdateFunctions();
const firstPageVariant = createUpdateFunctions(1);
const lastPageVariant = createUpdateFunctions(17);
const middlePageVariant = createUpdateFunctions(8);
const fewItemsVariant = createUpdateFunctions(1);
const manyItemsVariant = createUpdateFunctions(1);
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story
    title="Components/PaginationFooter"
    :layout="{ type: 'grid', width: '100%' }"
  >
    <Variant title="Default">
      <PaginationFooter
        :current-page="defaultCurrentPage"
        :total-items="defaultTotalItems"
        :items-per-page="defaultVariant.itemsPerPage.value"
        @update:current-page="defaultVariant.updateCurrentPage"
        @update:items-per-page="defaultVariant.updateItemsPerPage"
      />
    </Variant>

    <Variant title="First Page">
      <PaginationFooter
        :current-page="firstPageVariant.currentPage.value"
        :total-items="267"
        :items-per-page="firstPageVariant.itemsPerPage.value"
        @update:current-page="firstPageVariant.updateCurrentPage"
        @update:items-per-page="firstPageVariant.updateItemsPerPage"
      />
    </Variant>

    <Variant title="Last Page">
      <PaginationFooter
        :current-page="lastPageVariant.currentPage.value"
        :total-items="267"
        :items-per-page="lastPageVariant.itemsPerPage.value"
        @update:current-page="lastPageVariant.updateCurrentPage"
        @update:items-per-page="lastPageVariant.updateItemsPerPage"
      />
    </Variant>

    <Variant title="Middle Page">
      <PaginationFooter
        :current-page="middlePageVariant.currentPage.value"
        :total-items="267"
        :items-per-page="middlePageVariant.itemsPerPage.value"
        @update:current-page="middlePageVariant.updateCurrentPage"
        @update:items-per-page="middlePageVariant.updateItemsPerPage"
      />
    </Variant>

    <Variant title="Few Items">
      <PaginationFooter
        :current-page="fewItemsVariant.currentPage.value"
        :total-items="5"
        :items-per-page="fewItemsVariant.itemsPerPage.value"
        @update:current-page="fewItemsVariant.updateCurrentPage"
        @update:items-per-page="fewItemsVariant.updateItemsPerPage"
      />
    </Variant>

    <Variant title="Many Items">
      <PaginationFooter
        :current-page="manyItemsVariant.currentPage.value"
        :total-items="1000"
        :items-per-page="manyItemsVariant.itemsPerPage.value"
        @update:current-page="manyItemsVariant.updateCurrentPage"
        @update:items-per-page="manyItemsVariant.updateItemsPerPage"
      />
    </Variant>

    <Variant title="Interactive">
      <PaginationFooter
        :current-page="interactiveCurrentPage"
        :total-items="interactiveTotalItems"
        :items-per-page="interactiveItemsPerPage"
        @update:current-page="newPage => (interactiveCurrentPage = newPage)"
        @update:items-per-page="
          newItemsPerPage => (interactiveItemsPerPage = newItemsPerPage)
        "
      />
      <div class="mt-4">
        <p>Current Page: {{ interactiveCurrentPage }}</p>
        <p>Items Per Page: {{ interactiveItemsPerPage }}</p>
      </div>
    </Variant>
  </Story>
</template>
