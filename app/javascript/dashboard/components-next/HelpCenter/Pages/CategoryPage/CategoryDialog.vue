<script setup>
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import CategoryForm from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryForm.vue';

const props = defineProps({
  mode: {
    type: String,
    default: 'edit',
    validator: value => ['edit', 'create'].includes(value),
  },
  selectedCategory: {
    type: Object,
    default: () => ({}),
  },
  portalName: {
    type: String,
    default: '',
  },
  activeLocaleName: {
    type: String,
    default: '',
  },
  activeLocaleCode: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();
const route = useRoute();

const handleCategory = async formData => {
  const { id, name, slug, icon, description, locale } = formData;
  const categoryData = { name, icon, slug, description };

  if (props.mode === 'create') {
    categoryData.locale = locale;
  } else {
    categoryData.id = id;
  }

  try {
    const action = props.mode === 'edit' ? 'update' : 'create';
    const payload = {
      portalSlug: route.params.portalSlug,
      categoryObj: categoryData,
    };

    if (action === 'update') {
      payload.categoryId = id;
    }

    await store.dispatch(`categories/${action}`, payload);

    const successMessage = t(
      `HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.${props.mode.toUpperCase()}.API.SUCCESS_MESSAGE`
    );
    useAlert(successMessage);

    const trackEvent =
      props.mode === 'edit'
        ? PORTALS_EVENTS.EDIT_CATEGORY
        : PORTALS_EVENTS.CREATE_CATEGORY;
    useTrack(
      trackEvent,
      props.mode === 'create'
        ? { hasDescription: Boolean(description) }
        : undefined
    );

    emit('close');
  } catch (error) {
    const errorMessage =
      error?.message ||
      t(
        `HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.${props.mode.toUpperCase()}.API.ERROR_MESSAGE`
      );
    useAlert(errorMessage);
  }
};
</script>

<template>
  <div
    class="w-[400px] absolute top-10 ltr:right-0 rtl:left-0 bg-n-alpha-3 backdrop-blur-[100px] p-6 rounded-xl border border-slate-50 dark:border-slate-900 shadow-md flex flex-col gap-6"
  >
    <h3 class="text-base font-medium text-slate-900 dark:text-slate-50">
      {{
        t(
          `HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.HEADER.${mode.toUpperCase()}`
        )
      }}
    </h3>
    <CategoryForm
      :mode="mode"
      :selected-category="selectedCategory"
      :active-locale-code="activeLocaleCode"
      :portal-name="portalName"
      :active-locale-name="activeLocaleName"
      @submit="handleCategory"
      @cancel="emit('close')"
    />
  </div>
</template>
