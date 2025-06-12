<script setup>
import { computed, ref } from 'vue';
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
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-4">
          <span class="text-sm font-medium text-slate-800 dark:text-slate-100">
            {{ $t('HELP_CENTER.LOCALES_PAGE.LOCALES_COUNT', localeCount) }}
          </span>
        </div>
        <Button
          :label="$t('HELP_CENTER.LOCALES_PAGE.NEW_LOCALE_BUTTON_TEXT')"
          icon="i-lucide-plus"
          size="sm"
          @click="openAddLocaleDialog"
        />
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
