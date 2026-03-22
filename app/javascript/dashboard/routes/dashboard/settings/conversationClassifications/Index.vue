<script setup>
import { computed, onBeforeMount, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useStoreGetters } from 'dashboard/composables/store';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

const store = useStore();
const getters = useStoreGetters();
const { t } = useI18n();
const route = useRoute();

const newName = ref('');
const editingId = ref(null);
const editingName = ref('');
const loading = ref({});

const classifications = computed(
  () => getters['conversationClassifications/getAll'].value
);
const uiFlags = computed(
  () => getters['conversationClassifications/getUIFlags'].value
);

const currentAccount = computed(
  () =>
    getters['accounts/getAccount'].value(Number(route.params.accountId)) || {}
);

const requireClassification = computed(
  () =>
    currentAccount.value?.settings?.require_classification_on_resolve !== false
);

const requireClosingNote = computed(
  () => currentAccount.value?.settings?.require_closing_note_on_resolve === true
);

const tableHeaders = computed(() => [
  t('CLASSIFICATION_SETTINGS.TABLE.NAME'),
  t('CLASSIFICATION_SETTINGS.TABLE.ACTIONS'),
]);

const addClassification = async () => {
  if (!newName.value.trim()) return;
  try {
    await store.dispatch('conversationClassifications/create', {
      name: newName.value.trim(),
    });
    useAlert(t('CLASSIFICATION_SETTINGS.CREATE.SUCCESS'));
    newName.value = '';
  } catch {
    useAlert(t('CLASSIFICATION_SETTINGS.CREATE.ERROR'));
  }
};

const startEdit = item => {
  editingId.value = item.id;
  editingName.value = item.name;
};

const cancelEdit = () => {
  editingId.value = null;
  editingName.value = '';
};

const saveEdit = async id => {
  if (!editingName.value.trim()) return;
  try {
    await store.dispatch('conversationClassifications/update', {
      id,
      name: editingName.value.trim(),
    });
    useAlert(t('CLASSIFICATION_SETTINGS.UPDATE.SUCCESS'));
    cancelEdit();
  } catch {
    useAlert(t('CLASSIFICATION_SETTINGS.UPDATE.ERROR'));
  }
};

const deleteClassification = async id => {
  loading.value[id] = true;
  try {
    await store.dispatch('conversationClassifications/delete', id);
    useAlert(t('CLASSIFICATION_SETTINGS.DELETE.SUCCESS'));
  } catch {
    useAlert(t('CLASSIFICATION_SETTINGS.DELETE.ERROR'));
  } finally {
    loading.value[id] = false;
  }
};

const updateSetting = async (key, value) => {
  try {
    await store.dispatch('accounts/update', { [key]: value });
  } catch {
    useAlert(t('GENERAL_SETTINGS.UPDATE.ERROR'));
  }
};

onBeforeMount(() => {
  store.dispatch('conversationClassifications/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('CLASSIFICATION_SETTINGS.LOADING')"
    :no-records-found="false"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('CLASSIFICATION_SETTINGS.TITLE')"
        :description="$t('CLASSIFICATION_SETTINGS.DESCRIPTION')"
        feature-name="conversation_classifications"
      />
    </template>
    <template #body>
      <!-- Required fields toggles -->
      <div
        class="flex flex-col gap-4 mb-6 p-4 border border-n-weak rounded-lg bg-n-alpha-1"
      >
        <h3 class="text-sm font-semibold text-n-slate-12">
          {{ $t('CLASSIFICATION_SETTINGS.SETTINGS.TITLE') }}
        </h3>
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-n-slate-12">
              {{
                $t('CLASSIFICATION_SETTINGS.SETTINGS.REQUIRE_CLASSIFICATION')
              }}
            </p>
            <p class="text-xs text-n-slate-10">
              {{
                $t(
                  'CLASSIFICATION_SETTINGS.SETTINGS.REQUIRE_CLASSIFICATION_DESC'
                )
              }}
            </p>
          </div>
          <input
            type="checkbox"
            :checked="requireClassification"
            class="cursor-pointer"
            @change="
              updateSetting(
                'require_classification_on_resolve',
                $event.target.checked
              )
            "
          />
        </div>
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-n-slate-12">
              {{ $t('CLASSIFICATION_SETTINGS.SETTINGS.REQUIRE_CLOSING_NOTE') }}
            </p>
            <p class="text-xs text-n-slate-10">
              {{
                $t('CLASSIFICATION_SETTINGS.SETTINGS.REQUIRE_CLOSING_NOTE_DESC')
              }}
            </p>
          </div>
          <input
            type="checkbox"
            :checked="requireClosingNote"
            class="cursor-pointer"
            @change="
              updateSetting(
                'require_closing_note_on_resolve',
                $event.target.checked
              )
            "
          />
        </div>
      </div>

      <!-- Add new classification -->
      <div class="flex gap-2 mb-4">
        <input
          v-model="newName"
          type="text"
          :placeholder="$t('CLASSIFICATION_SETTINGS.FORM.PLACEHOLDER')"
          class="flex-1 px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-brand"
          @keydown.enter="addClassification"
        />
        <Button
          :label="$t('CLASSIFICATION_SETTINGS.FORM.ADD')"
          size="sm"
          :is-loading="uiFlags.isCreating"
          :disabled="!newName.trim() || uiFlags.isCreating"
          @click="addClassification"
        />
      </div>

      <!-- Classifications table -->
      <BaseTable
        :headers="tableHeaders"
        :items="classifications"
        :no-data-message="$t('CLASSIFICATION_SETTINGS.LIST.EMPTY')"
      >
        <template #row="{ items }">
          <BaseTableRow v-for="item in items" :key="item.id" :item="item">
            <template #default>
              <BaseTableCell>
                <div
                  v-if="editingId === item.id"
                  class="flex gap-2 items-center"
                >
                  <input
                    v-model="editingName"
                    type="text"
                    class="flex-1 px-2 py-1 text-sm border rounded border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-1 focus:ring-n-brand"
                    @keydown.enter="saveEdit(item.id)"
                    @keydown.esc="cancelEdit"
                  />
                  <Button
                    icon="i-lucide-check"
                    slate
                    sm
                    @click="saveEdit(item.id)"
                  />
                  <Button icon="i-lucide-x" slate sm @click="cancelEdit" />
                </div>
                <span v-else class="text-body-main text-n-slate-12">
                  {{ item.name }}
                </span>
              </BaseTableCell>

              <BaseTableCell align="end">
                <div class="flex gap-3 justify-end flex-shrink-0">
                  <Button
                    v-if="editingId !== item.id"
                    v-tooltip.top="$t('CLASSIFICATION_SETTINGS.TABLE.EDIT')"
                    icon="i-woot-edit-pen"
                    slate
                    sm
                    @click="startEdit(item)"
                  />
                  <Button
                    v-if="editingId !== item.id"
                    v-tooltip.top="$t('CLASSIFICATION_SETTINGS.TABLE.DELETE')"
                    icon="i-woot-bin"
                    slate
                    sm
                    class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
                    :is-loading="loading[item.id]"
                    @click="deleteClassification(item.id)"
                  />
                </div>
              </BaseTableCell>
            </template>
          </BaseTableRow>
        </template>
      </BaseTable>
    </template>
  </SettingsLayout>
</template>
