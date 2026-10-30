<script setup>
import { ref } from 'vue';
import LocaleCard from 'dashboard/components-next/HelpCenter/LocaleCard/LocaleCard.vue';
import LocaleContentDialog from 'dashboard/components-next/HelpCenter/Pages/LocalePage/LocaleContentDialog.vue';
import PopularContentDialog from 'dashboard/components-next/HelpCenter/Pages/LocalePage/PopularContentDialog.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

const props = defineProps({
  locales: {
    type: Array,
    required: true,
  },
  portal: {
    type: Object,
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();
const route = useRoute();
const { uiSettings, updateUISettings } = useUISettings();

const contentDialogRef = ref(null);
const popularContentDialogRef = ref(null);
const deleteDialogRef = ref(null);
const localeToDelete = ref(null);

const isLocaleDefault = code => {
  return props.portal?.meta?.default_locale === code;
};

const updatePortalLocales = async ({
  newAllowedLocales,
  newDraftLocales,
  defaultLocale,
  messageKey,
}) => {
  let alertMessage = '';
  try {
    await store.dispatch('portals/update', {
      portalSlug: props.portal.slug,
      config: {
        default_locale: defaultLocale,
        allowed_locales: newAllowedLocales,
        draft_locales: newDraftLocales,
      },
    });

    alertMessage = t(`HELP_CENTER.PORTAL.${messageKey}.API.SUCCESS_MESSAGE`);
  } catch (error) {
    alertMessage =
      error?.message || t(`HELP_CENTER.PORTAL.${messageKey}.API.ERROR_MESSAGE`);
  } finally {
    useAlert(alertMessage);
  }
};

const changeDefaultLocale = ({ localeCode }) => {
  const newAllowedLocales = props.locales.map(locale => locale.code);
  const newDraftLocales = props.locales
    .filter(locale => locale.isDraft)
    .map(locale => locale.code);
  updatePortalLocales({
    newAllowedLocales,
    newDraftLocales,
    defaultLocale: localeCode,
    messageKey: 'CHANGE_DEFAULT_LOCALE',
  });
  useTrack(PORTALS_EVENTS.SET_DEFAULT_LOCALE, {
    newLocale: localeCode,
    from: route.name,
  });
};

const updateLastActivePortal = async localeCode => {
  const { last_active_locale_code: lastActiveLocaleCode } =
    uiSettings.value || {};
  const defaultLocale = props.portal.meta.default_locale;

  // Update UI settings only if deleting locale matches the last active locale in UI settings.
  if (localeCode === lastActiveLocaleCode) {
    await updateUISettings({
      last_active_locale_code: defaultLocale,
    });
  }
};

const deletePortalLocale = async () => {
  const localeCode = localeToDelete.value.code;
  deleteDialogRef.value.close();

  try {
    await store.dispatch('portals/removeLocale', {
      portalSlug: props.portal.slug,
      locale: localeCode,
    });
    useAlert(t('HELP_CENTER.PORTAL.DELETE_LOCALE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(
      error?.message || t('HELP_CENTER.PORTAL.DELETE_LOCALE.API.ERROR_MESSAGE')
    );
  }

  await updateLastActivePortal(localeCode);

  useTrack(PORTALS_EVENTS.DELETE_LOCALE, {
    deletedLocale: localeCode,
    from: route.name,
  });
};

const openDeleteDialog = localeCode => {
  localeToDelete.value = props.locales.find(
    locale => locale.code === localeCode
  );
  deleteDialogRef.value.open();
};

const updateDraftLocales = async ({ localeCode, shouldDraft, messageKey }) => {
  const newAllowedLocales = props.locales.map(locale => locale.code);
  const currentDraftLocales = props.locales
    .filter(locale => locale.isDraft)
    .map(locale => locale.code);
  const newDraftLocales = shouldDraft
    ? [...new Set([...currentDraftLocales, localeCode])]
    : currentDraftLocales.filter(locale => locale !== localeCode);

  await updatePortalLocales({
    newAllowedLocales,
    newDraftLocales,
    defaultLocale: props.portal.meta.default_locale,
    messageKey,
  });
};

const moveLocaleToDraft = async ({ localeCode }) => {
  await updateDraftLocales({
    localeCode,
    shouldDraft: true,
    messageKey: 'DRAFT_LOCALE',
  });
};

const publishLocale = async ({ localeCode }) => {
  await updateDraftLocales({
    localeCode,
    shouldDraft: false,
    messageKey: 'PUBLISH_LOCALE',
  });
};

const handleAction = ({ action }, localeCode) => {
  if (action === 'change-default') {
    changeDefaultLocale({ localeCode: localeCode });
  } else if (action === 'move-to-draft') {
    moveLocaleToDraft({ localeCode: localeCode });
  } else if (action === 'publish-locale') {
    publishLocale({ localeCode: localeCode });
  } else if (action === 'customize-content') {
    contentDialogRef.value.openForLocale(localeCode);
  } else if (action === 'select-popular-content') {
    popularContentDialogRef.value.openForLocale(localeCode);
  } else if (action === 'delete') {
    openDeleteDialog(localeCode);
  }
};
</script>

<template>
  <ul role="list" class="w-full h-full space-y-4">
    <LocaleCard
      v-for="(locale, index) in locales"
      :key="index"
      :locale="locale.name"
      :is-default="isLocaleDefault(locale.code)"
      :is-draft="locale.isDraft"
      :locale-code="locale.code"
      :article-count="locale.articlesCount || 0"
      :category-count="locale.categoriesCount || 0"
      @action="handleAction($event, locale.code)"
    />
    <LocaleContentDialog ref="contentDialogRef" :portal="portal" />
    <PopularContentDialog ref="popularContentDialogRef" :portal="portal" />
    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="
        t('HELP_CENTER.PORTAL.DELETE_LOCALE.DIALOG.TITLE', {
          locale: localeToDelete?.name,
        })
      "
      :description="
        t('HELP_CENTER.PORTAL.DELETE_LOCALE.DIALOG.DESCRIPTION', {
          articles: t(
            'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.ARTICLES_COUNT',
            localeToDelete?.articlesCount || 0
          ),
          categories: t(
            'HELP_CENTER.LOCALES_PAGE.LOCALE_CARD.CATEGORIES_COUNT',
            localeToDelete?.categoriesCount || 0
          ),
        })
      "
      :confirm-button-label="
        t('HELP_CENTER.PORTAL.DELETE_LOCALE.DIALOG.CONFIRM')
      "
      @confirm="deletePortalLocale"
    />
  </ul>
</template>
