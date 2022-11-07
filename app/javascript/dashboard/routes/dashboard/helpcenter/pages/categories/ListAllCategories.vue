<template>
  <div class="category-list--container">
    <header>
      <div class="header-left--wrap">
        <label class="sub-block-title header-text">{{
          $t('HELP_CENTER.PORTAL.EDIT.CATEGORIES.TITLE')
        }}</label>
        <select
          :value="currentLocaleCode"
          class="row small-2 select-locale"
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
      <div class="header-right--wrap">
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
        :categories="categoryByLocaleCode"
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

import CategoryListItem from './CategoryListItem';
import AddCategory from './AddCategory';
import EditCategory from './EditCategory';

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
    categoryByLocaleCode() {
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
    async deleteCategory(categoryId) {
      try {
        await this.$store.dispatch('categories/delete', {
          portalSlug: this.currentPortalSlug,
          categoryId: categoryId,
        });
        this.alertMessage = this.$t(
          'HELP_CENTER.CATEGORY.DELETE.API.SUCCESS_MESSAGE'
        );
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
    },
  },
};
</script>
<style lang="scss" scoped>
.category-list--container {
  width: 100%;
  padding-left: var(--space-normal);

  header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: var(--space-normal);

    .header-left--wrap {
      display: flex;
      align-items: center;
      width: 100%;

      .header-text {
        font-weight: var(--font-weight-normal);
        margin-right: var(--space-slab);
        margin-bottom: 0;
      }
    }

    .header-right--wrap {
      flex: none;
      align-items: center;
    }
    .select-locale {
      height: var(--space-large);
      margin-bottom: 0;
      padding-top: var(--space-micro);
      padding-bottom: var(--space-micro);
    }
  }
}
</style>
