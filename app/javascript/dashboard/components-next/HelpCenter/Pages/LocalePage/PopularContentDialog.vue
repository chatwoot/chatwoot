<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useDebounceFn } from '@vueuse/core';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import categoriesAPI from 'dashboard/api/helpCenter/categories';
import articlesAPI from 'dashboard/api/helpCenter/articles';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';

const props = defineProps({
  portal: {
    type: Object,
    default: () => ({}),
  },
});

const MAX_SELECTION = 3;

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const activeLocale = ref('');
const isLoading = ref(false);

const categoryResults = ref([]);
const selectedCategoryIds = ref([]);

// Articles are searched server-side, so cache labels for selected items that
// fall outside the current results.
const articleResults = ref([]);
const articleLabelById = ref({});
const selectedArticleIds = ref([]);

const popularContent = computed(
  () => props.portal?.config?.popular_content || {}
);

// A selected id shows its cached label, a loading placeholder while fetching, or
// the raw id if loading fails; fetched results fill the rest of the dropdown.
const buildOptions = (selectedIds, results, labelById = {}) => {
  const loadingLabel = t(
    'HELP_CENTER.LOCALES_PAGE.POPULAR_CONTENT_DIALOG.LOADING'
  );
  const optionsById = new Map();
  selectedIds.forEach(id => {
    optionsById.set(id, {
      value: id,
      label: labelById[id] ?? (isLoading.value ? loadingLabel : String(id)),
    });
  });
  results.forEach(option => optionsById.set(option.value, option));
  return [...optionsById.values()];
};

const categoryOptions = computed(() =>
  buildOptions(selectedCategoryIds.value, categoryResults.value)
);

const articleOptions = computed(() =>
  buildOptions(
    selectedArticleIds.value,
    articleResults.value,
    articleLabelById.value
  )
);

const fetchCategories = async localeCode => {
  const {
    data: { payload },
  } = await categoriesAPI.get({
    portalSlug: props.portal?.slug,
    locale: localeCode,
  });
  categoryResults.value = payload.map(category => ({
    value: category.id,
    label: category.name,
  }));
};

const searchArticles = async (query = '') => {
  const { data } = await articlesAPI.getArticles({
    pageNumber: 1,
    portalSlug: props.portal?.slug,
    locale: activeLocale.value,
    status: 'published',
    query,
  });
  articleResults.value = data.payload.map(article => {
    articleLabelById.value[article.id] = article.title;
    return { value: article.id, label: article.title };
  });
};

const onArticleSearch = useDebounceFn(searchArticles, 300);

// Resolve titles for pre-selected articles that aren't in the current results.
const cacheSelectedArticleLabels = async () => {
  const unknownIds = selectedArticleIds.value.filter(
    id => !articleLabelById.value[id]
  );
  await Promise.all(
    unknownIds.map(async id => {
      try {
        const { data } = await articlesAPI.getArticle({
          id,
          portalSlug: props.portal?.slug,
        });
        articleLabelById.value[id] = data.payload.title;
      } catch {
        // Deleted since it was picked; leave it for the id fallback.
      }
    })
  );
};

const openForLocale = async localeCode => {
  const existing = popularContent.value[localeCode] || {};
  activeLocale.value = localeCode;
  selectedCategoryIds.value = [...(existing.category_ids || [])];
  selectedArticleIds.value = [...(existing.article_ids || [])];
  categoryResults.value = [];
  articleResults.value = [];
  articleLabelById.value = {};
  dialogRef.value?.open();

  isLoading.value = true;
  try {
    await Promise.all([
      fetchCategories(localeCode),
      cacheSelectedArticleLabels(),
      searchArticles(),
    ]);
  } catch (error) {
    useAlert(
      error?.message ||
        t('HELP_CENTER.LOCALES_PAGE.POPULAR_CONTENT_DIALOG.API.ERROR_MESSAGE')
    );
  } finally {
    isLoading.value = false;
  }
};

const onCategoriesUpdate = ids => {
  selectedCategoryIds.value = ids.slice(0, MAX_SELECTION);
};

const onArticlesUpdate = ids => {
  selectedArticleIds.value = ids.slice(0, MAX_SELECTION);
};

const selectionMessage = count =>
  t('HELP_CENTER.LOCALES_PAGE.POPULAR_CONTENT_DIALOG.SELECTION_COUNT', {
    count,
    max: MAX_SELECTION,
  });

const onConfirm = async () => {
  const updated = { ...popularContent.value };
  const entry = {
    category_ids: selectedCategoryIds.value,
    article_ids: selectedArticleIds.value,
  };

  if (entry.category_ids.length || entry.article_ids.length) {
    updated[activeLocale.value] = entry;
  } else {
    delete updated[activeLocale.value];
  }

  try {
    await store.dispatch('portals/update', {
      portalSlug: props.portal?.slug,
      config: { popular_content: updated },
    });
    dialogRef.value?.close();
    useAlert(
      t('HELP_CENTER.LOCALES_PAGE.POPULAR_CONTENT_DIALOG.API.SUCCESS_MESSAGE')
    );
  } catch (error) {
    useAlert(
      error?.message ||
        t('HELP_CENTER.LOCALES_PAGE.POPULAR_CONTENT_DIALOG.API.ERROR_MESSAGE')
    );
  }
};

defineExpose({ openForLocale });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="t('HELP_CENTER.LOCALES_PAGE.POPULAR_CONTENT_DIALOG.TITLE')"
    :description="
      t('HELP_CENTER.LOCALES_PAGE.POPULAR_CONTENT_DIALOG.DESCRIPTION')
    "
    @confirm="onConfirm"
  >
    <div class="flex flex-col gap-4">
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{
            t(
              'HELP_CENTER.LOCALES_PAGE.POPULAR_CONTENT_DIALOG.CATEGORIES.LABEL'
            )
          }}
        </label>
        <TagMultiSelectComboBox
          :model-value="selectedCategoryIds"
          :options="categoryOptions"
          :disabled="isLoading"
          :placeholder="
            t(
              'HELP_CENTER.LOCALES_PAGE.POPULAR_CONTENT_DIALOG.CATEGORIES.PLACEHOLDER'
            )
          "
          :search-placeholder="
            t('HELP_CENTER.LOCALES_PAGE.POPULAR_CONTENT_DIALOG.SEARCH')
          "
          :empty-state="
            t('HELP_CENTER.LOCALES_PAGE.POPULAR_CONTENT_DIALOG.EMPTY')
          "
          :message="selectionMessage(selectedCategoryIds.length)"
          @update:model-value="onCategoriesUpdate"
        />
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{
            t('HELP_CENTER.LOCALES_PAGE.POPULAR_CONTENT_DIALOG.ARTICLES.LABEL')
          }}
        </label>
        <TagMultiSelectComboBox
          server-search
          :model-value="selectedArticleIds"
          :options="articleOptions"
          :disabled="isLoading"
          :placeholder="
            t(
              'HELP_CENTER.LOCALES_PAGE.POPULAR_CONTENT_DIALOG.ARTICLES.PLACEHOLDER'
            )
          "
          :search-placeholder="
            t('HELP_CENTER.LOCALES_PAGE.POPULAR_CONTENT_DIALOG.SEARCH')
          "
          :empty-state="
            t('HELP_CENTER.LOCALES_PAGE.POPULAR_CONTENT_DIALOG.EMPTY')
          "
          :message="selectionMessage(selectedArticleIds.length)"
          @update:model-value="onArticlesUpdate"
          @search="onArticleSearch"
        />
      </div>
    </div>
  </Dialog>
</template>
