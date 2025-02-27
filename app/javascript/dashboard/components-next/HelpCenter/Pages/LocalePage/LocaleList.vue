<script setup>
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

const isLocaleDefault = code => {
  return props.portal?.meta?.default_locale === code;
};

const updatePortalLocales = async ({
  newAllowedLocales,
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
  updatePortalLocales({
    newAllowedLocales,
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

const deletePortalLocale = async ({ localeCode }) => {
  const updatedLocales = props.locales
    .filter(locale => locale.code !== localeCode)
    .map(locale => locale.code);

  const defaultLocale = props.portal.meta.default_locale;

  await updatePortalLocales({
    newAllowedLocales: updatedLocales,
    defaultLocale,
    messageKey: 'DELETE_LOCALE',
  });

  await updateLastActivePortal(localeCode);

  useTrack(PORTALS_EVENTS.DELETE_LOCALE, {
    deletedLocale: localeCode,
    from: route.name,
  });
};

const handleAction = ({ action }, localeCode) => {
  if (action === 'change-default') {
    changeDefaultLocale({ localeCode: localeCode });
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
      :locale-code="locale.code"
      :article-count="locale.articlesCount || 0"
      :category-count="locale.categoriesCount || 0"
      @action="handleAction($event, locale.code)"
    />
  </ul>
</template>
