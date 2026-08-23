<script setup>
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@chatwoot/pico-search';
import MacroListItem from './MacroListItem.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsFilterDropdown from '../components/SettingsFilterDropdown.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  useStoreGetters,
  useStore,
  useMapGetter,
} from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
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
const selectedFolder = ref('all');
const duplicatingId = ref(null);

const records = computed(() => getters['macros/getMacros'].value);
const uiFlags = computed(() => getters['macros/getUIFlags'].value);

const folders = computed(() => {
  const set = new Set();
  records.value.forEach(item => {
    if (item.folder) set.add(item.folder);
  });
  return [...set].sort((a, b) => a.localeCompare(b));
});

const hasUncategorized = computed(() => records.value.some(r => !r.folder));

const visibilityOptions = computed(() => [
  { value: 'all', label: t('MACROS.FILTER_VISIBILITY.ALL') },
  { value: 'mine', label: t('MACROS.FILTER_VISIBILITY.MINE') },
  { value: 'global', label: t('MACROS.FILTER_VISIBILITY.GLOBAL') },
]);

const folderOptions = computed(() => {
  const options = [
    { value: 'all', label: t('MACROS.ALL_FOLDERS') },
    ...folders.value.map(folder => ({ value: folder, label: folder })),
  ];
  if (hasUncategorized.value) {
    options.push({
      value: '',
      label: t('MACROS.UNCATEGORIZED'),
    });
  }
  return options;
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
  if (selectedFolder.value === 'all') return visibilityFilteredRecords.value;
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

const uniqueCopyName = (baseName, existingNames) => {
  const taken = new Set(existingNames);
  let candidate = `${baseName} (copy)`;
  let n = 2;
  while (taken.has(candidate)) {
    candidate = `${baseName} (copy ${n})`;
    n += 1;
  }
  return candidate;
};

const duplicateMacro = async macro => {
  duplicatingId.value = macro.id;
  try {
    const visibility =
      macro.visibility === 'global' && !isAdmin.value
        ? 'personal'
        : macro.visibility || 'personal';

    await store.dispatch('macros/create', {
      name: uniqueCopyName(
        macro.name,
        records.value.map(item => item.name)
      ),
      folder: macro.folder || '',
      visibility,
      actions: (macro.actions || []).map(({ action_name, action_params }) => ({
        action_name,
        action_params: action_params ?? [],
      })),
    });
    useAlert(t('MACROS.DUPLICATE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('MACROS.DUPLICATE.API.ERROR_MESSAGE'));
  } finally {
    duplicatingId.value = null;
  }
};
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
        <template v-if="records.length" #tabs>
          <div class="flex items-center gap-2">
            <SettingsFilterDropdown
              v-model="visibilityFilter"
              :options="visibilityOptions"
              icon="i-lucide-eye"
              action-key="visibility"
            />
            <SettingsFilterDropdown
              v-if="folders.length || hasUncategorized"
              v-model="selectedFolder"
              :options="folderOptions"
              icon="i-lucide-tags"
              action-key="folder"
            />
          </div>
        </template>
        <template v-if="filteredRecords.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ $t('MACROS.COUNT', { n: filteredRecords.length }) }}
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
      <div
        v-if="!filteredRecords.length"
        class="flex items-center justify-center p-8"
      >
        <span class="text-base text-n-slate-11">
          {{
            searchQuery ||
            visibilityFilter !== 'all' ||
            selectedFolder !== 'all'
              ? $t('MACROS.NO_RESULTS')
              : $t('MACROS.LIST.404')
          }}
        </span>
      </div>
      <div v-else class="border-t divide-y divide-n-weak border-n-weak">
        <MacroListItem
          v-for="macro in sortedRecords"
          :key="macro.id"
          :macro="macro"
          :can-manage-public-macros="isAdmin"
          :is-duplicating="duplicatingId === macro.id"
          @delete="openDeletePopup(macro)"
          @duplicate="duplicateMacro(macro)"
        />
      </div>
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
