<template>
  <div class="w-full pl-4">
    <header class="flex justify-between items-center mb-4">
      <div class="flex items-center w-full gap-3">
        <label
          class="font-normal mb-0 text-base text-slate-800 dark:text-slate-100"
        >
          {{ $t('HELP_CENTER.PORTAL.EDIT.CATEGORIES.TITLE') }}
        </label>
        <select
          :value="currentLocaleCode"
          class="w-[15%] select-locale"
          @change="changeCurrentCategory"
        >
          <option
            v-for="allowedLocaleCode in allowedLocaleCodes"
            :key="allowedLocaleCode"
            :value="allowedLocaleCode"
          >
            {{ allowedLocaleCode }}
          </option>
        </select>
      </div>
      <div class="flex-none items-center">
        <woot-button
          size="small"
          variant="smooth"
          color-scheme="primary"
          icon="add"
          @click="openAddCategoryModal"
        >
          {{ $t('HELP_CENTER.PORTAL.EDIT.CATEGORIES.NEW_CATEGORY') }}
        </woot-button>
      </div>
    </header>
    <div class="category-list">
      <category-list-item
        :categories="categoriesByLocaleCode"
        @delete="deleteCategory"
        @edit="openEditCategoryModal"
      />
    </div>
    <edit-category
      v-if="showEditCategoryModal"
      :show.sync="showEditCategoryModal"
      :portal-name="currentPortalName"
      :locale="selectedCategory.locale"
      :category="selectedCategory"
      :selected-portal-slug="currentPortalSlug"
      @cancel="closeEditCategoryModal"
    />
    <add-category
      v-if="showAddCategoryModal"
      :show.sync="showAddCategoryModal"
      :portal-name="currentPortalName"
      :locale="currentLocaleCode"
      @cancel="closeAddCategoryModal"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import portalMixin from '../../mixins/portalMixin';

import CategoryListItem from './CategoryListItem.vue';
import AddCategory from './AddCategory.vue';
import EditCategory from './EditCategory.vue';
import { PORTALS_EVENTS } from '../../../../../helper/AnalyticsHelper/events';

export default {
  components: {
    CategoryListItem,
    AddCategory,
    EditCategory,
  },
  mixins: [alertMixin, portalMixin],
  data() {
    return {
      selectedCategory: {},
      selectedLocaleCode: '',
      currentLocaleCode: 'en',
      showEditCategoryModal: false,
      showAddCategoryModal: false,
      alertMessage: '',
    };
  },
  computed: {
    ...mapGetters({
      portals: 'portals/allPortals',
      meta: 'portals/getMeta',
      isFetching: 'portals/isFetchingPortals',
    }),
    currentPortalSlug() {
      return this.$route.params.portalSlug;
    },
    categoriesByLocaleCode() {
      return this.$store.getters['categories/categoriesByLocaleCode'](
        this.currentLocaleCode
      );
    },
    currentPortal() {
      const slug = this.currentPortalSlug;
      if (slug) return this.$store.getters['portals/portalBySlug'](slug);

      return this.$store.getters['portals/allPortals'][0];
    },
    currentPortalName() {
      return this.currentPortal ? this.currentPortal.name : '';
    },
    currentPortalLocale() {
      return this.currentPortal ? this.currentPortal?.meta?.default_locale : '';
    },
    allLocales() {
      return this.currentPortal
        ? this.currentPortal.config.allowed_locales
        : [];
    },
    allowedLocaleCodes() {
      return this.allLocales.map(locale => locale.code);
    },
  },
  methods: {
    openAddCategoryModal() {
      this.showAddCategoryModal = true;
    },
    openEditCategoryModal(category) {
      this.selectedCategory = category;
      this.showEditCategoryModal = true;
    },
    closeAddCategoryModal() {
      this.showAddCategoryModal = false;
    },
    closeEditCategoryModal() {
      this.showEditCategoryModal = false;
    },
    async fetchCategoriesByPortalSlugAndLocale(localeCode) {
      await this.$store.dispatch('categories/index', {
        portalSlug: this.currentPortalSlug,
        locale: localeCode,
      });
    },
    async deleteCategory(category) {
      try {
        await this.$store.dispatch('categories/delete', {
          portalSlug: this.currentPortalSlug,
          categoryId: category.id,
        });
        this.alertMessage = this.$t(
          'HELP_CENTER.CATEGORY.DELETE.API.SUCCESS_MESSAGE'
        );
        this.$track(PORTALS_EVENTS.DELETE_CATEGORY, {
          hasArticles: category?.meta?.articles_count !== 0,
        });
      } catch (error) {
        const errorMessage = error?.message;
        this.alertMessage =
          errorMessage ||
          this.$t('HELP_CENTER.CATEGORY.DELETE.API.ERROR_MESSAGE');
      } finally {
        this.showAlert(this.alertMessage);
      }
    },
    changeCurrentCategory(event) {
      const localeCode = event.target.value;
      this.currentLocaleCode = localeCode;
      this.fetchCategoriesByPortalSlugAndLocale(localeCode);
    },
  },
};
</script>
<style lang="scss" scoped>
.select-locale {
  @apply h-8 mb-0 py-0.5;
}
</style>
