<script setup>
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { useRoute, useRouter } from 'vue-router';
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
const router = useRouter();

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

    // Update categorySlug parameter in the URL if it's an edit operation
    if (props.mode === 'edit' && route.params.categorySlug !== slug) {
      await router.replace({
        name: route.name,
        params: { ...route.params, categorySlug: slug },
      });
    }

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
    class="w-[400px] absolute top-10 right-0 bg-white dark:bg-slate-800 p-6 rounded-xl border border-slate-50 dark:border-slate-800/50 shadow-md flex flex-col gap-6"
  >
    <h3 class="text-base font-medium text-slate-900 dark:text-slate-50">
      {{
        t(
          `HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.HEADER.${mode.toUpperCase()}`
        )
      }}
    </h3>
    <div class="flex flex-col gap-4">
      <div
        class="flex items-center justify-start gap-8 px-4 py-2 border rounded-lg border-slate-50 dark:border-slate-700/50"
      >
        <div class="flex flex-col items-start w-full gap-2 py-2">
          <span class="text-sm font-medium text-slate-700 dark:text-slate-300">
            {{ t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.HEADER.PORTAL') }}
          </span>
          <span class="text-sm text-slate-800 dark:text-slate-100">
            {{ portalName }}
          </span>
        </div>
        <div class="justify-start w-px h-10 bg-slate-50 dark:bg-slate-700/50" />
        <div class="flex flex-col w-full gap-2 py-2">
          <span class="text-sm font-medium text-slate-700 dark:text-slate-300">
            {{ t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.HEADER.LOCALE') }}
          </span>
          <span
            :title="`${activeLocaleName} (${activeLocaleCode})`"
            class="text-sm line-clamp-1 text-slate-800 dark:text-slate-100"
          >
            {{ `${activeLocaleName} (${activeLocaleCode})` }}
          </span>
        </div>
      </div>
      <CategoryForm
        :mode="mode"
        :selected-category="selectedCategory"
        :active-locale-code="activeLocaleCode"
        @submit="handleCategory"
        @cancel="emit('close')"
      />
    </div>
  </div>
</template>

<style scoped lang="scss">
.emoji-dialog::before {
  @apply hidden;
}
</style>
