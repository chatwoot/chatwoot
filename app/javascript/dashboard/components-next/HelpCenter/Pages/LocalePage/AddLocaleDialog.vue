<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import allLocales from 'shared/constants/locales.js';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  portal: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();
const store = useStore();
const route = useRoute();

const dialogRef = ref(null);
const isUpdating = ref(false);

const selectedLocale = ref('');

const addedLocales = computed(() => {
  const { allowed_locales: allowedLocales = [] } = props.portal?.config || {};
  return allowedLocales.map(locale => locale.code);
});

const locales = computed(() => {
  return Object.keys(allLocales)
    .map(key => {
      return {
        value: key,
        label: `${allLocales[key]} (${key})`,
      };
    })
    .filter(locale => !addedLocales.value.includes(locale.value));
});

const onCreate = async () => {
  if (!selectedLocale.value) return;

  isUpdating.value = true;
  const updatedLocales = [...addedLocales.value, selectedLocale.value];

  try {
    await store.dispatch('portals/update', {
      portalSlug: props.portal.slug,
      config: { allowed_locales: updatedLocales },
    });

    useTrack(PORTALS_EVENTS.CREATE_LOCALE, {
      localeAdded: selectedLocale.value,
      totalLocales: updatedLocales.length,
      from: route.name,
    });

    dialogRef.value?.close();
    useAlert(
      t('HELP_CENTER.LOCALES_PAGE.ADD_LOCALE_DIALOG.API.SUCCESS_MESSAGE')
    );
  } catch (error) {
    useAlert(
      error?.message ||
        t('HELP_CENTER.LOCALES_PAGE.ADD_LOCALE_DIALOG.API.ERROR_MESSAGE')
    );
  } finally {
    isUpdating.value = false;
  }
};

// Expose the dialogRef to the parent component
defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="t('HELP_CENTER.LOCALES_PAGE.ADD_LOCALE_DIALOG.TITLE')"
    :description="t('HELP_CENTER.LOCALES_PAGE.ADD_LOCALE_DIALOG.DESCRIPTION')"
    @confirm="onCreate"
  >
    <div class="flex flex-col gap-6">
      <ComboBox
        v-model="selectedLocale"
        :options="locales"
        :placeholder="
          t('HELP_CENTER.LOCALES_PAGE.ADD_LOCALE_DIALOG.COMBOBOX.PLACEHOLDER')
        "
        class="[&>div>button]:!border-n-slate-5 [&>div>button]:dark:!border-n-slate-5"
      />
    </div>
  </Dialog>
</template>
