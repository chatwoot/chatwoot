<template>
  <div class="flex-1 overflow-auto p-4">
    <div class="button--fixed-top flex flex-row items-center gap-2">
      <div
        class="max-w-[400px] min-w-[150px] flex items-center relative mx-2 search-wrap"
      >
        <div class="flex items-center absolute h-full left-2.5">
          <fluent-icon
            icon="search"
            class="h-5 leading-9 text-sm text-slate-700 dark:text-slate-200"
          />
        </div>
        <input
          type="text"
          :placeholder="$t('PRODUCTS_PAGE.SEARCH_INPUT_PLACEHOLDER')"
          class="contact-search border-slate-100 dark:border-slate-600"
          :value="searchQuery"
          @keyup.enter="submitSearch"
          @input="inputSearch"
        />
        <woot-button
          :is-loading="false"
          class="clear"
          :class-names="searchButtonClass"
          @click="submitSearch"
        >
          {{ $t('PRODUCTS_PAGE.SEARCH_BUTTON') }}
        </woot-button>
      </div>
      <woot-button
        color-scheme="success"
        icon="add-circle"
        @click="onCreateProduct()"
      >
        {{ $t('PRODUCTS_PAGE.HEADER_BUTTON') }}
      </woot-button>
    </div>
    <div class="flex flex-col h-full">
      <products-table
        :products="records"
        :show-search-empty-state="showEmptySearchResult"
        :is-loading="uiFlags.isFetching"
        :on-click-product="openProductModal"
        :active-product-id="selectedProductId"
        @on-sort-change="onSortChange"
      />
      <table-footer
        class="border-t border-slate-75 dark:border-slate-700/50"
        :current-page="Number(meta.currentPage)"
        :total-count="meta.count"
        :page-size="15"
        @page-change="onPageChange"
      />
    </div>
    <product-form
      :show="showProductModal"
      :product="selectedProduct"
      @cancel="closeProductModal"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ProductsTable from './ProductsTable.vue';
import TableFooter from 'dashboard/components/widgets/TableFooter.vue';
import ProductForm from './ProductForm.vue';

const DEFAULT_PAGE = 1;

export default {
  components: {
    ProductsTable,
    TableFooter,
    ProductForm,
  },
  data() {
    return {
      searchQuery: '',
      showProductModal: false,
      selectedProductId: '',
      sortConfig: { name: 'asc' },
    };
  },
  computed: {
    ...mapGetters({
      records: 'products/getProducts',
      uiFlags: 'products/getUIFlags',
      meta: 'products/getMeta',
    }),
    showEmptySearchResult() {
      const hasEmptyResults = !!this.searchQuery && this.records.length === 0;
      return hasEmptyResults;
    },
    selectedProduct() {
      if (this.selectedProductId) {
        const product = this.records.find(
          item => this.selectedProductId === item.id
        );
        return product;
      }
      return {};
    },
    searchButtonClass() {
      return this.searchQuery !== '' ? 'show' : '';
    },
    pageParameter() {
      const selectedPageNumber = Number(this.$route.query?.page);
      return !Number.isNaN(selectedPageNumber) &&
        selectedPageNumber >= DEFAULT_PAGE
        ? selectedPageNumber
        : DEFAULT_PAGE;
    },
  },
  mounted() {
    this.fetchProducts(this.pageParameter);
  },
  methods: {
    updatePageParam(page) {
      window.history.pushState({}, null, `${this.$route.path}?page=${page}`);
    },
    onPageChange(page) {
      this.selectedProductId = '';
      this.fetchProducts(page);
    },
    getSortAttribute() {
      let sortAttr = Object.keys(this.sortConfig).reduce((acc, sortKey) => {
        const sortOrder = this.sortConfig[sortKey];
        if (sortOrder) {
          const sortOrderSign = sortOrder === 'asc' ? '' : '-';
          return `${sortOrderSign}${sortKey}`;
        }
        return acc;
      }, '');
      if (!sortAttr) {
        this.sortConfig = { name: 'asc' };
        sortAttr = '-name';
      }
      return sortAttr;
    },
    onSortChange(params) {
      this.sortConfig = params;
      this.fetchProducts(this.meta.currentPage);
    },
    fetchProducts(page) {
      this.updatePageParam(page);
      let value = '';
      if (this.searchQuery.charAt(0) === '+') {
        value = this.searchQuery.substring(1);
      } else {
        value = this.searchQuery;
      }
      const requestParams = {
        page,
        sortAttr: this.getSortAttribute(),
      };
      if (!value) {
        this.$store.dispatch('products/get', requestParams);
      } else {
        this.$store.dispatch('products/search', {
          search: encodeURIComponent(value),
          ...requestParams,
        });
      }
    },
    inputSearch(event) {
      const newQuery = event.target.value;
      const refetchAllProducts = !!this.searchQuery && newQuery === '';
      this.searchQuery = newQuery;
      if (refetchAllProducts) {
        this.fetchProducts(DEFAULT_PAGE);
      }
    },
    submitSearch() {
      this.selectedProductId = '';
      if (this.searchQuery) {
        this.fetchProducts(DEFAULT_PAGE);
      }
    },
    openProductModal(productId) {
      this.selectedProductId = productId;
      this.showProductModal = true;
    },
    closeProductModal() {
      this.selectedProductId = '';
      this.showProductModal = false;
    },
    onCreateProduct() {
      this.showProductModal = !this.showProductModal;
    },
  },
};
</script>

<style lang="scss" scoped>
.search-wrap {
  .contact-search {
    @apply pl-9 pr-[3.75rem] text-sm w-full h-[2.375rem] m-0;
  }

  .button {
    transition: transform 100ms linear;
    @apply ml-2 h-8 right-1 absolute py-0 px-2 opacity-0 -translate-x-px invisible;
  }

  .button.show {
    @apply opacity-100 translate-x-0 visible;
  }
}
</style>
