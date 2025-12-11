<script setup>
import { computed, ref } from 'vue';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useI18n } from 'vue-i18n';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
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
  <HelpCenterLayout
    :header-title="t('HELP_CENTER.LOCALES_PAGE.HEADER')"
    :create-button-label="t('HELP_CENTER.LOCALES_PAGE.NEW_LOCALE_BUTTON_TEXT')"
    :show-pagination-footer="false"
    @create="openAddLocaleDialog"
  >
    <template #header-actions>
      <div class="flex items-start h-8 ltr:ml-1 rtl:mr-1">
        <span class="text-sm font-medium text-n-slate-12">
          {{ $t('HELP_CENTER.LOCALES_PAGE.LOCALES_COUNT', localeCount) }}
        </span>
      </div>
    </template>
    <template #content>
      <div
        v-if="isSwitchingPortal"
        class="flex items-center justify-center py-10 text-n-slate-11"
      >
        <Spinner />
      </div>
      <LocaleList v-else :locales="locales" :portal="portal" />
    </template>
    <AddLocaleDialog ref="addLocaleDialogRef" :portal="portal" />
  </HelpCenterLayout>
</template>
