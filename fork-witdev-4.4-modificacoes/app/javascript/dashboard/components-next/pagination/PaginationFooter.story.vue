<script setup>
import { ref } from 'vue';
import PaginationFooter from './PaginationFooter.vue';

const createPaginationState = (initialPage, totalItems, itemsPerPage) => {
  const currentPage = ref(initialPage);
  const handlePageChange = newPage => {
    currentPage.value = newPage;
  };
  return { currentPage, totalItems, itemsPerPage, handlePageChange };
};

const defaultState = createPaginationState(1, 100, 16);
const middlePageState = createPaginationState(3, 100, 16);
const lastPageState = createPaginationState(7, 100, 16);
const customItemsState = createPaginationState(2, 100, 10);
const singlePageState = createPaginationState(1, 10, 16);
</script>

<template>
  <Story
    title="Components/PaginationFooter"
    :layout="{ type: 'grid', width: '957' }"
  >
    <Variant title="Default">
      <div class="p-4 bg-white dark:bg-slate-900">
        <PaginationFooter
          :current-page="defaultState.currentPage.value"
          :total-items="defaultState.totalItems"
          :items-per-page="defaultState.itemsPerPage"
          @update:current-page="defaultState.handlePageChange"
        />
      </div>
    </Variant>

    <Variant title="Middle Page">
      <div class="p-4 bg-white dark:bg-slate-900">
        <PaginationFooter
          :current-page="middlePageState.currentPage.value"
          :total-items="middlePageState.totalItems"
          :items-per-page="middlePageState.itemsPerPage"
          @update:current-page="middlePageState.handlePageChange"
        />
      </div>
    </Variant>

    <Variant title="Last Page">
      <div class="p-4 bg-white dark:bg-slate-900">
        <PaginationFooter
          :current-page="lastPageState.currentPage.value"
          :total-items="lastPageState.totalItems"
          :items-per-page="lastPageState.itemsPerPage"
          @update:current-page="lastPageState.handlePageChange"
        />
      </div>
    </Variant>

    <Variant title="Custom Items Per Page">
      <div class="p-4 bg-white dark:bg-slate-900">
        <PaginationFooter
          :current-page="customItemsState.currentPage.value"
          :total-items="customItemsState.totalItems"
          :items-per-page="customItemsState.itemsPerPage"
          @update:current-page="customItemsState.handlePageChange"
        />
      </div>
    </Variant>

    <Variant title="Single Page">
      <div class="p-4 bg-white dark:bg-slate-900">
        <PaginationFooter
          :current-page="singlePageState.currentPage.value"
          :total-items="singlePageState.totalItems"
          :items-per-page="singlePageState.itemsPerPage"
          @update:current-page="singlePageState.handlePageChange"
        />
      </div>
    </Variant>
  </Story>
</template>
