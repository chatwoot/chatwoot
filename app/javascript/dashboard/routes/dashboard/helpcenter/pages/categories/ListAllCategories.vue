<script setup>
import { useRoute } from 'dashboard/composables/route';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useI18n } from 'dashboard/composables/useI18n';
import { useAlert, useTrack } from 'dashboard/composables';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import { defineComponent, ref, computed } from 'vue';

import CategoryListItem from './CategoryListItem.vue';
import AddCategory from './AddCategory.vue';
import EditCategory from './EditCategory.vue';

defineComponent({
  name: 'ListAllCategories',
});

const selectedCategory = ref({});
const currentLocaleCode = ref('en');
const showEditCategoryModal = ref(false);
const showAddCategoryModal = ref(false);

const getters = useStoreGetters();
const store = useStore();
const route = useRoute();
const track = useTrack();
const { t } = useI18n();
const currentPortalSlug = computed(() => {
  return route.params.portalSlug;
});

const categoriesByLocaleCode = computed(() => {
  return getters['categories/categoriesByLocaleCode'].value(
    currentLocaleCode.value
  );
});

const currentPortal = computed(() => {
  const slug = currentPortalSlug.value;
  if (slug) return getters['portals/portalBySlug'].value(slug);

  return getters['portals/allPortals'].value[0];
});
const currentPortalName = computed(() => {
  return currentPortal.value ? currentPortal.value.name : '';
});
const allLocales = computed(() => {
  return currentPortal.value ? currentPortal.value.config.allowed_locales : [];
});

const allowedLocaleCodes = computed(() => {
  return allLocales.value.map(locale => locale.code);
});

function openAddCategoryModal() {
  showAddCategoryModal.value = true;
}
function openEditCategoryModal(category) {
  selectedCategory.value = category;
  showEditCategoryModal.value = true;
}
function closeAddCategoryModal() {
  showAddCategoryModal.value = false;
}
function closeEditCategoryModal() {
  showEditCategoryModal.value = false;
}
async function fetchCategoriesByPortalSlugAndLocale(localeCode) {
  await store.dispatch('categories/index', {
    portalSlug: currentPortalSlug.value,
    locale: localeCode,
  });
}

async function deleteCategory(category) {
  let alertMessage = '';
  try {
    await store.dispatch('categories/delete', {
      portalSlug: currentPortalSlug.value,
      categoryId: category.id,
    });
    alertMessage = t('HELP_CENTER.CATEGORY.DELETE.API.SUCCESS_MESSAGE');
    track(PORTALS_EVENTS.DELETE_CATEGORY, {
      hasArticles: category?.meta?.articles_count !== 0,
    });
  } catch (error) {
    const errorMessage = error?.message;
    alertMessage =
      errorMessage || t('HELP_CENTER.CATEGORY.DELETE.API.ERROR_MESSAGE');
  } finally {
    useAlert(alertMessage);
  }
}
function changeCurrentCategory(event) {
  const localeCode = event.target.value;
  currentLocaleCode.value = localeCode;
  fetchCategoriesByPortalSlugAndLocale(localeCode);
}
</script>

<template>
  <div class="w-full max-w-6xl">
    <header class="flex items-center justify-between mb-4">
      <div class="flex items-center w-full gap-3">
        <label
          class="mb-0 text-base font-normal text-slate-800 dark:text-slate-100"
        >
          {{ $t('HELP_CENTER.PORTAL.EDIT.CATEGORIES.TITLE') }}
        </label>
        <select
          :value="currentLocaleCode"
          class="w-[15%] h-8 mb-0 py-0.5"
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
      <div class="items-center flex-none">
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
