<script setup>
import { useAlert } from 'dashboard/composables';
import AddAutomationRule from './AddAutomationRule.vue';
import EditAutomationRule from './EditAutomationRule.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { picoSearch } from '@chatwoot/pico-search';
import AutomationRuleRow from './AutomationRuleRow.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import { BaseTable } from 'dashboard/components-next/table';
import { DEFAULT_DELAY_MINUTES } from './constants';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();
const confirmDialog = ref(null);

const loading = ref({});
const addDialogRef = ref(null);
const editDialogRef = ref(null);
const showDeleteConfirmationPopup = ref(false);
const selectedAutomation = ref({});
const searchQuery = ref('');
const toggleModalTitle = ref(t('AUTOMATION.TOGGLE.ACTIVATION_TITLE'));
const toggleModalDescription = ref(
  t('AUTOMATION.TOGGLE.ACTIVATION_DESCRIPTION')
);

const records = computed(() => getters['automations/getAutomations'].value);

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return records.value;
  return picoSearch(records.value, query, ['name', 'description']);
});

const uiFlags = computed(() => getters['automations/getUIFlags'].value);
const accountId = computed(() => getters.getCurrentAccountId.value);

const isDelayedAutomationsEnabled = computed(() =>
  getters['accounts/isFeatureEnabledonAccount'].value(
    accountId.value,
    'delayed_automations'
  )
);

const instantRecords = computed(() =>
  filteredRecords.value.filter(automation => !automation.execution_delay)
);
const delayedRecords = computed(() =>
  filteredRecords.value.filter(automation => automation.execution_delay)
);

// Accounts that can't create delayed rules, and have none left over, just see the plain list.
const showTabs = computed(
  () =>
    isDelayedAutomationsEnabled.value ||
    records.value.some(automation => automation.execution_delay)
);

const activeTab = ref('instant');

const tabs = computed(() => [
  {
    key: 'instant',
    label: t('AUTOMATION.LIST.TABS.INSTANT'),
    count: instantRecords.value.length,
  },
  {
    key: 'delayed',
    label: t('AUTOMATION.LIST.TABS.DELAYED'),
    count: delayedRecords.value.length,
  },
]);

const activeTabIndex = computed(() =>
  tabs.value.findIndex(tab => tab.key === activeTab.value)
);

const visibleRecords = computed(() => {
  if (!showTabs.value) return filteredRecords.value;
  return activeTab.value === 'delayed'
    ? delayedRecords.value
    : instantRecords.value;
});

const noDataMessage = computed(() => {
  if (searchQuery.value) return t('AUTOMATION.NO_RESULTS');
  return showTabs.value && activeTab.value === 'delayed'
    ? t('AUTOMATION.LIST.404_DELAYED')
    : t('AUTOMATION.LIST.404');
});

const onTabChanged = tab => {
  activeTab.value = tab.key;
};

const deleteConfirmText = computed(
  () => `${t('AUTOMATION.DELETE.CONFIRM.YES')} ${selectedAutomation.value.name}`
);

const deleteRejectText = computed(
  () => `${t('AUTOMATION.DELETE.CONFIRM.NO')} ${selectedAutomation.value.name}`
);

const deleteMessage = computed(() => ` ${selectedAutomation.value.name}?`);

const isSLAEnabled = computed(() =>
  getters['accounts/isFeatureEnabledonAccount'].value(accountId.value, 'sla')
);

const showDelayDisabledBanner = computed(
  () =>
    !isDelayedAutomationsEnabled.value &&
    records.value.some(automation => automation.execution_delay)
);

onMounted(() => {
  store.dispatch('inboxes/get');
  store.dispatch('agents/get');
  store.dispatch('contacts/get');
  store.dispatch('teams/get');
  store.dispatch('labels/get');
  store.dispatch('campaigns/get');
  store.dispatch('automations/get');
  if (isSLAEnabled.value) {
    store.dispatch('sla/get');
  }
});

const openAddPopup = () => {
  const startsWithWait =
    isDelayedAutomationsEnabled.value && activeTab.value === 'delayed';
  addDialogRef.value?.open(startsWithWait ? DEFAULT_DELAY_MINUTES : null);
};
const hideAddPopup = () => {
  addDialogRef.value?.close();
};

