<script setup>
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@chatwoot/pico-search';
import FlowsTableRow from './FlowsTableRow.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import PanelIaStateLegend from 'dashboard/components-next/PanelIa/PanelIaStateLegend.vue';
import { BaseTable } from 'dashboard/components-next/table';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const showDeleteConfirmationPopup = ref(false);
const selectedFlow = ref({});
const searchQuery = ref('');

const records = computed(() => getters['flows/getFlows'].value);
const uiFlags = computed(() => getters['flows/getUIFlags'].value);

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return records.value;
  return picoSearch(records.value, query, ['name', 'description', 'category']);
});

const deleteMessage = computed(() => ` ${selectedFlow.value.name}?`);

onMounted(() => {
  store.dispatch('flows/get');
});

const deleteFlow = async id => {
  try {
    await store.dispatch('flows/delete', id);
    useAlert(t('FLOWS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('FLOWS.DELETE.API.ERROR_MESSAGE'));
  }
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  selectedFlow.value = response;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const confirmDeletion = () => {
  closeDeletePopup();
  deleteFlow(selectedFlow.value.id);
};

const tableHeaders = computed(() => [
  t('FLOWS.LIST.TABLE_HEADER.NAME'),
  t('FLOWS.LIST.TABLE_HEADER.CATEGORY'),
  t('FLOWS.LIST.TABLE_HEADER.STATUS'),
  t('FLOWS.LIST.TABLE_HEADER.ACTIONS'),
]);
</script>

<template>
  <SettingsLayout
    :no-records-message="$t('FLOWS.LIST.404')"
    :no-records-found="!records.length"
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('FLOWS.LOADING')"
    feature-name="flows_v1"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('FLOWS.HEADER')"
        :description="$t('FLOWS.DESCRIPTION')"
        :link-text="$t('FLOWS.LEARN_MORE')"
        :search-placeholder="$t('FLOWS.SEARCH_PLACEHOLDER')"
        feature-name="flows_v1"
      >
        <template v-if="records?.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ $t('FLOWS.COUNT', { n: records.length }) }}
          </span>
        </template>
        <template #actions>
          <router-link :to="{ name: 'flows_new' }">
            <Button :label="$t('FLOWS.HEADER_BTN_TXT')" size="sm" />
          </router-link>
        </template>
      </BaseSettingsHeader>
      <PanelIaStateLegend class="mt-3" />
    </template>
    <template #body>
      <div
        v-if="!filteredRecords.length"
        class="px-4 py-8 text-center text-n-slate-11"
      >
        {{ searchQuery ? $t('FLOWS.NO_RESULTS') : $t('FLOWS.LIST.404') }}
      </div>
      <BaseTable
        v-else
        class="w-full"
        :headers="tableHeaders"
        :items="filteredRecords"
        :no-data-message="$t('FLOWS.LIST.404')"
      >
        <template #row="{ items }">
          <FlowsTableRow
            v-for="flow in items"
            :key="flow.id"
            :flow="flow"
            @delete="openDeletePopup(flow)"
          />
        </template>
      </BaseTable>
      <woot-delete-modal
        v-model:show="showDeleteConfirmationPopup"
        :on-close="closeDeletePopup"
        :on-confirm="confirmDeletion"
        :title="$t('FLOWS.DELETE.CONFIRM.TITLE')"
        :message="$t('FLOWS.DELETE.CONFIRM.MESSAGE')"
        :message-value="deleteMessage"
        :confirm-text="$t('FLOWS.DELETE.CONFIRM.YES')"
        :reject-text="$t('FLOWS.DELETE.CONFIRM.NO')"
      />
    </template>
  </SettingsLayout>
</template>
