<script setup>
import { computed } from 'vue';
import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import LocaleList from 'dashboard/components-next/HelpCenter/Pages/LocalePage/LocaleList.vue';

const props = defineProps({
  locales: {
    type: Array,
    required: true,
  },
});

const localeCount = computed(() => props.locales?.length);

// TODO: remove comments
// eslint-disable-next-line no-unused-vars
const handleTabChange = tab => {
  // TODO: Implement tab change logic
};
// eslint-disable-next-line no-unused-vars
const handlePageChange = page => {
  // TODO: Implement page change logic
};
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
        />
      </div>
    </template>
    <template #content>
      <LocaleList :locales="locales" />
    </template>
  </HelpCenterLayout>
</template>
