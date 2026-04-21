<script setup>
import { useAlert } from 'dashboard/composables';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import CustomRoleModal from './component/CustomRoleModal.vue';
import CustomRoleTableBody from './component/CustomRoleTableBody.vue';
import CustomRolePaywall from './component/CustomRolePaywall.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { picoSearch } from '@scmmishra/pico-search';
import { BaseTable } from 'dashboard/components-next/table';

const store = useStore();
const { t } = useI18n();

const showCustomRoleModal = ref(false);
const customRoleModalMode = ref('add');
const selectedRole = ref(null);
const loading = ref({});
const showDeleteConfirmationPopup = ref(false);
const activeResponse = ref({});
const searchQuery = ref('');

const records = useMapGetter('customRole/getCustomRoles');

const filteredRecords = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return records.value;
  return picoSearch(records.value, query, ['name', 'description']);
});
const uiFlags = useMapGetter('customRole/getUIFlags');

const deleteConfirmText = computed(
  () => `${t('CUSTOM_ROLE.DELETE.CONFIRM.YES')} ${activeResponse.value.name}`
);

const deleteRejectText = computed(
  () => `${t('CUSTOM_ROLE.DELETE.CONFIRM.NO')} ${activeResponse.value.name}`
);

const deleteMessage = computed(() => {
  return ` ${activeResponse.value.name} ? `;
});

const isFeatureEnabledOnAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const currentAccountId = useMapGetter('getCurrentAccountId');

const isBehindAPaywall = computed(() => {
  return !isFeatureEnabledOnAccount.value(
    currentAccountId.value,
    'custom_roles'
  );
});

const fetchCustomRoles = async () => {
  try {
    await store.dispatch('customRole/getCustomRole');
  } catch (error) {
    // Ignore Error
  }
};

onMounted(() => {
  fetchCustomRoles();
});

const tableHeaders = computed(() => {
  return [
    t('CUSTOM_ROLE.LIST.TABLE_HEADER.NAME'),
    t('CUSTOM_ROLE.LIST.TABLE_HEADER.DESCRIPTION'),
    t('CUSTOM_ROLE.LIST.TABLE_HEADER.PERMISSIONS'),
    t('CUSTOM_ROLE.LIST.TABLE_HEADER.ACTIONS'),
  ];
});

const showAlertMessage = message => {
  loading.value[activeResponse.value.id] = false;
  activeResponse.value = {};
  useAlert(message);
};

const openAddModal = () => {
  if (isBehindAPaywall.value) return;
  customRoleModalMode.value = 'add';
  selectedRole.value = null;
  showCustomRoleModal.value = true;
};

const openEditModal = role => {
  customRoleModalMode.value = 'edit';
  selectedRole.value = role;
  showCustomRoleModal.value = true;
};

const hideCustomRoleModal = () => {
  selectedRole.value = null;
  showCustomRoleModal.value = false;
};

const openDeletePopup = response => {
  showDeleteConfirmationPopup.value = true;
  activeResponse.value = response;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const deleteCustomRole = async id => {
  try {
    await store.dispatch('customRole/deleteCustomRole', id);
    showAlertMessage(t('CUSTOM_ROLE.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.message || t('CUSTOM_ROLE.DELETE.API.ERROR_MESSAGE');
    showAlertMessage(errorMessage);
  }
};

const confirmDeletion = () => {
  loading[activeResponse.value.id] = true;
  closeDeletePopup();
  deleteCustomRole(activeResponse.value.id);
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.fetchingList"
    :loading-message="$t('CUSTOM_ROLE.LOADING')"
    :no-records-found="!records.length && !isBehindAPaywall"
    :no-records-message="$t('CUSTOM_ROLE.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('CUSTOM_ROLE.HEADER')"
        :description="$t('CUSTOM_ROLE.DESCRIPTION')"
        :link-text="$t('CUSTOM_ROLE.LEARN_MORE')"
        :search-placeholder="$t('CUSTOM_ROLE.SEARCH_PLACEHOLDER')"
        feature-name="canned_responses"
      >
        <template v-if="records?.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ $t('CUSTOM_ROLE.COUNT', { n: records.length }) }}
          </span>
        </template>
        <template #actions>
          <Button
            :label="$t('CUSTOM_ROLE.HEADER_BTN_TXT')"
            size="sm"
            :disabled="isBehindAPaywall"
            @click="openAddModal"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <CustomRolePaywall v-if="isBehindAPaywall" />
      <BaseTable
        v-else
        :headers="tableHeaders"
        :items="filteredRecords"
        :no-data-message="
          searchQuery
            ? $t('CUSTOM_ROLE.NO_RESULTS')
            : $t('CUSTOM_ROLE.LIST.404')
        "
      >
        <template #row="{ items }">
          <CustomRoleTableBody
            :roles="items"
            :loading="loading"
            @edit="openEditModal"
            @delete="openDeletePopup"
          />
        </template>
      </BaseTable>
    </template>

    <woot-modal
      v-model:show="showCustomRoleModal"
      :on-close="hideCustomRoleModal"
    >
      <CustomRoleModal
        :mode="customRoleModalMode"
        :selected-role="selectedRole"
        @close="hideCustomRoleModal"
      />
    </woot-modal>

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('CUSTOM_ROLE.DELETE.CONFIRM.TITLE')"
      :message="$t('CUSTOM_ROLE.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />
  </SettingsLayout>
</template>
