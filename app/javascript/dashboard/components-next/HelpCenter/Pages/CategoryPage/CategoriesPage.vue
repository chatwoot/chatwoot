<script setup>
import { ref, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import CategoryList from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryList.vue';
import CategoryHeaderControls from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryHeaderControls.vue';
import CategoryEmptyState from 'dashboard/components-next/HelpCenter/EmptyState/Category/CategoryEmptyState.vue';
import EditCategoryDialog from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/EditCategoryDialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  categories: {
    type: Array,
    required: true,
  },
  isFetching: {
    type: Boolean,
    required: false,
  },
  allowedLocales: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['fetchCategories']);

const route = useRoute();
const router = useRouter();
const store = useStore();
const { t } = useI18n();

const editCategoryDialog = ref(null);
const selectedCategory = ref(null);

const isSwitchingPortal = useMapGetter('portals/isSwitchingPortal');
const isLoading = computed(() => props.isFetching || isSwitchingPortal.value);
const hasCategories = computed(() => props.categories?.length > 0);

const updateRoute = (newParams, routeName) => {
  const { accountId, portalSlug, locale } = route.params;
  const baseParams = { accountId, portalSlug, locale };

  router.push({
    name: routeName,
    params: {
      ...baseParams,
      ...newParams,
      categorySlug: newParams.categorySlug,
    },
  });
};

const openCategoryArticles = slug => {
  updateRoute({ categorySlug: slug }, 'portals_categories_articles_index');
};

const handleLocaleChange = value => {
  updateRoute({ locale: value }, 'portals_categories_index');
  emit('fetchCategories', value);
};

async function deleteCategory(category) {
  try {
    await store.dispatch('categories/delete', {
      portalSlug: route.params.portalSlug,
      categoryId: category.id,
    });

    useTrack(PORTALS_EVENTS.DELETE_CATEGORY, {
      hasArticles: category?.meta?.articles_count > 0,
    });

    useAlert(
      t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.DELETE.API.SUCCESS_MESSAGE')
    );
  } catch (error) {
    useAlert(
      error.message ||
        t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.DELETE.API.ERROR_MESSAGE')
    );
  }
}

const handleAction = ({ action, id, category: categoryData }) => {
  if (action === 'edit') {
    selectedCategory.value = props.categories.find(
      category => category.id === id
    );
    editCategoryDialog.value.dialogRef.open();
  }
  if (action === 'delete') {
    deleteCategory(categoryData);
  }
};
</script>

<template>
  <HelpCenterLayout :show-pagination-footer="false">
    <template #header-actions>
      <CategoryHeaderControls
        :categories="categories"
        :is-category-articles="false"
        :allowed-locales="allowedLocales"
        @locale-change="handleLocaleChange"
      />
    </template>
    <template #content>
      <div
        v-if="isLoading"
        class="flex items-center justify-center py-10 text-n-slate-11"
      >
        <Spinner />
      </div>
      <CategoryList
        v-else-if="hasCategories"
        :categories="categories"
        @click="openCategoryArticles"
        @action="handleAction"
      />
      <CategoryEmptyState
        v-else
        class="pt-14"
        :title="t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_EMPTY_STATE.TITLE')"
        :subtitle="t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_EMPTY_STATE.SUBTITLE')"
      />
    </template>
    <EditCategoryDialog
      ref="editCategoryDialog"
      :allowed-locales="allowedLocales"
      :selected-category="selectedCategory"
    />
  </HelpCenterLayout>
</template>
