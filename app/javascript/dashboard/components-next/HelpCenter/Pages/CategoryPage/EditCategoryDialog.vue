<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import CategoryForm from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryForm.vue';

const props = defineProps({
  selectedCategory: {
    type: Object,
    default: () => ({}),
  },
  allowedLocales: {
    type: Array,
    default: () => [],
  },
});

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const getters = useStoreGetters();

const dialogRef = ref(null);
const categoryFormRef = ref(null);

const isUpdatingCategory = computed(() => {
  const id = props.selectedCategory?.id;
  if (id) return getters['categories/uiFlags'].value(id)?.isUpdating;

  return false;
});

const isInvalidForm = computed(() => {
  if (!categoryFormRef.value) return false;
  const { isSubmitDisabled } = categoryFormRef.value;
  return isSubmitDisabled;
});

const activeLocale = computed(() => {
  return props.allowedLocales.find(
    locale => locale.code === route.params.locale
  );
});

const activeLocaleName = computed(() => activeLocale.value?.name ?? '');
const activeLocaleCode = computed(() => activeLocale.value?.code ?? '');

const onUpdateCategory = async () => {
  if (!categoryFormRef.value) return;
  const { state } = categoryFormRef.value;
  const { id, name, slug, icon, description } = state;
  const categoryData = { name, icon, slug, description };
  categoryData.id = id;

  try {
    const payload = {
      portalSlug: route.params.portalSlug,
      categoryObj: categoryData,
      categoryId: id,
    };

    await store.dispatch(`categories/update`, payload);

    const successMessage = t(
      `HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.EDIT.API.SUCCESS_MESSAGE`
    );
    useAlert(successMessage);
    dialogRef.value.close();

    const trackEvent = PORTALS_EVENTS.EDIT_CATEGORY;
    useTrack(trackEvent, { hasDescription: Boolean(description) });
  } catch (error) {
    const errorMessage =
      error?.message ||
      t(`HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.EDIT.API.ERROR_MESSAGE`);
    useAlert(errorMessage);
  }
};

// Expose the dialogRef to the parent component
defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.HEADER.EDIT')"
    :description="
      t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.HEADER.DESCRIPTION')
    "
    :is-loading="isUpdatingCategory"
    :disable-confirm-button="isUpdatingCategory || isInvalidForm"
    @confirm="onUpdateCategory"
  >
    <CategoryForm
      ref="categoryFormRef"
      mode="edit"
      :selected-category="selectedCategory"
      :active-locale-code="activeLocaleCode"
      :portal-name="route.params.portalSlug"
      :active-locale-name="activeLocaleName"
      :show-action-buttons="false"
    />
  </Dialog>
</template>
