<script setup>
import HelpCenterLayout from 'dashboard/playground/HelpCenter/components/HelpCenterLayout.vue';
import ButtonV4 from 'dashboard/playground/components/Button.vue';
import LocaleList from 'dashboard/playground/HelpCenter/components/LocaleList.vue';

const localeCount = 5;

const locales = [
  { variant: 'Default', name: 'English (en-US)', isDefault: true },
  { variant: 'Not Default', name: 'Spanish (es-ES)', isDefault: false },
  { variant: 'Not Default', name: 'English (en-UK)', isDefault: false },
  { variant: 'Not Default', name: 'Malay (ms-MY)', isDefault: false },
  { variant: 'Not Default', name: 'Malayalam (ml-IN)', isDefault: false },
  { variant: 'Not Default', name: 'Hindi (hi-IN)', isDefault: false },
  { variant: 'Not Default', name: 'Jamaican (en-JM)', isDefault: false },
  { variant: 'Not Default', name: 'Amharic (am-AM)', isDefault: false },
  { variant: 'Not Default', name: 'Arabic (ar-AR)', isDefault: false },
  { variant: 'Not Default', name: 'Somali (so-SO)', isDefault: false },
];

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

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <HelpCenterLayout :show-pagination-footer="false">
    <template #header-actions>
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-4">
          <span class="text-sm font-medium text-slate-800 dark:text-slate-100">
            {{ localeCount }} locales
          </span>
        </div>
        <ButtonV4 label="New locale" icon="add" size="sm" />
      </div>
    </template>
    <template #content>
      <LocaleList :locales="locales" />
    </template>
  </HelpCenterLayout>
</template>
