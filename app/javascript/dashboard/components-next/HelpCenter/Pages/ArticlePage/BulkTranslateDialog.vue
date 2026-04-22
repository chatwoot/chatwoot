<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import categoriesAPI from 'dashboard/api/helpCenter/categories.js';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  selectedArticleIds: {
    type: Array,
    default: () => [],
  },
  allowedLocales: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['translateStarted']);

const { t } = useI18n();
const store = useStore();
const route = useRoute();

const dialogRef = ref(null);
const isSubmitting = ref(false);
const selectedLocale = ref('');
const selectedCategoryId = ref('');
const targetCategories = ref([]);
const isFetchingCategories = ref(false);

const currentLocale = computed(() => route.params.locale);

const localeOptions = computed(() => {
  return props.allowedLocales
    .filter(locale => locale.code !== currentLocale.value)
    .map(locale => ({
      value: locale.code,
      label: `${locale.name} (${locale.code})`,
    }));
});

const categoryOptions = computed(() => {
  return targetCategories.value.map(category => ({
    value: category.id,
    label: category.name,
  }));
});

const articleCount = computed(() => props.selectedArticleIds.length);

const dialogTitle = computed(() =>
  t('HELP_CENTER.ARTICLES_PAGE.BULK_TRANSLATE.TITLE', articleCount.value)
);

const description = computed(() =>
  t('HELP_CENTER.ARTICLES_PAGE.BULK_TRANSLATE.DESCRIPTION', articleCount.value)
);

const isConfirmDisabled = computed(() => {
  return (
    !selectedLocale.value || !selectedCategoryId.value || isSubmitting.value
  );
});

const fetchCategoriesForLocale = async locale => {
  if (!locale) {
    targetCategories.value = [];
    return;
  }

  isFetchingCategories.value = true;
  try {
    const { data } = await categoriesAPI.get({
      portalSlug: route.params.portalSlug,
      locale,
    });
    targetCategories.value = data.payload;
  } catch {
    targetCategories.value = [];
  } finally {
    isFetchingCategories.value = false;
  }
};

watch(selectedLocale, newLocale => {
  selectedCategoryId.value = '';
  fetchCategoriesForLocale(newLocale);
});

const resetForm = () => {
  selectedLocale.value = '';
  selectedCategoryId.value = '';
  targetCategories.value = [];
};

const onConfirm = async () => {
  if (isConfirmDisabled.value) return;

  isSubmitting.value = true;
  try {
    await store.dispatch('articles/bulkTranslate', {
      portalSlug: route.params.portalSlug,
      articleIds: props.selectedArticleIds,
      locale: selectedLocale.value,
      categoryId: selectedCategoryId.value,
    });

    useAlert(t('HELP_CENTER.ARTICLES_PAGE.BULK_TRANSLATE.API.SUCCESS_MESSAGE'));
    resetForm();
    dialogRef.value?.close();
    emit('translateStarted');
  } catch (error) {
    useAlert(
      error?.message ||
        t('HELP_CENTER.ARTICLES_PAGE.BULK_TRANSLATE.API.ERROR_MESSAGE')
    );
  } finally {
    isSubmitting.value = false;
  }
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="dialogTitle"
    :description="description"
    :confirm-button-label="
      t('HELP_CENTER.ARTICLES_PAGE.BULK_TRANSLATE.CONFIRM')
    "
    :disable-confirm-button="isConfirmDisabled"
    :is-loading="isSubmitting"
    @close="resetForm"
    @confirm="onConfirm"
  >
    <div class="flex flex-col gap-6">
      <div class="flex flex-col gap-2">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('HELP_CENTER.ARTICLES_PAGE.BULK_TRANSLATE.LOCALE_LABEL') }}
        </span>
        <ComboBox
          v-model="selectedLocale"
          :options="localeOptions"
          :placeholder="
            t('HELP_CENTER.ARTICLES_PAGE.BULK_TRANSLATE.LOCALE_PLACEHOLDER')
          "
          class="[&>div>button:not(.focused)]:!outline-n-slate-5 [&>div>button:not(.focused)]:dark:!outline-n-slate-5"
        />
      </div>
      <div class="flex flex-col gap-2">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('HELP_CENTER.ARTICLES_PAGE.BULK_TRANSLATE.CATEGORY_LABEL') }}
        </span>
        <ComboBox
          v-model="selectedCategoryId"
          :options="categoryOptions"
          :disabled="!selectedLocale || isFetchingCategories"
          :placeholder="
            t('HELP_CENTER.ARTICLES_PAGE.BULK_TRANSLATE.CATEGORY_PLACEHOLDER')
          "
          class="[&>div>button:not(.focused)]:!outline-n-slate-5 [&>div>button:not(.focused)]:dark:!outline-n-slate-5"
        />
      </div>
    </div>
  </Dialog>
</template>
