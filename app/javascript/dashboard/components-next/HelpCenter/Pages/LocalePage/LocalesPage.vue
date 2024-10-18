<script setup>
import { computed, ref } from 'vue';
import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
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
          icon="add"
          size="sm"
          @click="openAddLocaleDialog"
        />
      </div>
    </template>
    <template #content>
      <LocaleList :locales="locales" :portal="portal" />
    </template>
    <AddLocaleDialog ref="addLocaleDialogRef" :portal="portal" />
  </HelpCenterLayout>
</template>
