<script setup>
import { useAlert } from 'dashboard/composables';
import AddCustomRole from './AddCustomRole.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'dashboard/composables/useI18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const showAddPopup = ref(false);
const loading = ref({});
const showEditPopup = ref(false);
const showDeleteConfirmationPopup = ref(false);
const activeResponse = ref({});
const customRoleAPI = ref({ message: '' });

const records = computed(() =>
  getters.getCustomRoles.value
);

const uiFlags = computed(() => getters.getUIFlags.value);

const deleteConfirmText = computed(
  () =>
    `${t('CUSTOM_ROLE.DELETE.CONFIRM.YES')} ${activeResponse.value.name}`
);

const deleteRejectText = computed(
  () =>
    `${t('CUSTOM_ROLE.DELETE.CONFIRM.NO')} ${activeResponse.value.name}`
);

const deleteMessage = computed(() => {
  return ` ${activeResponse.value.name} ? `;
});

const fetchCustomRoles = async () => {
  try {
    await store.dispatch('getCustomRole');
  } catch (error) {
    // Ignore Error
  }
};

onMounted(() => {
  fetchCustomRoles();
});

const showAlertMessage = message => {
  loading[activeResponse.value.id] = false;
  activeResponse.value = {};
  customRoleAPI.value.message = message;
  useAlert(message);
};

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = response => {
  showEditPopup.value = true;
  activeResponse.value = response;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
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
    await store.dispatch('deleteCustomRole', id);
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
  <div class="flex-1 overflow-auto">
    <BaseSettingsHeader
      :title="$t('CUSTOM_ROLE.HEADER')"
      :description="$t('CUSTOM_ROLE.DESCRIPTION')"
      :link-text="$t('CUSTOM_ROLE.LEARN_MORE')"
      feature-name="canned_responses"
    >
      <template #actions>
        <woot-button
          class="button nice rounded-md"
          icon="add-circle"
          @click="openAddPopup"
        >
          {{ $t('CUSTOM_ROLE.HEADER_BTN_TXT') }}
        </woot-button>
      </template>
    </BaseSettingsHeader>

    <div class="mt-6 flex-1">
      <woot-loading-state
        v-if="uiFlags.fetchingList"
        :message="$t('CUSTOM_ROLE.LOADING')"
      />
      <p
        v-else-if="!records.length"
        class="flex flex-col items-center justify-center h-full text-base text-slate-600 dark:text-slate-300 py-8"
      >
        {{ $t('CUSTOM_ROLE.LIST.404') }}
      </p>
      <table
        v-else
        class="min-w-full overflow-x-auto divide-y divide-slate-75 dark:divide-slate-700"
      >
        <thead>
          <th
            v-for="thHeader in $t('CUSTOM_ROLE.LIST.TABLE_HEADER')"
            :key="thHeader"
            class="py-4 pr-4 text-left font-semibold text-slate-700 dark:text-slate-300"
          >
              <span class="mb-0">
                {{ thHeader }}
              </span>
          </th>
        </thead>
        <tbody
          class="divide-y divide-slate-50 dark:divide-slate-800 text-slate-700 dark:text-slate-300"
        >
          <tr
            v-for="(customRole, index) in records"
            :key="customRole.id"
          >
            <td
              class="py-4 pr-4 truncate max-w-xs font-medium"
              :title="customRole.name"
            >
              {{ customRole.name }}
            </td>
            <td class="py-4 pr-4 md:break-all whitespace-normal">
              {{ customRole.description }}
            </td>
            <td class="py-4 pr-4 md:break-all whitespace-normal">
              {{ customRole.permissions }}
            </td>
            <td class="py-4 flex justify-end gap-1">
              <woot-button
                v-tooltip.top="$t('CUSTOM_ROLE.DELETE.BUTTON_TEXT')"
                variant="smooth"
                color-scheme="alert"
                size="tiny"
                icon="dismiss-circle"
                class-names="grey-btn"
                :is-loading="loading[customRole.id]"
                @click="openDeletePopup(customRole, index)"
              />
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <AddCustomRole :on-close="hideAddPopup" />
    </woot-modal>

    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('CUSTOM_ROLE.DELETE.CONFIRM.TITLE')"
      :message="$t('CUSTOM_ROLE.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />
  </div>
</template>
