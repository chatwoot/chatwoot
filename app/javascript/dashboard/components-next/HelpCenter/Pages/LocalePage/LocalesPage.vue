<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import LocaleList from 'dashboard/components-next/HelpCenter/Pages/LocalePage/LocaleList.vue';
import AddLocaleDialog from 'dashboard/components-next/HelpCenter/Pages/LocalePage/AddLocaleDialog.vue';

const props = defineProps({
  locales: {
    type: Array,
    required: true,
  },
  portal: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();

const addLocaleDialogRef = ref(null);

const isSwitchingPortal = useMapGetter('portals/isSwitchingPortal');

const openAddLocaleDialog = () => {
  addLocaleDialogRef.value.dialogRef.open();
};

const localeCount = computed(() => props.locales?.length);
</script>

<template>
  <HelpCenterLayout :show-pagination-footer="false">
    <template #header-actions>
      <div
        class="w-full rounded-xl border border-outline-variant/5 bg-surface-container-low p-4 shadow-sm"
      >
        <div class="flex flex-wrap items-center justify-between gap-3">
          <span class="text-sm font-medium text-on-surface">
            {{ t('HELP_CENTER.LOCALES_PAGE.LOCALES_COUNT', localeCount) }}
          </span>
          <Button
            solid
            teal
            sm
            :label="t('HELP_CENTER.LOCALES_PAGE.NEW_LOCALE_BUTTON_TEXT')"
            icon="i-lucide-plus"
            class="shrink-0 font-semibold"
            @click="openAddLocaleDialog"
          />
        </div>
      </div>
    </template>
    <template #content>
      <div
        v-if="isSwitchingPortal"
        class="flex items-center justify-center gap-2 py-10 text-on-surface-variant"
      >
        <Spinner />
      </div>
      <div
        v-else
        class="help-center-locales-page flex w-full flex-col space-y-6 text-on-surface antialiased selection:bg-secondary/30"
      >
        <header class="space-y-1">
          <h1 class="text-3xl font-bold tracking-tight text-on-surface">
            {{ t('HELP_CENTER.LOCALES_PAGE.PAGE_TITLE') }}
          </h1>
          <p class="mb-0 text-lg text-on-primary-container">
            {{ t('HELP_CENTER.LOCALES_PAGE.PAGE_SUBTITLE') }}
          </p>
        </header>
        <LocaleList :locales="locales" :portal="portal" />
      </div>
    </template>
    <AddLocaleDialog ref="addLocaleDialogRef" :portal="portal" />
  </HelpCenterLayout>
</template>
