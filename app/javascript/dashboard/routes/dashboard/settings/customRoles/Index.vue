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

const store = useStore();
const { t } = useI18n();

const showCustomRoleModal = ref(false);
const customRoleModalMode = ref('add');
const selectedRole = ref(null);
const loading = ref({});
const showDeleteConfirmationPopup = ref(false);
const activeResponse = ref({});

const records = useMapGetter('customRole/getCustomRoles');
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
        :title="$t('CUSTOM_ROLE.HEADER')"
        :description="$t('CUSTOM_ROLE.DESCRIPTION')"
        :link-text="$t('CUSTOM_ROLE.LEARN_MORE')"
        feature-name="canned_responses"
      >
        <template #actions>
          <Button
            icon="i-lucide-circle-plus"
            :label="$t('CUSTOM_ROLE.HEADER_BTN_TXT')"
            :disabled="isBehindAPaywall"
            @click="openAddModal"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <CustomRolePaywall v-if="isBehindAPaywall" />
      <table
        v-else
        class="min-w-full overflow-x-auto divide-y divide-slate-75 dark:divide-slate-700"
      >
        <thead>
          <th
            v-for="thHeader in tableHeaders"
            :key="thHeader"
            class="py-4 ltr:pr-4 rtl:pl-4 font-semibold text-left text-slate-700 dark:text-slate-300"
          >
            <span class="mb-0">
              {{ thHeader }}
            </span>
          </th>
        </thead>

        <CustomRoleTableBody
          :roles="records"
          :loading="loading"
          @edit="openEditModal"
          @delete="openDeletePopup"
        />
      </table>
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
