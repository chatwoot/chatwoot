<script setup>
import { computed } from 'vue';
import LocaleCard from 'dashboard/components-next/HelpCenter/LocaleCard/LocaleCard.vue';
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

const localeActionMessages = computed(() => ({
  CHANGE_DEFAULT_LOCALE: {
    success: t('HELP_CENTER.PORTAL.CHANGE_DEFAULT_LOCALE.API.SUCCESS_MESSAGE'),
    error: t('HELP_CENTER.PORTAL.CHANGE_DEFAULT_LOCALE.API.ERROR_MESSAGE'),
  },
  DELETE_LOCALE: {
    success: t('HELP_CENTER.PORTAL.DELETE_LOCALE.API.SUCCESS_MESSAGE'),
    error: t('HELP_CENTER.PORTAL.DELETE_LOCALE.API.ERROR_MESSAGE'),
  },
  DRAFT_LOCALE: {
    success: t('HELP_CENTER.PORTAL.DRAFT_LOCALE.API.SUCCESS_MESSAGE'),
    error: t('HELP_CENTER.PORTAL.DRAFT_LOCALE.API.ERROR_MESSAGE'),
  },
  PUBLISH_LOCALE: {
    success: t('HELP_CENTER.PORTAL.PUBLISH_LOCALE.API.SUCCESS_MESSAGE'),
    error: t('HELP_CENTER.PORTAL.PUBLISH_LOCALE.API.ERROR_MESSAGE'),
  },
}));

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

    alertMessage = localeActionMessages.value[messageKey].success;
    return true;
  } catch (error) {
    alertMessage =
      error?.message || localeActionMessages.value[messageKey].error;
    return false;
  } finally {
    useAlert(alertMessage);
  }
};

const changeDefaultLocale = async ({ localeCode }) => {
  const newAllowedLocales = props.locales.map(locale => locale.code);
  const newDraftLocales = props.locales
    .filter(locale => locale.isDraft)
    .map(locale => locale.code);
  const isUpdated = await updatePortalLocales({
    newAllowedLocales,
    newDraftLocales,
    defaultLocale: localeCode,
    messageKey: 'CHANGE_DEFAULT_LOCALE',
  });
  if (!isUpdated) {
    return;
  }

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

const deletePortalLocale = async ({ localeCode }) => {
  const updatedLocales = props.locales
    .filter(locale => locale.code !== localeCode)
    .map(locale => locale.code);
  const updatedDraftLocales = props.locales
    .filter(locale => locale.code !== localeCode && locale.isDraft)
    .map(locale => locale.code);

  const defaultLocale = props.portal.meta.default_locale;

  const isUpdated = await updatePortalLocales({
    newAllowedLocales: updatedLocales,
    newDraftLocales: updatedDraftLocales,
    defaultLocale,
    messageKey: 'DELETE_LOCALE',
  });
  if (!isUpdated) {
    return;
  }

  await updateLastActivePortal(localeCode);

  useTrack(PORTALS_EVENTS.DELETE_LOCALE, {
    deletedLocale: localeCode,
    from: route.name,
  });
};

const updateDraftLocales = async ({ localeCode, shouldDraft, messageKey }) => {
  const newAllowedLocales = props.locales.map(locale => locale.code);
  const currentDraftLocales = props.locales
    .filter(locale => locale.isDraft)
    .map(locale => locale.code);
  const newDraftLocales = shouldDraft
    ? [...new Set([...currentDraftLocales, localeCode])]
    : currentDraftLocales.filter(locale => locale !== localeCode);

  return updatePortalLocales({
    newAllowedLocales,
    newDraftLocales,
    defaultLocale: props.portal.meta.default_locale,
    messageKey,
  });
};

const moveLocaleToDraft = async ({ localeCode }) => {
  const isUpdated = await updateDraftLocales({
    localeCode,
    shouldDraft: true,
    messageKey: 'DRAFT_LOCALE',
  });
  if (!isUpdated) {
    return;
  }

  useTrack(PORTALS_EVENTS.DRAFT_LOCALE, {
    locale: localeCode,
    from: route.name,
  });
};

const publishLocale = async ({ localeCode }) => {
  const isUpdated = await updateDraftLocales({
    localeCode,
    shouldDraft: false,
    messageKey: 'PUBLISH_LOCALE',
  });
  if (!isUpdated) {
    return;
  }

  useTrack(PORTALS_EVENTS.PUBLISH_LOCALE, {
    locale: localeCode,
    from: route.name,
  });
};

const handleAction = ({ action }, localeCode) => {
  if (action === 'change-default') {
    changeDefaultLocale({ localeCode: localeCode });
  } else if (action === 'move-to-draft') {
    moveLocaleToDraft({ localeCode: localeCode });
  } else if (action === 'publish-locale') {
    publishLocale({ localeCode: localeCode });
  } else if (action === 'delete') {
    deletePortalLocale({ localeCode: localeCode });
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
  </ul>
</template>
