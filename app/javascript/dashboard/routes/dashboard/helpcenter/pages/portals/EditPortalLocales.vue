<script setup>
import LocaleItemTable from 'dashboard/routes/dashboard/helpcenter/components/PortalListItemTable.vue';
import AddLocale from 'dashboard/routes/dashboard/helpcenter/components/AddLocale.vue';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import { useAlert, useTrack } from 'dashboard/composables';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useRoute } from 'dashboard/composables/route';
import { useI18n } from 'dashboard/composables/useI18n';
import { defineComponent, ref, onBeforeMount, computed } from 'vue';

defineComponent({
  name: 'EditPortalLocales',
});

const isAddLocaleModalOpen = ref(false);

const getters = useStoreGetters();
const store = useStore();
const route = useRoute();
const track = useTrack();
const { t } = useI18n();

const currentPortalSlug = computed(() => {
  return route.params.portalSlug;
});
const currentPortal = computed(() => {
  const slug = currentPortalSlug.value;
  if (slug) return getters['portals/portalBySlug'].value(slug);

  return getters['portals/allPortals'].value[0];
});
const locales = computed(() => {
  return currentPortal.value?.config.allowed_locales;
});
const allowedLocales = computed(() => {
  return Object.keys(locales.value).map(key => {
    return locales.value[key].code;
  });
});

async function fetchPortals() {
  await store.dispatch('portals/index');
}

onBeforeMount(() => {
  fetchPortals();
});

async function updatePortalLocales({
  newAllowedLocales,
  defaultLocale,
  messageKey,
}) {
  let alertMessage = '';
  try {
    await store.dispatch('portals/update', {
      portalSlug: currentPortalSlug.value,
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
}

function changeDefaultLocale({ localeCode }) {
  updatePortalLocales({
    newAllowedLocales: allowedLocales.value,
    defaultLocale: localeCode,
    messageKey: 'CHANGE_DEFAULT_LOCALE',
  });

  track(PORTALS_EVENTS.SET_DEFAULT_LOCALE, {
    newLocale: localeCode,
    from: route.name,
  });
}
function deletePortalLocale({ localeCode }) {
  const updatedLocales = allowedLocales.value.filter(
    code => code !== localeCode
  );

  const defaultLocale = currentPortal.value?.meta.default_locale;

  updatePortalLocales({
    newAllowedLocales: updatedLocales,
    defaultLocale,
    messageKey: 'DELETE_LOCALE',
  });

  track(PORTALS_EVENTS.DELETE_LOCALE, {
    deletedLocale: localeCode,
    from: route.name,
  });
}

function closeAddLocaleModal() {
  isAddLocaleModalOpen.value = false;
}
function addLocale() {
  isAddLocaleModalOpen.value = true;
}
</script>

<template>
  <div class="w-full h-full max-w-6xl space-y-4 bg-white dark:bg-slate-900">
    <div class="flex justify-end">
      <woot-button
        variant="smooth"
        size="small"
        color-scheme="primary"
        class="header-action-buttons"
        @click="addLocale"
      >
        {{ $t('HELP_CENTER.PORTAL.PORTAL_SETTINGS.LIST_ITEM.HEADER.ADD') }}
      </woot-button>
    </div>
    <LocaleItemTable
      v-if="currentPortal"
      :locales="locales"
      :selected-locale-code="currentPortal.meta.default_locale"
      @change-default-locale="changeDefaultLocale"
      @delete="deletePortalLocale"
    />
    <woot-modal
      :show.sync="isAddLocaleModalOpen"
      :on-close="closeAddLocaleModal"
    >
      <AddLocale
        :show="isAddLocaleModalOpen"
        :portal="currentPortal"
        @cancel="closeAddLocaleModal"
      />
    </woot-modal>
  </div>
</template>