const openEditPopup = response => {
  selectedAutomation.value = { ...response };
  editDialogRef.value?.open(response);
};
const hideEditPopup = () => {
  editDialogRef.value?.close();
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  selectedAutomation.value = response;
};
const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteAutomation = async id => {
  try {
    await store.dispatch('automations/delete', id);
    useAlert(t('AUTOMATION.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('AUTOMATION.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[selectedAutomation.value.id] = false;
  }
};
const confirmDeletion = () => {
  loading.value[selectedAutomation.value.id] = true;
  closeDeletePopup();
  deleteAutomation(selectedAutomation.value.id);
};
const cloneAutomation = async ({ id }) => {
  try {
    await store.dispatch('automations/clone', id);
    useAlert(t('AUTOMATION.CLONE.API.SUCCESS_MESSAGE'));
    store.dispatch('automations/get');
  } catch (error) {
    useAlert(t('AUTOMATION.CLONE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[selectedAutomation.value.id] = false;
  }
};

const submitAutomation = async (payload, mode) => {
  try {
    const action =
      mode === 'edit' ? 'automations/update' : 'automations/create';
    const successMessage =
      mode === 'edit'
        ? t('AUTOMATION.EDIT.API.SUCCESS_MESSAGE')
        : t('AUTOMATION.ADD.API.SUCCESS_MESSAGE');
    await store.dispatch(action, payload);
    useAlert(successMessage);
    hideAddPopup();
    hideEditPopup();
  } catch (error) {
    const fallbackMessage =
      mode === 'edit'
        ? t('AUTOMATION.EDIT.API.ERROR_MESSAGE')
        : t('AUTOMATION.ADD.API.ERROR_MESSAGE');
    useAlert(error?.response?.data?.error || fallbackMessage);
  }
};
const toggleAutomation = async ({ id, name, status }) => {
  try {
    if (status) {
      toggleModalTitle.value = t('AUTOMATION.TOGGLE.DEACTIVATION_TITLE');
      toggleModalDescription.value = t(
        'AUTOMATION.TOGGLE.DEACTIVATION_DESCRIPTION',
        {
          automationName: name,
        }
      );
    } else {
      toggleModalTitle.value = t('AUTOMATION.TOGGLE.ACTIVATION_TITLE');
      toggleModalDescription.value = t(
        'AUTOMATION.TOGGLE.ACTIVATION_DESCRIPTION',
        {
          automationName: name,
        }
      );
    }

    const ok = await confirmDialog.value.showConfirmation();
    if (ok) {
      await store.dispatch('automations/update', {
        id: id,
        active: !status,
      });
      const message = status
        ? t('AUTOMATION.TOGGLE.DEACTIVATION_SUCCESFUL')
        : t('AUTOMATION.TOGGLE.ACTIVATION_SUCCESFUL');
      useAlert(message);
    }
  } catch (error) {
    useAlert(t('AUTOMATION.EDIT.API.ERROR_MESSAGE'));
  }
};

const tableHeaders = computed(() => {
  return [
    t('AUTOMATION.LIST.TABLE_HEADER.NAME'),
    t('AUTOMATION.LIST.TABLE_HEADER.ACTIVE'),
    t('AUTOMATION.LIST.TABLE_HEADER.CREATED_ON'),
    t('AUTOMATION.LIST.TABLE_HEADER.ACTIONS'),
  ];
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('AUTOMATION.LOADING')"
    :no-records-found="!records.length"
    :no-records-message="$t('AUTOMATION.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('AUTOMATION.HEADER')"
        :description="$t('AUTOMATION.DESCRIPTION')"
        :link-text="$t('AUTOMATION.LEARN_MORE')"
        :search-placeholder="$t('AUTOMATION.SEARCH_PLACEHOLDER')"
        feature-name="automation"
      >
        <template v-if="showTabs" #tabs>
          <TabBar
            :tabs="tabs"
            :initial-active-tab="activeTabIndex"
            @tab-changed="onTabChanged"
          />
        </template>
        <template v-if="visibleRecords.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ $t('AUTOMATION.COUNT', { n: visibleRecords.length }) }}
          </span>
        </template>
        <template #actions>
          <Button
            :label="$t('AUTOMATION.HEADER_BTN_TXT')"
            size="sm"
            @click="openAddPopup"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div
        v-if="showDelayDisabledBanner"
        class="px-4 py-3 mb-4 text-sm rounded-lg bg-n-amber-3 text-n-amber-12"
      >
        {{ $t('AUTOMATION.LIST.DELAY_DISABLED_BANNER') }}
      </div>
      <BaseTable
        :headers="tableHeaders"
        :items="visibleRecords"
        :no-data-message="noDataMessage"
      >
        <template #row="{ items }">
          <AutomationRuleRow
            v-for="automation in items"
            :key="automation.id"
            :automation="automation"
            :loading="loading[automation.id]"
            @clone="cloneAutomation"
            @toggle="toggleAutomation"
            @edit="openEditPopup"
            @delete="openDeletePopup"
          />
        </template>
      </BaseTable>
    </template>

    <AddAutomationRule ref="addDialogRef" @save-automation="submitAutomation" />

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('LABEL_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('AUTOMATION.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />

    <EditAutomationRule
      ref="editDialogRef"
      :selected-response="selectedAutomation"
      @save-automation="submitAutomation"
    />
    <woot-confirm-modal
      ref="confirmDialog"
      :title="toggleModalTitle"
      :description="toggleModalDescription"
    />
  </SettingsLayout>
</template>
