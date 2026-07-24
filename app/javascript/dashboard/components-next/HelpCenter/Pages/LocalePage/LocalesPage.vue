<script setup>
import { computed, ref } from 'vue';
import { useMapGetter } from 'dashboard/composables/store.js';

import { useI18n } from 'vue-i18n';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
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
const searchQuery = ref('');

const isSwitchingPortal = useMapGetter('portals/isSwitchingPortal');

const openAddLocaleDialog = () => {
  addLocaleDialogRef.value.dialogRef.open();
};

const localeCount = computed(() => props.locales?.length);

const filteredLocales = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return props.locales;
  return props.locales.filter(
    locale =>
      locale.name?.toLowerCase().includes(query) ||
      locale.code?.toLowerCase().includes(query)
  );
});

const isSearching = computed(() => searchQuery.value.trim().length > 0);
const hasResults = computed(() => filteredLocales.value?.length > 0);
</script>

<template>
  <HelpCenterLayout :show-pagination-footer="false">
    <template #header-actions>
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-4">
          <span class="text-sm font-medium text-n-slate-12">
            {{ $t('HELP_CENTER.LOCALES_PAGE.LOCALES_COUNT', localeCount) }}
          </span>
        </div>
        <div class="flex items-center gap-2">
          <Input
            v-model="searchQuery"
            :placeholder="$t('HELP_CENTER.LOCALES_PAGE.SEARCH_PLACEHOLDER')"
            type="search"
            size="sm"
            class="w-48"
          />
          <Button
            :label="$t('HELP_CENTER.LOCALES_PAGE.NEW_LOCALE_BUTTON_TEXT')"
            icon="i-lucide-plus"
            size="sm"
            @click="openAddLocaleDialog"
          />
        </div>
      </div>
    </template>
    <template #content>
      <div
        v-if="isSwitchingPortal"
        class="flex items-center justify-center py-10 text-n-slate-11"
      >
        <Spinner />
      </div>
      <EmptyStateLayout
        v-else-if="isSearching && !hasResults"
        :title="t('HELP_CENTER.LOCALES_PAGE.SEARCH_EMPTY_STATE.TITLE')"
        :subtitle="t('HELP_CENTER.LOCALES_PAGE.SEARCH_EMPTY_STATE.SUBTITLE')"
        :show-backdrop="false"
      />
      <LocaleList v-else :locales="filteredLocales" :portal="portal" />
    </template>
    <AddLocaleDialog ref="addLocaleDialogRef" :portal="portal" />
  </HelpCenterLayout>
</template>
