<script setup>
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@chatwoot/pico-search';
import MacrosTableRow from './MacrosTableRow.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  useStoreGetters,
  useStore,
  useMapGetter,
} from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import { BaseTable } from 'dashboard/components-next/table';
import { useAdmin } from 'dashboard/composables/useAdmin';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();
const { isAdmin } = useAdmin();
const currentUser = useMapGetter('getCurrentUser');

const showDeleteConfirmationPopup = ref(false);
const selectedMacro = ref({});
const searchQuery = ref('');
const visibilityFilter = ref('all');
const selectedFolder = ref(null);

const records = computed(() => getters['macros/getMacros'].value);
const uiFlags = computed(() => getters['macros/getUIFlags'].value);

const folders = computed(() => {
  const set = new Set();
  records.value.forEach(item => {
    if (item.folder) set.add(item.folder);
  });
  return [...set].sort((a, b) => a.localeCompare(b));
});

const visibilityFilteredRecords = computed(() => {
  const userId = currentUser.value?.id;
  if (visibilityFilter.value === 'mine') {
    return records.value.filter(item => item.created_by_id === userId);
  }
  if (visibilityFilter.value === 'global') {
    return records.value.filter(item => item.visibility === 'global');
  }
  return records.value;
});

const folderFilteredRecords = computed(() => {
  if (selectedFolder.value === null) return visibilityFilteredRecords.value;
  if (selectedFolder.value === '') {
    return visibilityFilteredRecords.value.filter(item => !item.folder);
  }
  return visibilityFilteredRecords.value.filter(
    item => item.folder === selectedFolder.value
  );
});

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim();
  const base = folderFilteredRecords.value;
  if (!query) return base;
  return picoSearch(base, query, ['name', 'folder']);
});

const sortedRecords = computed(() => {
  return [...filteredRecords.value].sort((a, b) => {
    const folderA = (a.folder || '').trim();
    const folderB = (b.folder || '').trim();
    if (!folderA && folderB) return 1;
    if (folderA && !folderB) return -1;
    const folderCompare = folderA.localeCompare(folderB);
    if (folderCompare !== 0) return folderCompare;
    return (a.name || '').localeCompare(b.name || '');
  });
});

const deleteMessage = computed(() => ` ${selectedMacro.value.name}?`);

onMounted(() => {
  store.dispatch('macros/get');
});

const deleteMacro = async id => {
  try {
    await store.dispatch('macros/delete', id);
    useAlert(t('MACROS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('MACROS.DELETE.API.ERROR_MESSAGE'));
  }
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  selectedMacro.value = response;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const confirmDeletion = () => {
  closeDeletePopup();
  deleteMacro(selectedMacro.value.id);
};

const visibilityFilters = computed(() => [
  { key: 'all', label: t('MACROS.FILTER_VISIBILITY.ALL') },
  { key: 'mine', label: t('MACROS.FILTER_VISIBILITY.MINE') },
  { key: 'global', label: t('MACROS.FILTER_VISIBILITY.GLOBAL') },
]);

const chipClass = active =>
  active
    ? 'bg-n-brand text-white border-n-brand'
    : 'bg-n-alpha-black2 text-n-slate-12 border-n-weak hover:bg-n-alpha-2';

const tableHeaders = computed(() => {
  return [
    t('MACROS.LIST.TABLE_HEADER.NAME'),
    t('MACROS.LIST.TABLE_HEADER.FOLDER'),
    t('MACROS.LIST.TABLE_HEADER.CREATED BY'),
    t('MACROS.LIST.TABLE_HEADER.LAST_UPDATED_BY'),
    t('MACROS.LIST.TABLE_HEADER.VISIBILITY'),
    t('MACROS.LIST.TABLE_HEADER.ACTIONS'),
  ];
});
</script>

<template>
  <SettingsLayout
    :no-records-message="$t('MACROS.LIST.404')"
    :no-records-found="!records.length"
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('MACROS.LOADING')"
    feature-name="macros"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('MACROS.HEADER')"
        :description="$t('MACROS.DESCRIPTION')"
        :link-text="$t('MACROS.LEARN_MORE')"
        :search-placeholder="$t('MACROS.SEARCH_PLACEHOLDER')"
        feature-name="macros"
      >
        <template v-if="records?.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ $t('MACROS.COUNT', { n: records.length }) }}
          </span>
        </template>
        <template #actions>
          <router-link :to="{ name: 'macros_new' }">
            <Button :label="$t('MACROS.HEADER_BTN_TXT')" size="sm" />
          </router-link>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div v-if="records.length" class="flex flex-col gap-3 mb-4">
        <div class="flex flex-wrap gap-2">
          <button
            v-for="filter in visibilityFilters"
            :key="filter.key"
            type="button"
            class="px-2.5 py-1 text-xs rounded-lg border border-solid transition-colors"
            :class="chipClass(visibilityFilter === filter.key)"
            @click="visibilityFilter = filter.key"
          >
            {{ filter.label }}
          </button>
        </div>
        <div
          v-if="folders.length || records.some(r => !r.folder)"
          class="flex flex-wrap gap-2"
        >
          <button
            type="button"
            class="px-2.5 py-1 text-xs rounded-lg border border-solid transition-colors"
            :class="chipClass(selectedFolder === null)"
            @click="selectedFolder = null"
          >
            {{ $t('MACROS.ALL_FOLDERS') }}
          </button>
          <button
            v-for="folder in folders"
            :key="folder"
            type="button"
            class="px-2.5 py-1 text-xs rounded-lg border border-solid transition-colors"
            :class="chipClass(selectedFolder === folder)"
            @click="selectedFolder = folder"
          >
            {{ folder }}
          </button>
          <button
            v-if="records.some(r => !r.folder)"
            type="button"
            class="px-2.5 py-1 text-xs rounded-lg border border-solid transition-colors"
            :class="chipClass(selectedFolder === '')"
            @click="selectedFolder = ''"
          >
            {{ $t('MACROS.UNCATEGORIZED') }}
          </button>
        </div>
      </div>

      <div
        v-if="!filteredRecords.length"
        class="px-4 py-8 text-center text-n-slate-11"
      >
        {{
          searchQuery || visibilityFilter !== 'all' || selectedFolder !== null
            ? $t('MACROS.NO_RESULTS')
            : $t('MACROS.LIST.404')
        }}
      </div>
      <BaseTable
        v-else
        class="w-full"
        :headers="tableHeaders"
        :items="sortedRecords"
        :no-data-message="$t('MACROS.LIST.404')"
      >
        <template #row="{ items }">
          <MacrosTableRow
            v-for="macro in items"
            :key="macro.id"
            :macro="macro"
            :can-manage-public-macros="isAdmin"
            @delete="openDeletePopup(macro)"
          />
        </template>
      </BaseTable>
      <woot-delete-modal
        v-model:show="showDeleteConfirmationPopup"
        :on-close="closeDeletePopup"
        :on-confirm="confirmDeletion"
        :title="$t('LABEL_MGMT.DELETE.CONFIRM.TITLE')"
        :message="$t('MACROS.DELETE.CONFIRM.MESSAGE')"
        :message-value="deleteMessage"
        :confirm-text="$t('MACROS.DELETE.CONFIRM.YES')"
        :reject-text="$t('MACROS.DELETE.CONFIRM.NO')"
      />
    </template>
  </SettingsLayout>
</template>
